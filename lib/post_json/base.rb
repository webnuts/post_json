# Why all the ugly naming you might ask? Well, it will be fixed,
# but for now it is preventing a conflict with the naming of JSON attributes

module PostJson
  class Base < ActiveRecord::Base
    self.abstract_class = true
    self.table_name = "post_json_documents"
    self.lock_optimistically = false

    include SettingsMethods
    include DynamicIndexMethods
    include Copyable

    def initialize(*args)
      if args[0]
        __local__doc__body = HashWithIndifferentAccess.new

        args[0] = args[0].with_indifferent_access.inject(HashWithIndifferentAccess.new('__doc__body' => {})) do |result, (attribute_name, value)|
          if self.class.primary_key == attribute_name
            result[attribute_name] = value
            result['__doc__body'][attribute_name] = value
          elsif self.class.column_names.include?(attribute_name)
            result[attribute_name] = value
          else
            __local__doc__body[attribute_name] = value
          end
          result
        end

        super(*args) do |new_record|
          __local__doc__body.each do |attribute_name, value|
            new_record.public_send("#{attribute_name}=", value)
          end

          yield new_record if block_given?
        end
      else
        args[0] = HashWithIndifferentAccess.new('__doc__body' => {})
        super
      end
    end

    def cache_key
      @dashed_name ||= self.class.name.underscore.dasherize
      __local__unique_version = __doc__version || Digest::MD5.hexdigest(attributes.inspect)
      "#{@dashed_name}-#{self[self.class.primary_key]}-version-#{__local__unique_version}"
    end

    def attributes
      if @new_record != nil
        (read_attribute('__doc__body') || {}).with_indifferent_access
      else
        HashWithIndifferentAccess.new
      end
    end

    def to_h
      attributes.deep_dup
    end

    def inspect
      "#<#{self.class.name} #{attributes.map{ |k, v| "#{k}: #{v.inspect}" }.join(", ")}>"
    end

    def write_attribute(attribute_name, value)
      attribute_name = attribute_name.to_s
      if attribute_name == '__doc__body'
        value = value.try(:with_indifferent_access)
        self.__doc__body_will_change! unless self.__doc__body.try(:with_indifferent_access) == value
        super('__doc__body', value)
      elsif attribute_name.in?(attribute_names)
        super
      else
        __doc__body_write_attribute(attribute_name, value)
      end
    end

    def attribute_changed?(attribute_name)
      attribute_name = attribute_name.to_s
      if attribute_name.in?(attribute_names)
        super
      else
        __doc__body_attribute_changed?(attribute_name)
      end
    end

    def __doc__body_read_attribute(attribute_name)
      __local__value = self.__doc__body[attribute_name.to_s] if self.__doc__body
      __doc__body_convert_attribute_type(attribute_name, __local__value)
    end

    def __doc__body_write_attribute(attribute_name, value)
      self.__doc__body = HashWithIndifferentAccess.new(self.__doc__body).merge(attribute_name.to_s => value)
      value
    end

    def __doc__body_attribute_was(attribute_name)
      self.__doc__body_was == nil ? nil : self.__doc__body_was.with_indifferent_access[attribute_name]
    end

    def __doc__body_attribute_changed?(attribute_name)
      (self.__doc__body == nil ? nil : self.__doc__body.with_indifferent_access[attribute_name]) != self.__doc__body_attribute_was(attribute_name)
    end

    def __doc__body_attribute_change(attribute_name)
      __local__change = [__doc__body_attribute_was(attribute_name), __doc__body_read_attribute(attribute_name)]
      if __local__change[0] == __local__change[1]
        nil
      else
        __local__change
      end
    end

    def __doc__body_convert_attribute_type(attribute_name, value)
      case value
      when /^[0-9]{4}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]\.[0-9]{3}Z$/
        DateTime.parse(value)
      when Hash
        value.inject(HashWithIndifferentAccess.new) do |result, (key, value)|
          result[key] = __doc__body_convert_attribute_type("#{attribute_name}.#{key}", value)
          result
        end
      when Array
        value.map.with_index do |array_value, index|
          __doc__body_convert_attribute_type("#{attribute_name}[#{index}]", array_value)
        end
      else
        value
      end
    end

    def [](attribute_name)
      self.__doc__body_read_attribute(attribute_name)
    end

    def []=(attribute_name, value)
      self.__doc__body_write_attribute(attribute_name, value)
    end

    alias_method :super_respond_to?, :respond_to?

    def respond_to?(method_symbol, include_all = false)
      if super
        true
      else
        method_name = method_symbol.to_s
        attribute_name =  if method_name.end_with?("_changed?")
                            method_name[0..-10]
                          elsif method_name.end_with?("_was")
                            method_name[0..-5]
                          elsif method_name.end_with?("=")
                            method_name[0..-2]
                          elsif method_name.end_with?("_change")
                            method_name[0..-8]
                          elsif method_name.end_with?("_will_change!")
                            method_name[0..-14]
                          else
                            method_name
                          end
        attributes.has_key?(attribute_name)
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
                        elsif method_name.end_with?("_change")
                          method_name[0..-8]
                        elsif method_name.end_with?("_will_change!")
                          method_name[0..-14]
                        else
                          method_name
                        end

      if attribute_name.in?(attribute_names) || self.class.column_names.include?(attribute_name) || super_respond_to?(attribute_name.to_sym)
        super
      else
        self.class.define_attribute_accessor(attribute_name)
        send(method_symbol, *args)
      end
    end

    class << self
      def all_with_query_translator
        QueryTranslator.new(all_without_query_translator)
      end

      alias_method_chain :all, :query_translator

      def page(*args)
        all.page(*args)
      end

      def default_scopes
        # query = query.where("\"#{table_name}\".__doc__model_settings_id = ?", settings_id)
        model_settings = ModelSettings.table_name
        query = all_without_query_translator
        query = query.joins("INNER JOIN \"#{model_settings}\" ON lower(\"#{model_settings}\".collection_name) = '#{collection_name.downcase}'")
        query = query.where("\"#{table_name}\".__doc__model_settings_id = \"#{model_settings}\".id")
        super + [Proc.new { query }]
      end

      def collection_name
        if @collection_name == nil
          @collection_name = superclass.collection_name rescue nil
        end
        message = "You need to assign a collection name to \"#{name || 'Class'}.collection_name\""
        raise ArgumentError, message unless @collection_name.present?
        @collection_name
      end

      def collection_name=(name)
        raise ArgumentError, "Collection name must be present" unless name.present?
        @collection_name = name.to_s.strip
        reload_settings!
        @collection_name
      end

      def rename_collection(new_name)
        new_name = new_name.to_s.strip
        if settings.persisted?
          settings.collection_name = new_name
          settings.save!
        end
        @collection_name = new_name
      end

      def define_attribute_accessor(attribute_name)
        class_eval <<-RUBY
          def #{attribute_name}
            __doc__body_read_attribute('#{attribute_name}')
          end

          def #{attribute_name}=(value)
            __doc__body_write_attribute('#{attribute_name}', value)
          end

          def #{attribute_name}_changed?
            __doc__body_attribute_changed?('#{attribute_name}')
          end

          def #{attribute_name}_was
            __doc__body_attribute_was('#{attribute_name}')
          end

          def #{attribute_name}_change
            __doc__body_attribute_change('#{attribute_name}')
          end

          def #{attribute_name}_will_change!
            (__doc__body_will_change! || {})['#{attribute_name}']
          end
        RUBY
      end

      def convert_attribute_value_before_save(primary_key, selector, value)
        case value
        when Time
          value.in_time_zone
        when DateTime
          value.to_time.in_time_zone
        else
          value
        end
      end

      def convert_document_hash_before_save(primary_key, document_hash, prefix = nil)
        if document_hash
          document_hash.inject(HashWithIndifferentAccess.new) do |result_hash, (key, value)|
            selector =  if prefix
                          "#{prefix}.#{key}"
                        else
                          key
                        end
            case value
            when Hash
              result_hash[key] = convert_document_hash_before_save(primary_key, value, selector)
            when Array
              result_hash[key] = convert_document_array_before_save(primary_key, value, selector)
            else
              result_hash[key] = convert_attribute_value_before_save(primary_key, selector, value)
            end
            result_hash
          end
        end
      end

      def convert_document_array_before_save(primary_key, document_array, prefix = nil)
        if document_array
          document_array.map.with_index do |value, index|
            selector = "#{prefix}[#{index}]"
            case value
            when Hash
              convert_document_hash_before_save(primary_key, value, selector)
            when Array
              convert_document_array_before_save(primary_key, value, selector)
            else
              convert_attribute_value_before_save(primary_key, selector, value)
            end
          end
        end
      end
    end

  protected

    def timestamp_attributes_for_update
      [] # ActiveRecord depend on real table columns, so we use an alternative timestamps method
    end

    def timestamp_attributes_for_create
      [] # ActiveRecord depend on real table columns, so we use an alternative timestamps method
    end

    def create_record
      write_attribute(self.class.primary_key, self.__doc__body[self.class.primary_key].to_s.strip.downcase)
      if read_attribute(self.class.primary_key).blank?
        write_attribute(self.class.primary_key, (self.__doc__body[self.class.primary_key] = SecureRandom.uuid))
      end

      self.__doc__model_settings_id = self.class.persisted_settings.id
      self.__doc__version = 1

      if self.class.persisted_settings.include_version_number == true &&
         __doc__body_read_attribute(self.class.persisted_settings.version_attribute_name) == nil
        __doc__body_write_attribute(self.class.persisted_settings.version_attribute_name, self.__doc__version)
      end

      if self.class.persisted_settings.use_timestamps
        __local__current_time = Time.zone.now
        __doc__body_write_attribute(self.class.persisted_settings.created_at_attribute_name, __local__current_time)
        __doc__body_write_attribute(self.class.persisted_settings.updated_at_attribute_name, __local__current_time)
      end

      super
    end

    def update_record(*args)
      if self.changed_attributes.keys.include?(self.class.primary_key)
        raise ArgumentError, "Primary key '#{self.class.primary_key}' cannot be modified."
      end

      if self.__doc__body_changed?
        self.__doc__version = self.__doc__version + 1
      end

      if self.class.persisted_settings.include_version_number == true &&
         __doc__body_attribute_changed?(self.class.persisted_settings.version_attribute_name) == false
        __doc__body_write_attribute(self.class.persisted_settings.version_attribute_name, self.__doc__version)
      end

      if self.class.persisted_settings.use_timestamps && __doc__body_attribute_changed?(self.class.persisted_settings.updated_at_attribute_name)
        __local__current_time = Time.zone.now
        __doc__body_write_attribute(self.class.persisted_settings.updated_at_attribute_name, __local__current_time)
      end
      super
    end

    def typecasted_attribute_value(name)
      result = super
      name = name.to_s
      if name == '__doc__body'
        self.class.convert_document_hash_before_save(self[self.primary_key], result)
      else
        result
      end
    end
  end
end 
