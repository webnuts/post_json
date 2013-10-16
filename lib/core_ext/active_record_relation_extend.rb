# See https://github.com/rails/rails/blob/master/activerecord/CHANGELOG.md - Fixes #10615
#
# "Usage of implicit_readonly is being removed. Please usereadonlymethod explicitly to mark records asreadonly"
#
# The override below can be removed in the future

ActiveRecord::Relation.class_eval do
  def exec_queries_without_implicit_readonly
    records = original_exec_queries
    records.each { |r| r.instance_variable_set(:@readonly, false) } unless self.readonly_value == true
    records
  end

  alias_method :original_exec_queries, :exec_queries
  alias_method :exec_queries, :exec_queries_without_implicit_readonly
end