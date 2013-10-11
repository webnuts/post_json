require "uuidtools"

module PostJson
  class Document < ActiveRecord::Base
    include ActiveRecordExtensions

    self.table_name = "post_json_documents"
    self.record_timestamps = false

    def self.record_timestamps=(value)
      raise ArgumentError, "Use 'use_timestamps' attribute on collection: Collection.by_name('my_collection').update_attribute('use_timestamps', false)"
    end

    belongs_to :__doc__collection, class_name: 'Collection'

    validate do |document|
      if document.persisted? && (document.id_changed? || document.id != document.__doc__body['id'])
        errors.add(:id, "cannot be modified") 
      end
    end

    before_validation do |document|
      document.__doc__body ||= HashWithIndifferentAccess.new
      if document.new_record?
        given_id = document.__doc__body['id'].to_s.strip.gsub(/\/+/, "/").downcase
        given_id = given_id[1..-1] if given_id[0] == "/"
        given_id =  if given_id == ""
                      UUIDTools::UUID.random_create.to_s
                    elsif given_id[-1] == "/"
                      given_id + UUIDTools::UUID.random_create.to_s
                    else
                      given_id
                    end
        document.id = given_id
      end
    end

    before_save do |document|
      if document.new_record?
        document.__doc__body['id'] = document.id

        last_slash_index = document.id.rindex("/")
        collection_name = if last_slash_index
                            document.id[0..last_slash_index-1]
                          else
                            ""
                          end

        document.__doc__collection = Collection.where(name: collection_name).first_or_create unless document.__doc__collection_id

        document.__doc__version = 1
      elsif document.__doc__body_changed? && document.__doc__version_changed? == false
        document.__doc__version = document.__doc__version + 1
      end

      __doc__collection.update_document_attributes_on_save(document)
    end

    def initialize(*args)
      args[0] ||= {}
      args[0] = {'__doc__body' => args[0]}.with_indifferent_access
      super(*args)
    end

    after_find do |document|
      document
    end

    def cache_key
      "#{id}-version-#{__doc__version}"
    end

    def attributes
      read_attribute('__doc__body')
    end

    def to_h
      hash = attributes
      if hash.is_a?(Hash)
        hash.with_indifferent_access
      else
        HashWithIndifferentAccess.new
      end
    end

    def [](key)
      read_attribute(key)
    end

    def []=(key, value)
      write_attribute(key, value)
    end

    def read_attribute(attribute_name)
      name = attribute_name.to_s
      if name.in?(attribute_names)
        super
      else
        found__doc__body = super('__doc__body')
        if found__doc__body == nil
          nil
        else
          value = found__doc__body[name]
          if new_record? || __doc__body_attribute_changed?(name)
            value
          else
            __doc__collection.convert_document_attribute_type(attribute_name, value)
          end
        end
      end      
    end

    def write_attribute(attribute_name, value)
      name = attribute_name.to_s
      if name == '__doc__body'
        value = value.with_indifferent_access if value.is_a?(Hash)
        super('__doc__body', value)
      elsif name.in?(attribute_names)
        super
      else
        found__doc__body = read_attribute('__doc__body') || {}
        found__doc__body = found__doc__body.with_indifferent_access
        found__doc__body[name] = value
        write_attribute('__doc__body', found__doc__body)
        value
      end
    end

    def method_missing(method_symbol, *args, &block)
      method_name = method_symbol.to_s
      attribute_name =  if method_name.end_with?("_changed?")
                          method_name[0..-10]
                        elsif method_name.end_with?("_was")
                          method_name[0..-5]
                        elsif method_name.end_with?("=")
                          method_name[0..-2]
                        else
                          method_name
                        end

      if attribute_name.in?(attribute_names) == false
        self.class.define_attribute_accessor(attribute_name)
        send(method_symbol, *args)
      else
        super
      end
    end

    def __doc__body_attribute_changed?(attribute_name)
      attribute_now = __doc__body == nil ? nil : __doc__body[attribute_name.to_s]
      attribute_now != __doc__body_attribute_was(attribute_name)
    end

    def __doc__body_attribute_was(attribute_name)
      __doc__body_was == nil ? nil :  __doc__body_was[attribute_name.to_s]
    end

    def self.define_attribute_accessor(attribute_name)
      class_eval <<-RUBY
        def #{attribute_name}
          read_attribute('#{attribute_name}')
        end

        def #{attribute_name}=(value)
          write_attribute('#{attribute_name}', value)
        end

        def #{attribute_name}_changed?
          __doc__body_attribute_changed?('#{attribute_name}')
        end

        def #{attribute_name}_was
          __doc__body_attribute_was('#{attribute_name}')
        end
      RUBY
    end
  end
end
