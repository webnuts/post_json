module PostJson
  module DynamicIndexMethods
    extend ActiveSupport::Concern

    module ClassMethods
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
    end
  end
end