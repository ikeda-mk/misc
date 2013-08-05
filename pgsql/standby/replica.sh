PG_DIR=/usr/local/pgsql/data
rm -rf $PG_DIR/*
pg_basebackup -h postgres1 -U pgrepl -D $PG_DIR --xlog --progress --verbose

cp recovery.conf $PG_DIR
cp postgresql.conf $PG_DIR
