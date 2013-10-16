class EnableExtensions < ActiveRecord::Migration
  def change
    # Install Postgresql 9.2 with PLV8 (might require )
    # 1. sudo add-apt-repository ppa:pitti/postgresql 
    # 2. sudo apt-get update
    # 3. sudo apt-get install postgresql-9.2 postgresql-contrib-9.2 postgresql-server-dev-9.2 libv8-dev
    # 4. sudo su - postgres
    # 5. Enter psql and run "CREATE USER webnuts WITH PASSWORD 'webnuts';" and "ALTER USER webnuts CREATEDB;" and "ALTER USER webnuts SUPERUSER;"
    # 6. git clone https://code.google.com/p/plv8js/
    # 7. cd plv8js
    # 8. make
    # 9. sudo make install

    # bundle exec rake db:create:all
    # bundle exec rake db:migrate
    # bundle exec rake db:test:prepare

    # See all available extensions:
    # ActiveRecord::Base.connection.execute("select * from pg_available_extensions;").each_row do |row|
    #   puts row.to_s
    # end

    enable_extension 'uuid-ossp'  # generate universally unique identifiers (UUIDs)
    enable_extension 'hstore'     # data type for storing sets of (key, value) pairs
    enable_extension 'plv8'       # PL/JavaScript (v8) trusted procedural language
    #enable_extension 'plcoffee'   # PL/CoffeeScript (v8) trusted procedural language
  end
end
