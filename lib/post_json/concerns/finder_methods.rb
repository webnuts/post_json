require 'hashie'

module PostJson
  module FinderMethods
    extend ActiveSupport::Concern

    #
    # This module depends upon method 'execute'
    #

    include QueryMethods
    include ArgumentMethods

    def any?
      execute { |documents| documents.any? }
    end

    def blank?
      execute { |documents| documents.blank? }
    end

    def count(column_name = nil, options = {})
      selector =  if column_name.present?
                    define_selector(column_name)
                  else
                    column_name
                  end
      execute { |documents| documents.count(selector, options) }
    end

    def delete(id_or_array)
      where(id: id_or_array).delete_all
    end

    def delete_all(conditions = nil)
      where(conditions).execute { |documents| documents.delete_all }
    end

    def destroy(id)
      execute { |documents| documents.destroy(id) }
    end

    def destroy_all(conditions = nil)
      where(conditions).execute { |documents| documents.destroy_all }
    end

    def empty?
      execute { |documents| documents.empty? }
    end

    def exists?(conditions = nil)
      query = case conditions
              when nil
                self
              when Numeric, String
                where({id: conditions})
              else
                where(conditions)
              end

      query.execute { |documents| documents.exists? }
    end

    def find(*args)
      execute { |documents| documents.find(*args) }
    end

    def find_by(*args)
      where(*args).first
    end

    def find_by!(*args)
      find_by(*args) or raise ActiveRecord::RecordNotFound
    end

    def find_each(options = {})
      execute { |documents| documents.find_each(options) }
    end

    def find_in_batches(options = {})
      execute { |documents| documents.find_in_batches(options) }
    end

    def first(limit = nil)
      if limit
        limit(limit).execute { |documents| documents.first }
      else
        execute { |documents| documents.first }
      end
    end

    def first!
      execute { |documents| documents.first! }
    end

    def first_or_create(attributes = {})
      attributes = where_values_hash.with_indifferent_access.deep_merge(attributes)
      first or create(attributes)
    end

    def first_or_initialize(attributes = {})
      attributes = where_values_hash.with_indifferent_access.deep_merge(attributes)
      first or model_class.new(attributes)
    end

    def ids
      pluck('id')
    end

    def last(limit = nil)
      reverse_order.first(limit)
    end

    def last!
      reverse_order.first!
    end

    def load
      execute { |documents| documents.load }
    end

    def many?
      execute { |documents| documents.many? }
    end

    def pluck(*selectors)
      selectors = join_arguments(*selectors)
      if selectors == ""
        []
      elsif selectors == "*"
        execute { |documents| documents.pluck("\"#{table_name}\".__doc__body") }
      elsif selectors == "id"
        execute { |documents| documents.pluck("\"#{table_name}\".id") }
      else
        result = nil
        execute { |documents| result = documents.pluck("json_selectors('#{selectors}', \"#{table_name}\".__doc__body)") }
        if selectors.include?(",")
          result
        else
          result.flatten(1)
        end
      end
    end

    def select(*selectors)
      selectors = selectors.flatten(1)
      if selectors.length == 0
        []
      elsif selectors.length == 1
        selector = selectors[0]
        case selector
        when String, Symbol
          selector = selector.to_s.gsub(/\s+/, '')
          if selector == "*"
            pluck("*").map { |body| body ? Hashie::Mash.new(body) : body }
          else
            selectors = selector.split(",")
            if selectors.length == 1
              select({selector => selector})
            else
              select(selectors)
            end
          end
        when Hash
          flat_hash = selector.flatten_hash
          pluck(flat_hash.values).map do |row|
            flat_body = if flat_hash.keys.length == 1
                          {flat_hash.keys[0] => row}
                        else
                          Hash[flat_hash.keys.zip(row)]
                        end
            deep_hash = flat_body.deepen_hash
            Hashie::Mash.new(deep_hash) if deep_hash
          end
        else
          raise ArgumentError, "Invalid argument(s): #{selectors.inspect}"
        end
      else
        select(Hash[selectors.zip(selectors)])
      end
    end

    def size
      execute { |documents| documents.size }
    end

    def take(limit = nil)
      execute { |documents| documents.take(limit) }
    end

    def take!
      execute { |documents| documents.take! }
    end

    def to_a
      execute { |documents| documents.to_a }
    end

    def to_sql
      execute { |documents| documents.to_sql }
    end

    def where_values_hash
      where_equals = query_tree[:where_equal] || []
      values_hash = where_equals.inject({}) do |result, where_equal|
        key = where_equal[:attribute]
        result[key] = where_equal[:argument]
        result
      end
      values_hash.deepen_hash
    end

  protected

    def define_selector(attribute_name)
      case attribute_name.to_s
      when "id"
        "\"#{table_name}\".id"
      else
        "json_selector('#{attribute_name}', \"#{table_name}\".__doc__body)"
      end
    end

    def prepare_query_tree_for_method_mapping(query_tree)
      prepared_query_tree = query_tree.map do |method_sym, arguments_collection|
        arguments_collection.map do |arguments|
          case method_sym
          when :limit
            [:limit, arguments]
          when :offset
            [:offset, arguments]
          when :order
            name, direction = arguments.split(" ")
            selector = define_selector(name)
            [:order, "#{selector} #{direction}"]
          when :where_function
            function = arguments[:function]
            escape_sql_single_quote = function.gsub("'", "''")
            condition = "js_filter('#{escape_sql_single_quote}', '#{arguments[:arguments]}', \"#{table_name}\".__doc__body) = 1"
            [:where, condition]
          when :where_forward
            if arguments[0].is_a?(String)
              json_regex = "json_([^ =]+)"
              arguments[0] = arguments[0].gsub(/^#{json_regex}\ /) {"json_selector('#{$1}', \"#{table_name}\".__doc__body) "}
              arguments[0] = arguments[0].gsub(/\ #{json_regex}\ /) {" json_selector('#{$1}', \"#{table_name}\".__doc__body) "}
              arguments[0] = arguments[0].gsub(/\ #{json_regex}$/) {" json_selector('#{$1}', \"#{table_name}\".__doc__body)"}
            end
            [:where, arguments]
          when :where_equal
            selector = define_selector(arguments[:attribute])
            argument = arguments[:argument]
            case argument
            when Array
              values = argument.map{|v| v ? v.to_s : nil}
              [:where, "(#{selector} IN (?))", values]
            when Range
              first_value = argument.first ? argument.first.to_s : nil
              last_value = argument.last ? argument.last.to_s : nil
              [:where, "(#{selector} BETWEEN ? AND ?)", first_value, last_value]
            else
              value = argument ? argument.to_s : nil
              [:where, "#{selector} = ?", value]
            end
          else
            raise NotImplementedError, "Query tree method '#{method_sym}' not mapped to Active Record."
          end
        end
      end
      prepared_query_tree.flatten(1)
    end

    def active_record_send_invocations
      prepare_query_tree_for_method_mapping(query_tree)
    end
  end
end

    # def query(params)
    #   valid_params = params.slice(:filter, :filter_arguments, :count, :page, :per_page, :order, :limit, :offset, :select)

    #   inquiry = self
    #   inquiry = inquiry.where(valid_params[:filter], valid_params[:filter_arguments]) if valid_params[:filter].present?

    #   total_count = inquiry.count

    #   if valid_params[:count].to_s.downcase.in? ["true", "yes", "1"]
    #     total_count
    #   else
    #     meta = {
    #       page: 1,
    #       per_page: nil,
    #       total_pages: 1,
    #       total_count: total_count,
    #     }

    #     page, per_page = valid_params[:page].to_i, valid_params[:per_page].to_i

    #     inquiry = if valid_params[:page].present?
    #                 total_pages = total_count/per_page
    #                 total_pages = total_pages + 1 if 0 < total_count%per_page
    #                 meta[:page] = page
    #                 meta[:per_page] = per_page
    #                 meta[:total_pages] = total_pages
    #                 inquiry.page(page, per_page)
    #               else
    #                 inquiry
    #               end

    #     inquiry = inquiry.order(valid_params[:order]) if valid_params[:order].present?
    #     inquiry = inquiry.limit(valid_params[:limit].to_i) if valid_params[:limit].present?
    #     inquiry = inquiry.offset(valid_params[:offset].to_i) if valid_params[:offset].present?

    #     meta[:updated_at] = inquiry.except(:order)
    #                                .order('updatedAt desc')
    #                                .limit(1)
    #                                .select("updatedAt")
    #                                .first
    #                                .try("updatedAt")

    #     bodies =  if valid_params[:select].present?
    #                 inquiry.select(valid_params[:select])
    #               else
    #                 inquiry.pluck("body")
    #               end

    #     {documents: bodies, meta: meta}
    #   end
    # end

    # def digest_etag(seed = nil)
    #   inquery = except(:order).order('id')
    #   digest_seed = (inquery.pluck(:etag) + [inquery.to_sql + seed.to_s]).join
    #   etag = Digest::SHA2.hexdigest(digest_seed)
    # end

    # def latest_updated_at
    #   except(:order).order('updated_at DESC').limit(1).pluck(:updated_at).first
    # end

    # def xor_uuids(uuid_array)
    #   # move work to db: http://stackoverflow.com/questions/17739887/how-to-xor-md5-hash-values-and-cast-them-to-hex-in-postgresql
    #   uuid_array.inject("") { |result, uuid| (result.to_i(16) ^ uuid.to_i(16)).to_s(16) }
    # end 