# http://pgxn.org/dist/plv8/doc/plv8.html

class CreateProcedures < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute(json_numeric_procedure)
    ActiveRecord::Base.connection.execute(json_text_procedure)
    ActiveRecord::Base.connection.execute(js_filter_procedure)
    ActiveRecord::Base.connection.execute(json_selector_procedure)
    ActiveRecord::Base.connection.execute(json_selectors_procedure)
    ActiveRecord::Base.connection.execute(show_all_indexes_procedure)
    ActiveRecord::Base.connection.execute(show_indexes_procedure)
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

  def show_indexes_procedure
"CREATE OR REPLACE FUNCTION show_indexes(table_name text DEFAULT '', index_prefix text DEFAULT '') RETURNS json AS $$
  var show_all_indexes = plv8.find_function('show_all_indexes');
  var indexes = show_all_indexes();
  if (0 < (table_name || '').length) {
    indexes = indexes.filter(function(row) { return row['table'] === table_name; });
  }
  if (0 < (index_prefix || '').length) {
    indexes = indexes.filter(function(row) { return row['index'].lastIndexOf(index_prefix, 0) === 0; });
  }
  return indexes;
$$ LANGUAGE plv8 IMMUTABLE STRICT;"
  end
end
