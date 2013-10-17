module PostJson
  module QueryMethods
    extend ActiveSupport::Concern

    #
    # Use 'query_tree' to integrate with this module
    #

    include ArgumentMethods

    def query_tree
      @query_tree ||= {}
    end

    def query_tree_renew!
      @query_tree = @query_tree.deep_dup
    end

    def query_clone
      cloned_self = clone
      cloned_self.query_tree_renew!
      cloned_self
    end

    def add_query(method, *arguments)
      query_tree[method] = (query_tree[method] || []) + arguments
      self
    end

    def except!(*attributes)
      remove_keys = flatten_arguments(attributes).map(&:to_sym)
      query_tree.except!(*remove_keys)
      self
    end

    def except(*attributes)
      query_clone.except!(*attributes)
    end

    def limit!(value)
      except!(:limit).add_query(:limit, value.to_i)
    end

    def limit(value)
      query_clone.limit!(value)
    end

    def offset!(value)
      except!(:offset).add_query(:offset, value.to_i)
    end

    def offset(value)
      query_clone.offset!(value)
    end

    def page!(page, per_page)
      page_int = page.to_i
      per_page_int = per_page.to_i
      offset!((page_int-1)*per_page_int).limit!(per_page_int)
    end

    def page(page, per_page)
      query_clone.page!(page, per_page)
    end

    def only!(*attributes)
      keep_keys = flatten_arguments(attributes).map(&:to_sym)
      query_tree.keep_if{|key| key.in?(keep_keys)}
      self
    end

    def only(*attributes)
      query_clone.only!(*attributes)
    end

    def order!(*args)
      if 0 < args.length
        flatten_arguments(args).each do |arg|
          name, direction = arg.split(' ')

          direction = direction.to_s.upcase
          direction = "ASC" unless direction.present?


          if direction.in?(["ASC", "DESC"]) == false
            raise ArgumentError, "Direction should be 'asc' or 'desc'"
          end

          add_query(:order, "#{name} #{direction}")
        end
      end
      self
    end

    def order(*args)
      query_clone.order!(*args)
    end

    def reorder!(*args)
      except!(:order).order!(*args)
    end

    def reorder(*args)
      query_clone.reorder!(*args)
    end

    def reverse_order!
      current_order = query_tree.delete(:order)
      if current_order.present?
        current_order.each do |arg|
          name, direction = arg.split(' ')
          reverse_direction = direction == "DESC" ? "ASC" : "DESC"
          order!("#{name} #{reverse_direction}")          
        end
        self
      else
        order!("id DESC")
      end
    end

    alias_method :reverse!, :reverse_order!

    def reverse_order
      query_clone.reverse_order!
    end

    alias_method :reverse, :reverse_order

    def where!(opts = :chain, *rest)
      if opts == :chain || opts.blank?
        self
      else
        case opts
        when String
          if opts.start_with?("function")
            add_query(:where_function, {function: opts, arguments: rest})
          else
            add_query(:where_forward, [opts] + rest)
          end
        when Array
          add_query(:where_forward, [opts] + rest)
        when Hash
          opts.stringify_keys.flatten_hash.each do |attribute, value|
            add_query(:where_equal, {attribute: attribute, argument: value})
          end
        else
          add_query(:where_forward, [opts] + rest)
        end
        self
      end
    end

    def where(filter = :none, *options)
      query_clone.where!(filter, *options)
    end
  end
end