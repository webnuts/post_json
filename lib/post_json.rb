require 'core_ext/hash_extend'
require 'core_ext/abstract_adapter_extend'
require 'core_ext/active_record_relation_extend'
require 'post_json/concerns/argument_methods'
require 'post_json/concerns/query_methods'
require 'post_json/concerns/finder_methods'
require 'post_json/concerns/settings_methods'
require 'post_json/concerns/dynamic_index_methods'
require 'post_json/query_translator'
require 'post_json/base'
require 'post_json/model_settings'
require 'post_json/dynamic_index'
require 'post_json/version'

module PostJson
  class << self
    def setup(collection_name, &block)
      collection = Collection[collection_name]
      collection.transaction do
        block.call(collection)
      end
    end
  end

  class Collection
    module Proxy
      class << self
        def const_missing(class_name)
          const_set(class_name, Class.new(PostJson::Base))
        end
      end
    end

    class << self
      def [](collection_name)
        name_digest = PostJson::ModelSettings.collection_name_digest(collection_name)
        class_name = "Collection_#{name_digest}"
        model_class = Proxy.const_get(class_name)
        model_class.collection_name = collection_name
        model_class
      end

      def names
        ModelSettings.order('collection_name').pluck('collection_name')
      end

      def to_a
        names.map { |collection_name| self[collection_name] }
      end

      def each(&block)
        to_a.each(&block)
      end
    end
  end
end
