echo "database 127.0.0.1" >> /etc/hosts
initdb -D db1
pg_ctl -D db1 start -l db1.log
psql template1 -c 'create database epgsql_test' -k db1
vi db1/postgresql.conf # listen on tcp
psql template1 -c 'createdb epgsql_test' -h database
psql epgsql_test -c "create user epgsql_test with password 'password'" -h database

sudo iptables -A INPUT -m tcp -p tcp --dport 5432 -d 127.0.0.1  -j DROP
sudo iptables -D INPUT -m tcp -p tcp --dport 5432 -d 127.0.0.1  -j DROP
