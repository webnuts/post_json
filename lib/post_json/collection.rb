module PostJson
  class Collection < ActiveRecord::Base
    self.table_name = "post_json_collections"

    class << self
      def all_names
        self.order(:name).pluck(:name)
      end

      def initialize(*collection_configs)
        collection_configs =  if collection_configs.length == 1 && collection_configs[0].is_a?(Array)
                                collection_configs[0]
                              else
                                collection_configs
                              end

        collection_configs.map do |collection_config|
          collection_name = collection_config.with_indifferent_access.delete('name')
          if collection_name
            collection = self.where(name: collection_name).first_or_create
            collection.update_attributes(collection_config)
          else
            raise ArgumentError, "Specify a collection name"
          end
        end
      end
    end

    has_many :documents, foreign_key: '__doc__collection_id', dependent: :delete_all
    has_many :dynamic_indexes, foreign_key: 'collection_id', dependent: :destroy

    validates :name, uniqueness: true

    before_validation do |collection|
      collection.name = case collection.name
                        when nil
                          ""
                        when String
                          collection.name = collection.name[1..-1] if collection.name.start_with?("/")
                          collection.name = collection.name[0..-2] if collection.name.end_with?("/")
                          collection.name.strip.downcase
                        end
    end

    before_save do |collection|
      collection.meta = {} if collection.meta.nil?
      if collection.persisted? && collection.name_changed?
        start_index = collection.name_was.length
        self.class.transaction do
          documents.find_each do |document|
            new_id = "#{collection.name}#{document.id[start_index..-1]}"
            new_body = document.__doc__body.with_indifferent_access
            new_body['id'] = new_id
            document.update_columns({id: new_id, __doc__body: new_body})
          end
        end
      end
    end

    scope :by_name, -> (collection_name) { where(name: collection_name.to_s.strip.downcase)}

    def dynamic_indexes
      DynamicIndex.indexed_selectors(id)
    end

    def create_dynamic_index(selector)
      create_dynamic_indexes(selector)
    end

    def create_dynamic_indexes(*selectors)
      DynamicIndex.ensure_index(id, *selectors).count
    end

    def destroy_dynamic_index(selector)
      DynamicIndex.destroy_index(selector)
    end

    def update_document_attributes_on_save(document)
      set_document_timestamps(document)
      set_document_version(document)
    end

    def convert_document_attribute_type(attribute_name, value)
      case value
      when /^[0-9]{4}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]\.[0-9]{3}Z$/
        Time.parse(value).in_time_zone
      when Hash
        value.inject(HashWithIndifferentAccess.new) do |result, (key, value)|
          result[key] = convert_document_attribute_type("#{attribute_name}.#{key}", value)
          result
        end
      when Array
        value.map.with_index do |array_value, index|
          convert_document_attribute_type("#{attribute_name}[#{index}]", array_value)
        end
      else
        value
      end
    end

  private

    def set_document_timestamps(document)
      if use_timestamps == true
        now = Time.zone.now
        if document.new_record?
          document[created_at_attribute_name] = now unless document[created_at_attribute_name].present?
          document[updated_at_attribute_name] = now unless document[updated_at_attribute_name].present?
        else
          document[updated_at_attribute_name] = now unless document.updated_at_changed?
        end
      end
    end

    def set_document_version(document)
      if use_version_number == true
        document[version_attribute_name] = document.__doc__version 
      end
    end
  end
end
