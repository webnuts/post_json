module PostJson
  module DynamicIndexMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def dynamic_indexes
        if settings.new_record?
          []
        else
          DynamicIndex.indexed_selectors(settings.id)
        end
      end

      def ensure_dynamic_index(*selectors)
        DynamicIndex.ensure_index(persisted_settings.id, *selectors).count
      end

      def destroy_dynamic_index(selector)
        if settings.new_record?
          false
        else
          DynamicIndex.destroy_index(settings.id, selector)
        end
      end
    end
  end
end