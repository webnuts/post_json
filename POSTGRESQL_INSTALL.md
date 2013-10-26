# Install PostgreSQL 9.2 with PLV8 on Ubuntu

1. sudo add-apt-repository ppa:pitti/postgresql 
2. sudo apt-get update
3. sudo apt-get install postgresql-9.2 postgresql-contrib-9.2 postgresql-server-dev-9.2 libv8-dev
4. sudo su - postgres
5. Run 'psql' and run "CREATE USER your_username WITH PASSWORD 'your_password';" and "ALTER USER your_username CREATEDB;" and "ALTER USER your_username SUPERUSER;"
6. Exit 'psql' by entering '\q'
7. git clone https://code.google.com/p/plv8js/
8. cd plv8js
9. make
10. sudo make install
