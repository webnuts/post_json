class Hash
  def flatten_hash(prefix = nil)
    self.inject(HashWithIndifferentAccess.new) do |result, (key, value)|
      combined_key = [prefix, key].compact.join(".")
      if value.is_a?(Hash)
        result.deep_merge!(value.flatten_hash(combined_key))
      else
        result[combined_key] = value
      end
      result
    end
  end

  def deepen_hash
    self.inject(HashWithIndifferentAccess.new) do |result, (key, value)|
      path_names = key.split(".")
      if path_names.length == 1
        result[key] = value
      else
        key_result = path_names.reverse.inject(nil) do |result, path_name|
          if result == nil
            HashWithIndifferentAccess.new(path_name => value)
          else
            HashWithIndifferentAccess.new(path_name => result)
          end
        end
        result.deep_merge!(key_result)
      end
      result
    end
  end

  def difference(h2)
    dup.delete_if { |k, v| h2[k] == v }.merge!(h2.dup.delete_if { |k, v| has_key?(k) })
  end
end
