# http://pgxn.org/dist/plv8/doc/plv8.html
# http://plv8-pgopen.herokuapp.com/
# http://www.craigkerstiens.com/2013/06/25/javascript-functions-for-postgres/
# http://www.postgresonline.com/journal/archives/272-Using-PLV8-to-build-JSON-selectors.html

class CreateProcedures < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute(json_numeric_procedure)
    ActiveRecord::Base.connection.execute(json_text_procedure)
    ActiveRecord::Base.connection.execute(js_filter_procedure)
    ActiveRecord::Base.connection.execute(json_selector_procedure)
    ActiveRecord::Base.connection.execute(json_selectors_procedure)
    ActiveRecord::Base.connection.execute(show_all_indexes_procedure)
    # ActiveRecord::Base.connection.execute(show_indexes_procedure)
    # ActiveRecord::Base.connection.execute(ensure_dynamic_index_procedure)
  end

  def json_numeric_procedure
"CREATE OR REPLACE FUNCTION json_numeric(key text, data json) RETURNS numeric AS $$
  if (data == null) {
    return null;
  }
  return data[key];
$$ LANGUAGE plv8 IMMUTABLE STRICT;"
  end

  def json_text_procedure
"CREATE OR REPLACE FUNCTION json_text(key text, data json) RETURNS text AS $$
  if (data == null) {
    return null;
  }
  return data[key];
$$ LANGUAGE plv8 IMMUTABLE STRICT;"    
  end

  def js_filter_procedure
"create or replace function js_filter(js_function text, json_arguments text, data json) returns numeric as $$
  if (data == null) {
    return null;
  }
  eval('var func = ' + js_function);
  eval('var args = ' + (json_arguments == '' ? 'null' : json_arguments));
  var final_args = [data].concat(args);
  var result = func.apply(null, final_args);
  return result == true || 0 < parseInt(result) ? 1 : 0;
$$ LANGUAGE plv8 IMMUTABLE STRICT;"
  end

  def json_selector_procedure
"CREATE OR REPLACE FUNCTION json_selector(selector text, data json) RETURNS text AS $$
  if (data == null || selector == null || selector == '') {
    return null;
  }
  var names = selector.split('.');
  var result = names.reduce(function(previousValue, currentValue, index, array) {
    if (previousValue == null) {
      return null;
    } else {
      return previousValue[currentValue];
    }
  }, data);
  return result;
$$ LANGUAGE plv8 IMMUTABLE STRICT;"    
  end

  def json_selectors_procedure
"CREATE OR REPLACE FUNCTION json_selectors(selectors text, data json) RETURNS json AS $$
  var json_selector = plv8.find_function('json_selector');
  var selectorArray = selectors.replace(/\s+/g, '').split(',');
  var result = selectorArray.map(function(selector) { return json_selector(selector, data); });
  return result;
$$ LANGUAGE plv8 IMMUTABLE STRICT;"
  end

  def show_all_indexes_procedure
    "CREATE OR REPLACE FUNCTION show_all_indexes() RETURNS json AS $$
      var sql = \"SELECT c3.relname AS table, c2.relname AS index FROM pg_class c2 LEFT JOIN pg_index i ON c2.oid = i.indexrelid LEFT JOIN pg_class c1 ON c1.oid = i.indrelid RIGHT OUTER JOIN pg_class c3 ON c3.oid = c1.oid LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c3.relnamespace WHERE c3.relkind IN ('r','') AND n.nspname NOT IN ('pg_catalog', 'pg_toast') AND pg_catalog.pg_table_is_visible(c3.oid) ORDER BY c3.relpages DESC;\"
      return plv8.execute( sql );
    $$ LANGUAGE plv8 IMMUTABLE STRICT;"
  end

#   def show_indexes_procedure
# "CREATE OR REPLACE FUNCTION show_indexes(table_name text DEFAULT '', index_prefix text DEFAULT '') RETURNS json AS $$
#   var show_all_indexes = plv8.find_function('show_all_indexes');
#   var indexes = show_all_indexes();
#   if (0 < (table_name || '').length) {
#     indexes = indexes.filter(function(row) { return row['table'] === table_name; });
#   }
#   if (0 < (index_prefix || '').length) {
#     indexes = indexes.filter(function(row) { return row['index'].lastIndexOf(index_prefix, 0) === 0; });
#   }
#   return indexes;
# $$ LANGUAGE plv8 IMMUTABLE STRICT;"
#   end

#   def ensure_dynamic_index_procedure
#     raise ArgumentError, "index name should be: dyn_col_id_md5_hash_of_selector and truncated to a length of 63"
#     raise ArgumentError, "it should only create 1 index and not multiple"


#     # CREATE INDEX CONCURRENTLY post_json_documents_body_age ON post_json_documents(json_selector('age', body))
# "CREATE OR REPLACE FUNCTION ensure_dynamic_index(selectors text, collection_id text) RETURNS json AS $$
#   var show_indexes = plv8.find_function('show_indexes');
#   var colId = collection_id.replace('-', '');
#   var indexPrefix = 'col_' + colId + '_';
#   var existingIndexes = show_indexes('post_json_documents', indexPrefix).map(function(row) { return row.index; });
#   var selectorArray = selectors.replace(/\s+/g, '').split(',');

#   var indexes = selectorArray.map(function(selector) { return {'name': indexPrefix + selector.replace('.', '_'), selector: selector}; });
#   var newIndexes = indexes.filter(function(index) { return existingIndexes.indexOf(index.name) == -1; });

#   newIndexes.forEach(function(index) {
#     var sql = \"CREATE INDEX \" + index.name + \" ON post_json_documents(json_selector('\" + index.selector + \"', body)) WHERE collection_id = '\" + colId + \"';\"
#     plv8.execute( sql );      
#   });

#   return newIndexes;
# $$ LANGUAGE plv8 IMMUTABLE STRICT;"
#   end
end
