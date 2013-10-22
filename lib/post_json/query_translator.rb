module PostJson
  class QueryTranslator

    include FinderMethods

    def initialize(relation)
      @relation = relation
    end

    def model_class
      @relation.klass
    end

    def primary_key
      model_class.primary_key
    end

    def table_name
      model_class.table_name
    end

    def each(&block)
      relation_query.each(&block)
    end

    def execute(ignore_dynamic_indexes = false, &block)
      if ignore_dynamic_indexes == true || model_class.use_dynamic_index != true
        block.call(relation_query)
      else
        result = block.call(relation_query)
        select_query = ActiveRecord::Base.connection.last_select_query
        select_duration = ActiveRecord::Base.connection.last_select_query_duration * 1000
        if model_class.use_dynamic_index == true &&
           model_class.create_dynamic_index_milliseconds_threshold < select_duration
          selectors = select_query.scan(/.*?json_selector\('(.*?)', \"post_json_documents\"\.__doc__body\)/).flatten.uniq
          model_class.create_dynamic_indexes(selectors)
        end
        result
      end
    end

    def relation_query
      active_record_send_invocations.inject(@relation) do |query, send_arguments|
        query.send(*send_arguments)
      end
    end

    def create(attributes = {})
      relation_query.create(attributes.with_indifferent_access)
    end
  end
end