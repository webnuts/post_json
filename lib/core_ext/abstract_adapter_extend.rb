ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do

  attr_accessor :last_select_query, :last_select_query_duration
  
  def measure_select_all(arel, name = nil, binds = [])
    result = nil
    @last_select_query_duration = Benchmark.realtime do
      result = original_select_all(arel, name, binds)
    end
    @last_select_query = to_sql(arel, binds.dup).strip
    result
  end

  alias_method :original_select_all, :select_all
  alias_method :select_all, :measure_select_all
end
