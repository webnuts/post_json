ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do

  attr_accessor :last_select_query, :last_select_query_duration
  
  def select_all_with_measure_duration(arel, name = nil, binds = [])
    result = nil
    @last_select_query_duration = Benchmark.realtime do
      result = select_all_without_measure_duration(arel, name, binds)
    end
    @last_select_query = to_sql(arel, binds.dup).strip
    result
  end

  alias_method_chain :select_all, :measure_duration
end
