# This will let you change the `hosts` entry to point to a
# db instance on a different IP if you wanted to do
# an end-to-end local test of the behavior
echo "database 127.0.0.1" >> /etc/hosts

# Set up 'db1/' directory initialized for pg
initdb -D db1
# NOTE:
# edit db1/postgrsql.vonf and set the following:
# unix_socket_directories='.'
# port = 5432
# listen_address='127.0.0.1` - if setting up s econd instance,
# use a different locally available addres.

# Start it
pg_ctl -D db1 start -l db1.log

# Create the DB and user. Assumes 'database' has a hosts entry.
psql template1 -c 'create database epgsql_test' -k db1
psql epgsql_test -c "create user epgsql_test with password 'epgsql_test'" -h database

# Start dropping traffic to reproduce the 'hang forever'
sudo iptables -A INPUT -m tcp -p tcp --dport 5432 -d 127.0.0.1  -j DROP

# Run this when you want to stop dropping traffic.  If the DB is still running on
# the same IP, this will cause the test driver to eventually recover.
sudo iptables -D INPUT -m tcp -p tcp --dport 5432 -d 127.0.0.1  -j DROP
