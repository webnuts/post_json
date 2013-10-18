class EnableExtensions < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'  # generate universally unique identifiers (UUIDs)
    enable_extension 'hstore'     # data type for storing sets of (key, value) pairs
    enable_extension 'plv8'       # PL/JavaScript (v8) trusted procedural language
  end
end
