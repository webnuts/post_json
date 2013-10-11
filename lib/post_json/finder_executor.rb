module PostJson
  class FinderExecutor

    include FinderMethods

    def initialize(collection_name)
      @collection_name = collection_name
    end

    def create(attributes = {})
      Collection.transaction do
        attributes = attributes.with_indifferent_access

        name = "#{collection(true).name}"
        given_id = attributes['id'].to_s
        given_id = given_id.gsub(/\/+/, "/")
        given_id = given_id[1..-1] if given_id[0] == "/"
        given_id =  if given_id == "" || given_id.downcase == "#{name}/"
                      "#{name}/"
                    elsif given_id.downcase.start_with?("#{name}/")
                      given_id
                    else
                      "#{name}/#{given_id}"
                    end

        attributes['id'] = given_id

        document_collection(true).create(attributes)
      end
    end

    def each(&block)
      document_collection.each(&block)
    end

    def execute(ignore_dynamic_indexes = false, &block)
      if ignore_dynamic_indexes == true || collection == nil
        block.call(documents_query)
      else
        result = block.call(documents_query)
        select_query = ActiveRecord::Base.connection.last_select_query
        select_duration = ActiveRecord::Base.connection.last_select_query_duration * 1000
        if collection.use_dynamic_index == true &&
           collection.create_dynamic_index_milliseconds_threshold < select_duration
          selectors = select_query.scan(/.*?json_selector\('(.*?)', __doc__body\)/).flatten.uniq
          collection.create_dynamic_indexes(selectors)
        end
        result
      end
    end

  protected

    def collection(create_if_not_exists = false)
      @collection ||= if create_if_not_exists
                        Collection.by_name(@collection_name).first_or_create
                      else
                        Collection.by_name(@collection_name).first
                      end
    end

    def document_collection(create_if_not_exists = false)
      collection(create_if_not_exists).try(:documents) || Document.none
    end

    def documents_query
      active_record_send_invocations.inject(document_collection) do |active_record_query, send_arguments|
        active_record_query.send(*send_arguments)
      end
    end
  end
end