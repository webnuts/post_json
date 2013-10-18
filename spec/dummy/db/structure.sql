--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: plv8; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plv8 WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plv8; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plv8 IS 'PL/JavaScript (v8) trusted procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: js_filter(text, text, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION js_filter(js_function text, json_arguments text, data json) RETURNS numeric
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
  if (data == null) {
    return null;
  }
  eval('var func = ' + js_function);
  eval('var args = ' + (json_arguments == '' ? 'null' : json_arguments));
  var final_args = [data].concat(args);
  var result = func.apply(null, final_args);
  return result == true || 0 < parseInt(result) ? 1 : 0;
$$;


--
-- Name: json_numeric(text, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_numeric(key text, data json) RETURNS numeric
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
  if (data == null) {
    return null;
  }
  return data[key];
$$;


--
-- Name: json_selector(text, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_selector(selector text, data json) RETURNS text
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
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
$$;


--
-- Name: json_selectors(text, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_selectors(selectors text, data json) RETURNS json
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
  var json_selector = plv8.find_function('json_selector');
  var selectorArray = selectors.replace(/ +/g, '').split(',');
  var result = selectorArray.map(function(selector) { return json_selector(selector, data); });
  return result;
$$;


--
-- Name: json_text(text, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_text(key text, data json) RETURNS text
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
  if (data == null) {
    return null;
  }
  return data[key];
$$;


--
-- Name: show_all_indexes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION show_all_indexes() RETURNS json
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
      var sql = "SELECT c3.relname AS table, c2.relname AS index FROM pg_class c2 LEFT JOIN pg_index i ON c2.oid = i.indexrelid LEFT JOIN pg_class c1 ON c1.oid = i.indrelid RIGHT OUTER JOIN pg_class c3 ON c3.oid = c1.oid LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c3.relnamespace WHERE c3.relkind IN ('r','') AND n.nspname NOT IN ('pg_catalog', 'pg_toast') AND pg_catalog.pg_table_is_visible(c3.oid) ORDER BY c3.relpages DESC;"
      return plv8.execute( sql );
    $$;


--
-- Name: show_indexes(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION show_indexes(table_name text DEFAULT ''::text, index_prefix text DEFAULT ''::text) RETURNS json
    LANGUAGE plv8 IMMUTABLE STRICT
    AS $$
  var show_all_indexes = plv8.find_function('show_all_indexes');
  var indexes = show_all_indexes();
  if (0 < (table_name || '').length) {
    indexes = indexes.filter(function(row) { return row['table'] === table_name; });
  }
  if (0 < (index_prefix || '').length) {
    indexes = indexes.filter(function(row) { return row['index'].lastIndexOf(index_prefix, 0) === 0; });
  }
  return indexes;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: post_json_documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE post_json_documents (
    id text NOT NULL,
    __doc__version integer,
    __doc__body json,
    __doc__model_settings_id uuid NOT NULL
);


--
-- Name: post_json_dynamic_indexes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE post_json_dynamic_indexes (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    selector text NOT NULL,
    model_settings_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: post_json_model_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE post_json_model_settings (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    collection_name text,
    meta json DEFAULT '{}'::json NOT NULL,
    use_timestamps boolean DEFAULT true,
    created_at_attribute_name text DEFAULT 'created_at'::text NOT NULL,
    updated_at_attribute_name text DEFAULT 'updated_at'::text NOT NULL,
    include_version_number boolean DEFAULT true,
    version_attribute_name text DEFAULT 'version'::text NOT NULL,
    use_dynamic_index boolean DEFAULT true,
    create_dynamic_index_milliseconds_threshold integer DEFAULT 50,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: post_json_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY post_json_documents
    ADD CONSTRAINT post_json_documents_pkey PRIMARY KEY (id, __doc__model_settings_id);


--
-- Name: post_json_dynamic_indexes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY post_json_dynamic_indexes
    ADD CONSTRAINT post_json_dynamic_indexes_pkey PRIMARY KEY (id);


--
-- Name: post_json_model_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY post_json_model_settings
    ADD CONSTRAINT post_json_model_settings_pkey PRIMARY KEY (id);


--
-- Name: post_json_documents_unique_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX post_json_documents_unique_id ON post_json_documents USING btree (id, __doc__model_settings_id);


--
-- Name: post_json_model_settings_lower_collection_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX post_json_model_settings_lower_collection_name ON post_json_model_settings USING btree (lower(collection_name));


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20131018135639');

INSERT INTO schema_migrations (version) VALUES ('20131018135640');

INSERT INTO schema_migrations (version) VALUES ('20131018135641');

INSERT INTO schema_migrations (version) VALUES ('20131018135642');

INSERT INTO schema_migrations (version) VALUES ('20131018135643');
