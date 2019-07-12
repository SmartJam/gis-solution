
# 安装
## 依赖
```
# JDK自行安装

# maven

```

## graphhopper
```
wget https://github.com/graphhopper/graphhopper/archive/0.11.0.zip
unzip graphhopper-0.11.0.zip && cd graphhopper-0.11.0
```

# 使用
```
cp config-example.yml config.yml
vi config.yml
    # 修改导航模式，可同时支持多种模式
    graph.flag_encoders: foot
    
    # 配置默认值允许本地访问，按需修改bindHost
    # 例如允许全世界访问
    bindHost: 0.0.0.0
    
# 预处理地图数据
export JAVA_OPTS="-Xmx4g -Xms2g"
./graphhopper.sh import /root/osm/osm-web-data/china-latest.osm.pbf

# 启动服务
./graphhopper.sh web /root/osm/osm-web-data/china-latest.osm.pbf
```


# 数据更新
数据更新涉及两部分：
1. 使用Osmosis从编辑数据库导出pbf
2. 根据pbf生成地图导航数据   

详情参考[脚本](./scripts/refresh-gh-data.sh)