#!/bin/bash
# 50-config.py or equivalent must be run first to set all omero.db.*
# omero.db.host may require special handling since the default is
# to use `--link postgres:db`

set -eu

omero=/opt/omero/server/venv3/bin/omero
omego=/opt/omero/server/venv3/bin/omego
cd /opt/omero/server

CONFIG_omero_db_host=${CONFIG_omero_db_host:-}
if [ -n "$CONFIG_omero_db_host" ]; then
    DBHOST="$CONFIG_omero_db_host"
else
    DBHOST=db
    $omero config set omero.db.host "$DBHOST"
fi
DBUSER="${CONFIG_omero_db_user:-omero}"
DBNAME="${CONFIG_omero_db_name:-omero}"
DBPASS="${CONFIG_omero_db_pass:-omero}"
DBPORT="${CONFIG_omero_db_port:-5432}"
POSTGRES_DB="${POSTGRES_DB:-postgres}"
ROOTPASS="${ROOTPASS:-omero}"
export PGPASSWORD="$DBPASS"
i=0
while ! psql -h "$DBHOST" -p "$DBPORT" -U "$DBUSER" "$POSTGRES_DB" >/dev/null 2>&1 < /dev/null; do
    i=$(($i+1))
    if [ $i -ge 50 ]; then
        echo "$(date) - postgres:5432 still not reachable, giving up"
        exit 1
    fi
    echo "$(date) - waiting for postgres:5432..."
    sleep 1
done
echo "postgres connection established"

psql -w -h "$DBHOST" -p "$DBPORT" -U "$DBUSER" "$DBNAME" -c \
    "select * from dbpatch" 2> /dev/null && {
    echo "Upgrading database"
    $omego db upgrade --serverdir=OMERO.server
} || {
    echo "Initialising database"
    psql -h "$DBHOST" -p "$DBPORT" -U "$DBUSER" -d "$POSTGRES_DB" -c "create database $DBNAME;"
    $omego db init --rootpass=$ROOTPASS --serverdir=OMERO.server
}
