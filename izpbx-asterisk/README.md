# izpbx-asterisk

izPBX 是一个基于 Asterisk 引擎和 FreePBX 管理 GUI 的开箱即用云原生电话系统

更多信息：https://github.com/ugoviti/izdock-izpbx

# izPBX 开发

## 构建

Asterisk 18 + FreePBX 16：
`docker build --pull --rm --build-arg APP_DEBUG=1 --build-arg APP_VER_BUILD=1 --build-arg APP_BUILD_COMMIT=0000000 --build-arg APP_BUILD_DATE=$(date +%s) --build-arg APP_VER=dev-18.16 --build-arg FREEPBX_VER=16 -t izpbx-asterisk:dev-18.16 .`

Asterisk 18 + FreePBX 15：
`docker build --pull --rm --build-arg APP_DEBUG=1 --build-arg APP_VER_BUILD=1 --build-arg APP_BUILD_COMMIT=0000000 --build-arg APP_BUILD_DATE=$(date +%s) --build-arg APP_VER=dev-18.15 --build-arg FREEPBX_VER=15 -t izpbx-asterisk:dev-18.15 .`

## 运行

### Docker Run：
启动 MySQL：
`docker run --rm -ti -p 3306:3306 -v ${PWD}/data/db:/var/lib/mysql -e MYSQL_DATABASE=asterisk -e MYSQL_USER=asterisk -e MYSQL_ROOT_PASSWORD=CHANGEM3 -e MYSQL_PASSWORD=CHANGEM3 --name izpbx-db mariadb:10.6`

启动 izPBX：
`docker run --rm -ti --network=host --privileged --cap-add=NET_ADMIN -v ${PWD}/data/izpbx:/data -e MYSQL_SERVER=127.0.0.1 -e MYSQL_DATABASE=asterisk -e MYSQL_USER=asterisk -e MYSQL_ROOT_PASSWORD=CHANGEM3 -e MYSQL_PASSWORD=CHANGEM3 -e APP_DATA=/data --name izpbx izpbx-asterisk:dev-18.16`


### Docker Compose：

Asterisk 18 + FreePBX 16：
`docker-compose down ; docker-compose -f docker-compose.yml -f docker-compose-dev-18.16.yml up`

Asterisk 18 + FreePBX 15：
`docker-compose down ; docker-compose -f docker-compose.yml -f docker-compose-dev-18.15.yml up`
