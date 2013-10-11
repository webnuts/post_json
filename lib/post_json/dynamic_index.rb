module PostJson
  class DynamicIndex < ActiveRecord::Base
    class << self
      include ArgumentMethods

      def ensure_index(collection_id, *selectors)
        selectors = flatten_arguments(selectors)
        if selectors.length == 0
          []
        else
          existing_selectors = where(collection_id: collection_id).pluck(:selector)
          new_selectors = selectors - existing_selectors
          new_selectors.map do |selector|
            create(collection_id: collection_id, selector: selector)
          end
        end
      end

      def indexed_selectors(collection_id)
        # distinct is needed since race condition can cause 1+ records to own the same index
        where(collection_id: collection_id).distinct.pluck(:selector)
      end

      def destroy_index(collection_id, selector)
        where(collection_id: collection_id, selector: selector).destroy_all
      end
    end

    self.table_name = "post_json_dynamic_indexes"

    belongs_to :collection

    attr_readonly :selector

    validates :selector,    presence: true

    def index_name
      if defined?(@index_name)
        @index_name
      else
        prefix = "dyn_#{collection_id.gsub('-', '')}_"
        @index_name = if 63 < prefix.length + selector.length
                        digest = Digest::MD5.hexdigest(selector) 
                        "#{prefix}#{digest}"[0..62]
                      else
                        "#{prefix}#{selector.gsub('.', '_')}"
                      end
      end
    end

    after_create do |dynamic_index|
      # catch duplicate index error
      ActiveRecord::Base.connection.execute(dynamic_index.inline_create_index_procedure)
    end

    after_destroy do |dynamic_index|
      ActiveRecord::Base.connection.execute("DROP INDEX IF EXISTS #{dynamic_index.index_name};")
    end

    def inline_create_index_procedure
      schemas = ActiveRecord::Base.connection.schema_search_path.gsub(/\s+/, '').split(',')
      current_schema =  if schemas[0] == "\"$user\"" && 1 < schemas.length
                          schemas[1]
                        else
                          schemas[0]
                        end
"DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = '#{index_name}'
    AND    n.nspname = '#{current_schema}' -- 'public' by default
    ) THEN

    CREATE INDEX #{index_name} ON #{current_schema}.#{Document.table_name} (json_selector('#{selector}', __doc__body)) WHERE __doc__collection_id = '#{collection_id.gsub('-', '')}';
END IF;

END$$;"
    end
  end
end
