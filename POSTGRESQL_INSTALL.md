# Install PostgreSQL 9.2 with PLV8 on Ubuntu

1. sudo add-apt-repository ppa:pitti/postgresql 
2. sudo apt-get update
3. sudo apt-get install postgresql-9.2 postgresql-contrib-9.2 postgresql-server-dev-9.2 libv8-dev
4. sudo su - postgres
5. Enter psql and run "CREATE USER <your_username> WITH PASSWORD '<your_password>';" and "ALTER USER <your_username> CREATEDB;" and "ALTER USER <your_username> SUPERUSER;"
6. git clone https://code.google.com/p/plv8js/
7. cd plv8js
8. make
9. sudo make install