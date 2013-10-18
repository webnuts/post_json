module PostJson
  module DynamicIndexMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def dynamic_indexes
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
        DynamicIndex.ensure_index(settings.id, *selectors).count
      end

      def destroy_dynamic_index(selector)
        if settings
          DynamicIndex.destroy_index(settings.id, selector)
        else
          false
        end
      end
    end
  end
end