#!/bin/sh
# 该脚本用于启动GraphHopper导航服务
# 要求在脚本同级目录下有格式为GH*的导航数据目录，如GH-20181126T190440
# 脚本会获取最新的目录作为数据工作目录启动服务

cd "$(dirname "$0")"

tab=graphhoper-server
pid=`ps -ef | grep $tab | grep -v "grep" | cut -c 9-15`
if [ "${pid}" != "" ]; then
  echo "$tab is running, pid:${pid}, now stoping it"
  kill ${pid}
fi

CACHE_DIRS=(`ls -d GH* | sort -r`)
PBF=${CACHE_DIRS[0]}/osm.pbf
JAVA_OPTS="-Xmx2g -Xms2g"
CONF="-Dgraphhopper.datareader.file=$PBF"

echo $PBF
app=graphhopper-web-0.11-SNAPSHOT.jar
nohup java $JAVA_OPTS $CONF -D$tab -jar $app server config-server.yml 2>&1 & disown
