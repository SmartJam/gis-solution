# 说明
* openstreetmap-carto地图样式使用了[CartoCss项目](https://carto.com/developers/styling/cartocss/)   
* TileMill是可修改地图样式的客户端工具，但在导入openstreetmap-carto样式时很耗CPU、内存，且最终崩溃。而Mapbox已放弃维护TileMill，所以放弃使用TileMill。   
* kosmtik是服务端地图样式编辑工具，可直接加载openstreetmap-carto项目的project.mml文件，提供瓦片服务。  
* kosmtik安装参考[文档](https://ircama.github.io/osm-carto-tutorials/kosmtik-ubuntu-setup/#install-kosmtik)

# 安装
## 升级GCC
centos7默认安装的GCC为4.8.5，不完全支持C11，编译会报错
```
yum install centos-release-scl
yum install devtoolset-7-gcc*
scl enable devtoolset-7 bash
which gcc
gcc --version
```

## 安装kosmtik
```
npm install npm@latest -g
npm install -g n
n 8.9.0
npm -g install kosmtik

# 安装插件
kosmtik plugins --install kosmtik-overpass-layer --install kosmtik-fetch-remote --install kosmtik-overlay --install kosmtik-open-in-josm --install kosmtik-map-compare --install kosmtik-osm-data-overlay --install kosmtik-mapnik-reference --install kosmtik-geojson-overl
```

## 安装node-mapnik
```
cd /root/osm
git clone --depth=1 --branch v3.0.x https://github.com/mapnik/node-mapnik.git
make release_base

mv /usr/local/lib/node_modules/kosmtik/node_modules/mapnik /usr/local/lib/node_modules/kosmtik/node_modules/mapnik.npm
ln -s /root/osm/node-mapnik/ /usr/local/lib/node_modules/kosmtik/node_modules/mapnik
```

# 配置
vi /root/osm/openstreetmap-carto-4.13.0/localconfig.json
```
[
    {
        "where": "center",
        "then": [113.398, 23.16775, 15]
    },
    {
        "where": "Layer",
        "if": {
            "Datasource.type": "postgis"
        },
        "then": {
            "Datasource.dbname": "tiles",
            "Datasource.password": "123456",
            "Datasource.user": "postgres",
            "Datasource.host": "127.0.0.1"
        }
    }
]
```

# 运行
```
kosmtik serve /root/osm/openstreetmap-carto-4.13.0/project.mml --localconfig /root/osm/openstreetmap-carto-4.13.0/localconfig.json --host 0.0.0.0 
```





