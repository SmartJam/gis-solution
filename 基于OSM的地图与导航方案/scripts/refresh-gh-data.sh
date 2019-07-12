#!/bin/sh
# 该脚本用于从地图编辑数据库备份pbf数据，用于更新导航数据
# 1. 脚本会将最新的地图数据导出到脚本所在目录，数据目录名格式为`GH-yyyyMMddTHHmmss`
# 2. 脚本根据最新的pbf文件创建GH cache文件
# 3. 使用最新地图导航数据启动导航服务
# 4. 删除过久的地图导航数据，只保留最近的5个
# 脚本依赖了备份地图差异数据时创建的数据库授权文件auth.conf

cd "$(dirname "$0")"

log() {
  echo "[script] [$(date +'%Y-%m-%d %H:%M:%S')]: $@"
}

NOW=`date '+%Y%m%dT%H%M%S'`
PBF_DIR=`pwd`/GH-$NOW
mkdir -p $PBF_DIR

PBF=$PBF_DIR/osm.pbf

# dump osm pbf
log "dump database to pbf"
DB_AUTH=/root/osm/replication/auth.conf
/usr/bin/time -v osmosis --read-apidb authFile=$DB_AUTH validateSchemaVersion=no --write-pbf file=$PBF omitmetadata=true

DUMP_RET=$?
if [ $DUMP_RET != 0 ]; then
  echo 'dump database failed, ret:$DUMP_RET, exit'
  rm -rf $PBF_DIR
  exit -1
fi


# prepare GH cache
log "prepare GH cache"

CACHE_DIR=gh-data-refresh
JAVA_OPTS="-Xmx2g -Xms2g"
CONF="-Dgraphhopper.datareader.file=$PBF"
/usr/bin/time -v java $JAVA_OPTS $CONF -jar graphhopper-web-0.11-SNAPSHOT.jar import config-import.yml

PREPARE_RET=$?
if [ $PREPARE_RET != 0 ]; then
  echo 'prepare GH cache failed, ret:$PREPARE_RET, exit'
  rm -rf $PBF_DIR
  exit -1
fi


# restart gh with latest map data
# modification is needed to satisfy remote deployment requirement
./start-gh.sh


# delete old cache dirs
log "remove old cache directories"

KEEP_LEN=5
CACHE_DIRS=(`ls -d GH* | sort`)
DELETE_LEN=$(( ${#CACHE_DIRS[@]} - $KEEP_LEN))

for (( idx=0; idx<=$(($DELETE_LEN - 1)); idx++ ))
do
  dir=${CACHE_DIRS[$idx]}
  log "remove dir:$dir"
  rm -rf $dir
done
