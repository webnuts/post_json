module PostJson
  class Base < ActiveRecord::Base
    self.abstract_class = true
    self.table_name = "post_json_documents"
    self.lock_optimistically = false

    # record_timestamps accessor is overriden and record_timestamps is true by default. See code below.
    self.record_timestamps = false

    def initialize(*args)
      __local__primary_key = self.class.primary_key
      __local__attrs = (args[0] || {}).with_indifferent_access
      __local__attrs[__local__primary_key] = __local__attrs[__local__primary_key].to_s if __local__attrs.has_key?(__local__primary_key)
      args[0] = {__local__primary_key => __local__attrs[__local__primary_key], '__doc__body' => __local__attrs}.with_indifferent_access
      super
    end

    def cache_key
      @dashed_name ||= self.class.name.underscore.dasherize
      __local__unique_version = __doc__version || Digest::MD5.hexdigest(attributes.inspect)
      "#{@dashed_name}-#{id}-version-#{__local__unique_version}"
    end

    def attributes
      read_attribute('__doc__body').try(:with_indifferent_access) || HashWithIndifferentAccess.new
    end

    def to_h
      attributes.deep_dup
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

    def [](attribute_name)
      self.__doc__body_read_attribute(attribute_name)
    end

    def []=(attribute_name, value)
      self.__doc__body_write_attribute(attribute_name, value)
    end

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

    class << self
      def post_json_all
        QueryTranslator.new(original_all)
      end

      alias_method :original_all, :all
      alias_method :all, :post_json_all

      def page(*args)
        all.page(*args)
      end

      def default_scopes
        if @collection_name
          model_settings = ModelSettings.table_name
          query = original_all.joins("INNER JOIN #{model_settings} ON #{table_name}.__doc__model_settings_id = #{model_settings}.id")
          query = query.where("lower(#{model_settings}.collection_name) = ?", collection_name.downcase)
          [Proc.new { query }] + super
        else
          [Proc.new { none }] + super
        end
      end

      def collection_name
        message = "You need to assign a collection name to class \"#{name}\":
class #{name}
  self.collection_name = \"customers\"
end"
        raise ArgumentError, message unless @collection_name.present?
        @collection_name
      end

      def collection_name=(name)
        raise ArgumentError, "name must be present" unless name.present?
        @collection_name = name.to_s.strip
      end

      def rename_collection(new_name)
        new_name = new_name.to_s.strip
        settings = find_settings
        if settings
          settings.collection_name = new_name
          settings.save!
        end
        @collection_name = new_name
      end

      def read_settings_attribute(attribute_name)
        attribute_name = attribute_name.to_s
        settings = find_settings_or_initialize
        settings[attribute_name]
      end

      def write_settings_attribute(attribute_name, value)
        attribute_name = attribute_name.to_s
        settings = find_settings_or_initialize
        settings[attribute_name] = value
        settings.save! 
        value
      end

      def meta
        HashWithIndifferentAccess.new(read_settings_attribute('meta'))
      end

      def meta=(hash)
        write_settings_attribute('meta', HashWithIndifferentAccess.new(hash))
      end

      def record_timestamps
        read_settings_attribute('use_timestamps')
      end

      def record_timestamps=(value)
        write_settings_attribute('use_timestamps', value)
      end

      def created_at_attribute_name
        read_settings_attribute('created_at_attribute_name')
      end

      def created_at_attribute_name=(attribute_name)
        write_settings_attribute('created_at_attribute_name', attribute_name)
      end

      def updated_at_attribute_name
        read_settings_attribute('updated_at_attribute_name')
      end

      def updated_at_attribute_name=(attribute_name)
        write_settings_attribute('updated_at_attribute_name', attribute_name)
      end

      def include_version_number
        read_settings_attribute('include_version_number')
      end

      def include_version_number=(value)
        write_settings_attribute('include_version_number', value)
      end

      def version_attribute_name
        read_settings_attribute('version_attribute_name')
      end

      def version_attribute_name=(attribute_name)
        write_settings_attribute('version_attribute_name', attribute_name)
      end

      def use_dynamic_index
        read_settings_attribute('use_dynamic_index')
      end

      def use_dynamic_index=(value)
        write_settings_attribute('use_dynamic_index', value)
      end

      def create_dynamic_index_milliseconds_threshold
        read_settings_attribute('create_dynamic_index_milliseconds_threshold')
      end

      def create_dynamic_index_milliseconds_threshold=(millisecs)
        write_settings_attribute('create_dynamic_index_milliseconds_threshold', millisecs)
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
        RUBY
      end

      def dynamic_indexes
        settings = find_settings
        if settings
          DynamicIndex.indexed_selectors(settings.id)
        else
          []
        end
      end

      def create_dynamic_index(selector)
        create_dynamic_indexes(selector)
      end

      def create_dynamic_indexes(*selectors)
        settings = find_settings_or_create
        DynamicIndex.ensure_index(settings.id, *selectors).count
      end

      def destroy_dynamic_index(selector)
        settings = find_settings_or_create
        if settings
          DynamicIndex.destroy_index(settings.id, selector)
        else
          false
        end
      end

      def find_settings
        ModelSettings.by_collection(collection_name).first
      end

      def find_settings_or_create
        ModelSettings.by_collection(collection_name).first_or_create(collection_name: collection_name)
      end

      def find_settings_or_initialize
        ModelSettings.by_collection(collection_name).first_or_initialize(collection_name: collection_name)
      end
    end

  protected

    def __model__settings
      @__model__settings ||= self.class.find_settings_or_create
    end

    def timestamp_attributes_for_update
      [] # ActiveRecord depend on real table columns, so we use an alternative timestamps method
    end

    def timestamp_attributes_for_create
      [] # ActiveRecord depend on real table columns, so we use an alternative timestamps method
    end

    def create_record
      self.id = self.__doc__body['id'].to_s.strip.downcase
      if self.id.blank?
        self.id = self.__doc__body['id'] = SecureRandom.uuid
      end

      self.__doc__model_settings_id = __model__settings.id
      self.__doc__version = 1

      if __model__settings.include_version_number == true &&
         __doc__body_read_attribute(__model__settings.version_attribute_name) == nil
        __doc__body_write_attribute(__model__settings.version_attribute_name, self.__doc__version)
      end

      if __model__settings.use_timestamps
        __local__current_time = Time.zone.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
        __doc__body_write_attribute(__model__settings.created_at_attribute_name, __local__current_time)
        __doc__body_write_attribute(__model__settings.updated_at_attribute_name, __local__current_time)
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

      if __model__settings.include_version_number == true &&
         __doc__body_attribute_changed?(__model__settings.version_attribute_name) == false
        __doc__body_write_attribute(__model__settings.version_attribute_name, self.__doc__version)
      end

      if __model__settings.use_timestamps && __doc__body_attribute_changed?(__model__settings.updated_at_attribute_name)
        __local__current_time = Time.zone.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
        __doc__body_write_attribute(__model__settings.updated_at_attribute_name, __local__current_time)
      end
      super
    end
  end
end 
