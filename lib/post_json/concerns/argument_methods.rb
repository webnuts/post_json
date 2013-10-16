 module PostJson
  module ArgumentMethods
    extend ActiveSupport::Concern

    def join_arguments(*arguments)
      arguments = arguments[0] if arguments.length == 1 && arguments[0].is_a?(Array)
      arguments = arguments[0].split(',') if arguments.length == 1 && arguments[0].is_a?(String)

      arguments = arguments.map do |arg|
        case arg
        when nil
          nil
        when String
          arg.strip.gsub(/\s+/, ' ')
        when Symbol
          arg.to_s
        else
          arg
        end
      end

      arguments.join(',')
    end

    def flatten_arguments(*arguments)
      join_arguments(*arguments).split(',')
    end

    def assert_valid_indifferent_keys(options, *valid_keys)
      options.stringify_keys.assert_valid_keys(flatten_arguments(*valid_keys))
    end
  end
end
