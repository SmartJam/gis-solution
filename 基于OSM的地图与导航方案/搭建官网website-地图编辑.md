# 说明
. 官方的web项目提供了查看瓦片和编辑地图的功能  
. 在线编辑工具为iD，在搭建web的时候已自带  
. web项目基于Ruby on Rails  
. 本文档提及的操作基于centos7  
. 此处数据库权限管理`不规范`，就酱  
. 本文档参考[官方文档](https://github.com/openstreetmap/openstreetmap-website/blob/master/INSTALL.md)  
. 成功安装后在使用中会遇到问题，例如导入数据，添加帐号，创建管理员。可参考[说明](https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md)

# 安装依赖
. Ruby 2.3  
. RubyGems 1.3.1+  
. Bundler  
. PostgreSQL 9.5+ (官网要求不低于9.1上即可，后面使用Mapzen构建MVT时要求9.5+)  
. ImageMagick  
. Javascript Runtime  

## 其他依赖
```
yum install libxml2-devel gcc gcc-c++
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
```

## 安装Ruby
```
# rvm
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm reload

# ruby
rvm install 2.3.3

# gem, bundler
yum install rubygem-rdoc rubygem-bundler rubygems
```

## 安装PostgreSQL
```
# 安装
yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
yum install postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs postgresql96-devel postgis2_96 postgis2_96-utils postgis2_96-client -y

# 注册服务
systemctl enable postgresql-9.6.service

# 启动
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl start postgresql-9.6.service
```

## 部署website
```
# release版本是2014年的，项目维护很不到位，直接拉最新的吧
wget https://github.com/openstreetmap/openstreetmap-website/archive/master.zip
unzip master.zip
cd openstreetmap-website-master

# 安装pg时不一定找到pgsql开发库，这里指定对应目录
gem install pg -v '0.21.0' --source 'https://rubygems.org/'  -- --with-pg-dir=/usr/pgsql-9.6 

# root下使用bundle时会报“不要用root跑bundler”，无视就好，一会后就开始安装依赖
bundle install --system

gem install passenger
```

## 安装数据导入工具
**说明**  
. 如果不需要将地图数据导入数据库，可跳过这部分  
. osmosis用于把从其他地方获取的地图数据导入到数据库  
. osmosis为Java工具，请自行安装JRE

```
# osmosis
wget https://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.zip
unzip osmosis-latest.zip -d /var/lib/osmosis
ln -s /var/lib/osmosis/bin/osmosis /usr/local/bin/osmosis
```

# 组件初始化 

## 修改数据库配置
```
# 安装后的数据库默认只能通过postgres系统帐号访问
vi /var/lib/pgsql/9.6/data/pg_hba.conf
# 将 local all all peer 中的peer改为md5，如下
local   all             all                                     md5

# 将host all all 127.0.0.1/32 ident的ident改为md5，允许通过127.0.0.1访问
host    all             all             127.0.0.1/32            md5

# 重启postgres
systemctl restart postgresql-9.6.service

# 切换帐号到postgres，进入数据库管理终端
su postgres
psql

# 在管理终端给postgres设置密码，密码要求输入两次
\password postgres

# 退出管理终端并返回root帐号
\quit
exit
```

## 修改website配置
```
# 在openstreetmap-website-master项目下
cp config/example.application.yml config/application.yml
cp config/example.database.yml config/database.yml

# 按实际情况修改配置，server_url对实际访问没影响
vi config/application.yml

# 按实际情况修改数据库配置。host改为127.0.0.1
vi config/database.yml
```

## 初始化数据库
```
# 在openstreetmap-website-master项目下。确保开发环境的数据库创建成功，因为后续在开发环境数据库操作。
rake db:create

# 给数据库安装插件，假设数据为osm
psql -U postgres -W -d osm -c "CREATE EXTENSION btree_gist"

# 在openstreetmap-website-master项目下
ln -s /usr/pgsql-9.6/bin/pg_config /usr/bin/pg_config
cd db/functions/
make libpgosm.so
cd ../..

# 给数据库osm添加function
chmod +x /root
psql -U postgres -h127.0.0.1 -W -d osm -c "CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '`pwd`/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT"
psql -U postgres -h127.0.0.1 -W -d osm -c "CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '`pwd`/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT"
psql -U postgres -h127.0.0.1 -W -d osm -c "CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '`pwd`/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT"

# 初始化数据表
rake db:migrate
```

## 启动服务
```
# 在openstreetmap-website-master项目下
# 当前session运行
# rails server

# 守护进程
passenger start -p 3000 -e development -d

# 停止服务
# passenger stop -p 3000 

# 可通过3000端口访问服务
# 访问失败检查下防火墙
# 访问返回的瓦片通过官网获取
```

# 使用
## 导入广州的地图数据
**说明**  
. 不需要导入地图数据的话无视此操作  
. 可[下载](http://download.geofabrik.de/)并导入感兴趣的地图数据。数据包最小维度为国家，小心磁盘hold不住。  
. 该文档下载中国地图后，截取出广州区域的数据  
. 截取的区域经纬度为：左下(112.856, 22.480)，右上(114.096, 24.006)  

```
wget http://download.geofabrik.de/asia/china-latest.osm.pbf

# 截取广州区域数据(其实比广州大不少)，相关的道路和关系都会保留
osmosis --read-pbf china-latest.osm.pbf --bb left=112.856 right=114.096 top=24.006 bottom=22.480 completeWays=yes completeRelations=yes --write-xml file=guanghzou.osm

# 导入数据，等等吧
osmosis --read-xml guanghzou.osm --write-apidb host="127.0.0.1" database="osm" user="postgres" password="123456" validateSchemaVersion="no"

# 直接从pbf导入
# osmosis --read-pbf china-latest.osm.pbf --write-apidb host="127.0.0.1" database="osm" user="postgres" password="123456" validateSchemaVersion="no"
```

## 创建帐号
. 在首页通过`Sign Up`注册新帐号  
. 注册成功后会显示发送了邮箱验证邮件，其实并没有，因为没有配对应邮件服务  
. 修改数据库users表，`status`属性改为`active`  
. 新帐号可以登录  

## <span id="editIDKey">设置iD key</span>
. 登录后点击编辑按钮时会报错，显示常量`ID_KEY`未初始化  
. 参考[说明](https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md#oauth-consumer-keys)解决  
. 登录后在头像处点击`My Settings`进入`帐号管理页`  
. 在管理页中点击`oauth settings`进入`授权详情页`，url为：`/url/{你注册的名字}/oauth_clients`  
. 在授权页中点击`Register your application`注册新应用  
. Name填`Local iD`; Main Application URL填`http://{服务器域名或ip}:3000`, 例如我的http://my.centos:3000  
. 在底下权限栏中勾选`modify the map`  
. 点击`Register`  
. 注册成功后，在应用的授权详情页中复制`Consumer Key`  
. vi config/application.yml文件  
. 取消id_key的注释，并改为刚才复制的Consumer Key  
. 重启服务就可以编辑地图鸟  

## JOSM上使用自建website  
**通过website注册JOSM用的应用**  
. 流程与[设置iDKey一样](#editIDKey)  
. 应用名填JOSM, 权限都勾上  
. 注册成功后复制`Consumer Key`和`Consumer Secret`，后续在JOSM上用到  

**在JOSM上设置授权**  
. 工具栏`edit`上点击`Preferences`  
. 点击左边第二个工具(那个地球)，Connection Settings for the OSM server  
. 在`OSM Server URL`填上对应的URL，例如`http://192.168.32.178:3000/api`  
. 点击`Authentication`分页下的`Authorize now`  
. 在`authorization procedure`下拉选项中选择`Fully automatic`(默认就是)  
. 在`Basic`分页下填入注册OSM账号时的用户名和密码  
. 在`Advanced OAuth properties`分页反选`Use default settings`  
. 填上刚才注册应用获得的`Consumer Key`和`Consumer Secret`  
. 点击`Authorize now`  
. 授权成功后，点击`Accept Access Token`  
. DONE  

# 开发注意事项
## 软链接导致的windows开发惨案
`/app/assets/stylesheets/ltr/*.scss`和`/app/assets/stylesheets/rtl/*.scss`是**软链**！是**软链**！是**软链**！  
windows它老人家不认，运行时会出错。  
一个解决方案是用实际文件替，要注意不要提交到仓库，git的`skip-worktree`标记和`assume-unchaged`标记可以考虑下。
