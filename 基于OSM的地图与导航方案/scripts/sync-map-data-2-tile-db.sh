#!/bin/bash
# 该脚本用于将新地图数据同步到瓦片数据库

now=`date`
echo "------------ start at: $now ------------------"

export REPLICATION_CLIENT_DIR=/root/osm/replication/client
export PGHOST=127.0.0.1
export PGUSER=postgres
export PGPASSWORD=123456
TILES_DB=tiles
CHANGE_FILE=$REPLICATION_CLIENT_DIR/changes.osc.gz
EXPIRY_MINZOOM=13
EXPIRY_METAZOOM=15-17
EXPIRY_FILE=$REPLICATION_CLIENT_DIR/dirty_tiles

rm $EXPIRY_FILE

cd /root/osm/openstreetmap-carto-4.13.0

/usr/local/bin/osmosis --read-replication-interval workingDirectory=${REPLICATION_CLIENT_DIR} --simplify-change --write-xml-change $CHANGE_FILE
/usr/local/bin/osm2pgsql --append --slim --expire-tiles $EXPIRY_METAZOOM --expire-output $EXPIRY_FILE -C 300 -G --hstore --style openstreetmap-carto.style --tag-transform-script openstreetmap-carto.lua -d $TILES_DB -H $PGHOST -U $PGUSER $CHANGE_FILE

# expire when user access, service with old tiles
/usr/local/bin/render_expired --min-zoom=$EXPIRY_MINZOOM --touch-from=$EXPIRY_MINZOOM -s /var/run/renderd/renderd.sock < "$EXPIRY_FILE"

# delete old tiles, need permission
/usr/local/bin/render_expired --min-zoom=$EXPIRY_MINZOOM --delete-from=$EXPIRY_MINZOOM -s /var/run/renderd/renderd.sock < "$EXPIRY_FILE" 

now=`date`
echo "------------ end at: $now ------------------"
echo "--------------------------------------------"
echo ""
echo ""
