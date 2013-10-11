module PostJson
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    module ClassMethods
      include FinderMethods

      def root
        collection("")
      end

      def [](collection_name)
        collection(collection_name)
      end

      def collection(collection_name)
        collection_name = if collection_name.downcase == "root"
                            ""
                          else
                            collection_name
                          end
        FinderExecutor.new(collection_name)
      end

      def each(&block)
        root.each(&block)
      end

      def execute(ignore_dynamic_indexes = false, &block)
        root.execute(ignore_dynamic_indexes, &block)
      end
    end
  end
end