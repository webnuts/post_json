module PostJson
  module SettingsMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def settings
        @settings ||= ModelSettings.by_collection(collection_name).first_or_initialize(collection_name: collection_name)
      end

      def persisted_settings
        if settings.new_record?
          existing = ModelSettings.by_collection(collection_name).first
          if existing
            updates = settings.changes.inject({}) {|result, (k,v)| result[k] = v[1]; result}
            existing.update_attributes(updates)
            @settings = existing
          else
            settings.save!
          end
        end
        settings
      end

      def new?
        settings.new_record?
      end

      def persisted?
        settings.persisted?
      end

      def reload_settings!
        @settings = nil
        settings
      end

      def read_settings_attribute(attribute_name)
        attribute_name = attribute_name.to_s
        settings[attribute_name]
      end

      def write_settings_attribute(attribute_name, value)
        attribute_name = attribute_name.to_s
        if settings[attribute_name] != value
          settings[attribute_name] = value 
          settings.save! 
        end
        value
      end

      def meta
        HashWithIndifferentAccess.new(read_settings_attribute('meta'))
      end

      def meta=(hash)
        write_settings_attribute('meta', HashWithIndifferentAccess.new(hash))
      end

      def use_timestamps
        read_settings_attribute('use_timestamps')
      end

      def use_timestamps=(value)
        write_settings_attribute('use_timestamps', value)
      end

      alias_method :record_timestamps, :use_timestamps
      alias_method :record_timestamps=, :use_timestamps=

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
    end
  end
end