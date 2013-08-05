PG_DIR='/usr/local/pgsql/data'

pg_ctl -D $PG_DIR -l logfile stop
sleep 1

rm -rf $PG_DIR/*
initdb --locale='en_US.UTF-8' -D $PG_DIR 
mkdir $PG_DIR/archive

pg_ctl -D $PG_DIR -l logfile start
sleep 1

createdb xnat
createuser -s -I xnat
createuser -s -I pgrepl

sleep 3
cat xnat.dump | psql xnat

pg_ctl -D $PG_DIR -l logfile stop
sleep 2

cp pg_hba.conf $PG_DIR/.
cp postgresql.conf $PG_DIR/.

#pg_ctl -D /usr/local/pgsql/data/ -l logfile stop
#pg_ctl -D /usr/local/pgsql/data/ -l logfile start
#psql -U xnat -h localhost postgres

#cp pg_hba.conf /usr/local/pgsql/data/
#cp postgresql.conf /usr/local/pgsql/data/
