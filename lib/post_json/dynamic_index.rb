module PostJson
  class DynamicIndex < ActiveRecord::Base
    class << self
      include ArgumentMethods

      def ensure_index(model_settings_id, *selectors)
        selectors = flatten_arguments(selectors)
        if selectors.length == 0
          []
        else
          existing_selectors = where(model_settings_id: model_settings_id).pluck(:selector)
          new_selectors = selectors - existing_selectors
          new_selectors.map do |selector|
            create(model_settings_id: model_settings_id, selector: selector)
          end
        end
      end

      def indexed_selectors(model_settings_id)
        # distinct is needed since race condition can cause 1+ records to own the same index
        where(model_settings_id: model_settings_id).distinct.pluck(:selector)
      end

      def destroy_index(model_settings_id, selector)
        where(model_settings_id: model_settings_id, selector: selector).destroy_all.present?
      end
    end

    self.table_name = "post_json_dynamic_indexes"

    belongs_to :model_settings

    attr_readonly :selector

    validates :selector,    presence: true

    def index_name
      @index_name ||= unless @index_name
                        prefix = "dyn_#{model_settings_id.gsub('-', '')}_"
                        if 63 < prefix.length + selector.length
                          digest = Digest::MD5.hexdigest(selector) 
                          "#{prefix}#{digest}"[0..62]
                        else
                          "#{prefix}#{selector.gsub('.', '_')}"
                        end
                      end
    end

    after_create do |dynamic_index|
      begin
        ActiveRecord::Base.connection.execute(dynamic_index.inline_create_index_procedure)
      rescue ActiveRecord::StatementInvalid => e
        # lets ignore this exception if the index already exists. this could happen in a rare race condition.
        orig = e.original_exception
        raise unless orig.is_a?(PG::DuplicateTable) && orig.message.include?("already exists")
      end
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

    CREATE INDEX #{index_name} ON #{current_schema}.#{Base.table_name} (json_selector('#{selector}', __doc__body));
END IF;

END$$;"
    end
  end
end

# CREATE INDEX #{index_name} ON #{current_schema}.#{Base.table_name} (json_selector('#{selector}', __doc__body)) WHERE __doc__model_settings_id = '#{model_settings_id.gsub('-', '')}';