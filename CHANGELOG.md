# 变更日志
本项目所有值得注意的变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，
本项目遵循 [语义化版本](https://semver.org/spec/v2.0.0.html)。

## [18.16.13] - 2022-09-22
### 变更
- 更新 PBX 引擎至 Asterisk `18.14.0` LTS (https://downloads.asterisk.org/pub/telephony/asterisk/releases/ChangeLog-18.14.0)
- 更新 sngrep 至 `1.6.0` (https://github.com/irontec/sngrep/releases/tag/v1.6.0)
- 禁用 asterisk 模块 `res_geolocation`
### 修复
- 修复因 docker-compose.yml 中缺少 ulimit 设置导致的 crond CPU 使用率过高问题

## [18.16.12] - 2022-08-09
### 变更
- 更新 `default.env` 添加以下内容：（注意：请勿忘记相应地更新您的 `.env` 文件）
  - 新增：`#FAIL2BAN_DEFAULT_BANACTION=iptables-allports[blocktype=DROP]`

## [18.16.11] - 2022-07-21
### 修复
- 从 Apache 配置中移除 'MultiViews' 选项，该选项曾导致 FreePBX GQL/REST API 无法正常工作

## [18.16.10] - 2022-07-18
### 新增
- 新增 Asterisk chan_dongle 支持 (https://github.com/shalzz/asterisk-chan-dongle)
### 变更
- 操作系统软件包更新

## [18.16.9] - 2022-06-29
### 变更
- 更新 PBX 引擎至 Asterisk `18.13.0` LTS (https://downloads.asterisk.org/pub/telephony/asterisk/releases/ChangeLog-18.13.0)
- 更新数据库引擎至 MariaDB `10.6.8` LTS (https://mariadb.com/kb/en/mariadb-1067-release-notes/)
  - 部署后请勿忘记升级 MariaDB 数据库，执行：`source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD`

## [18.16.8] - 2022-05-14
### 变更
- 更新 PBX 引擎至 Asterisk `18.12.0` LTS (https://downloads.asterisk.org/pub/telephony/asterisk/releases/ChangeLog-18.12.0)
- 更新 sngrep 至 `1.5.0`
- 更新 zabbix-agent 至 `6.0`

## [18.16.7] - 2022-03-31
### 变更
- 更新 PBX 引擎至 Asterisk `18.11.1` LTS (https://downloads.asterisk.org/pub/telephony/asterisk/releases/ChangeLog-18.11.1)
- 更新 `default.env` 添加以下变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - 将 `APP_PORT_SIP` 的默认值从 `5160` 更改为 `5061`

## [18.16.6] - 2022-03-12
### 变更
- 更新 PBX 引擎至 Asterisk `18.10.1` LTS (https://downloads.asterisk.org/pub/telephony/asterisk/releases/ChangeLog-18.10.1)
- 更新 SpanDSP 至 `3.0.0-6ec23e5a7e`
- 更新数据库引擎至 MariaDB `10.6.7` LTS (https://mariadb.com/kb/en/mariadb-1067-release-notes/)
  - 部署后请勿忘记升级 MariaDB 数据库，执行：`source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD`

## [18.16.5] - 2022-02-12
### 变更
- 更新 PBX 引擎至 Asterisk `18.10.0` LTS (https://downloads.asterisk.org/pub/telephony/asterisk/releases/ChangeLog-18.10.0)

## [18.16.4] - 2022-02-03
### 修复
- 更新 FOP2 至 2.31.32（此版本修复了 FOP2 在 Docker 容器内长期存在的许可证问题——每次重启后许可证都会失效，需要重新激活）
- FOP2：在 fop2_server 命令中新增 `--rp=http` 选项，以绕过容器内运行时 FOP2 的许可证问题
- FOP2：改进许可证处理机制

## [18.16.3] - 2022-01-22
### 变更
- 更新 FOP2 至 2.31.31
- 可移植性增强：`MYSQL_ROOT_PASSWORD` 不再是必需的。
  如果出于安全原因未在 `.env` 文件中定义，则将使用 `MYSQL_PASSWORD` 替代
  警告：您必须手动预先确保 `asterisk` 和 `asteriskcdrdb` 数据库已存在，且 `MYSQL_USER` 拥有使用它们的权限，否则安装步骤将失败。
- 默认情况下，izPBX 新版本发布时不自动更新 FOP2，您必须在 `.env` 中设置 `FOP2_AUTOUPGRADE=true` 才能升级 FOP2（需要有效的许可证文件）
### 新增
- 更新 `default.env` 添加以下变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - 新增：`FOP2_AUTOUPGRADE`（默认值：`false`）

## [18.16.2] - 2021-12-24
### 新增
- 新增 `iproute` 软件包（在 SIP 设置中将接口绑定到 SIP 通道驱动时使用）

## [18.16.1] - 2021-12-15
### 变更
- 更新 PBX 引擎至 Asterisk 18.9.0 LTS (https://www.asterisk.org/asterisk-news/asterisk-18-9-0-now-available/)
- Let's Encrypt：将申请证书时使用的地址从 `SMTP_MAIL_TO` 更改为 `SMTP_MAIL_FROM`

## [18.16.0] - 2021-12-04
### 变更
- 重大变更：将 GUI 更新至 FreePBX 16（升级说明请参阅 README.md）
- 重大变更：chan_pjsip 现已成为默认的 SIP 通道驱动
- 重大变更：将 PHP 从 7.2 更新至 7.4（注意：在切换到本版本之前，请记得升级所有 FreePBX 模块，以避免出现关于不支持的 PHP 版本的警告）
- 禁用 Asterisk 模块：app_voicemail_imap
- 更新 sngrep 至 1.4.10
- 更新 `default.env` 添加以下内容：（注意：请勿忘记相应地更新您的 `.env` 文件）
  - 新增：`FREEPBX_AUTOUPGRADE_CORE=true`
  - 重命名：`FREEPBX_FIRSTRUN_AUTOUPDATE` 为 `FREEPBX_AUTOUPGRADE_MODULES`
  - 变更：`APP_PORT_PJSIP=5060`
  - 变更：`APP_PORT_SIP=5160`
  - 禁用：`FREEPBX_SIGNATURECHECK=0`
### 新增
- PHP 7.4 IonCube Loader 支持，用于商业模块支持（尚不可用，缺少 sysadmin rpm 包）
### 移除
- 移除 Asterisk 16 构建支持

## [18.15.24] - 2021-11-20
### 变更
- 首次部署时启用 FreePBX 模块自动更新
- 默认启用以下 FreePBX 模块：
  - bulkhandler
  - speeddial
  - weakpasswords
  - ucp
### 新增
- 更新 `default.env` 添加以下变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - `FREEPBX_FIRSTRUN_AUTOUPDATE=true`
  - `APP_PORT_WEBRTC=8089`
  - `APP_PORT_UCP_HTTP=8001`
  - `APP_PORT_UCP_HTTPS=8003`

## [18.15.23] - 2021-11-11
### 变更
- 更新引擎至 Asterisk 18.8.0 LTS
- 更新数据库引擎至 MariaDB 10.6.5
  - 部署后请勿忘记升级 MariaDB 数据库，执行：`source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD`

## [18.15.22] - 2021-10-21
### 变更
- 更新 Asterisk 至 18.7.1 LTS

## [18.15.21] - 2021-09-24
### 修复
- 将 `[ASTRUNDIR]=/var/run/asterisk` 移出持久化的 `/data` 存储，以避免启动之间出现问题
### 变更
- 将 MariaDB 从 10.5.12 更新至 10.6.4
  - 部署后请勿忘记升级 MariaDB 数据库，执行：`source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD`
- 更新 `default.env` 添加以下变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - 将 `HTTPD_HTTPS_ENABLED` 的默认值从 `true` 更改为 `false`

## [18.15.20] - 2021-09-19
### 变更
- 更新 `default.env` 添加以下新变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - `HTTPD_HTTPS_CERT_FILE`
  - `HTTPD_HTTPS_KEY_FILE`
  - `HTTPD_HTTPS_CHAIN_FILE`
- 自动重新生成默认自签名证书以匹配 `APP_FQDN` 变量的通用名称（Common Name）
- 增强自签名证书管理
- 将默认 https 证书目录从 `/etc/pki/izpbx` 更改为 `/etc/asterisk/keys`（请记得删除旧的 `/etc/pki/izpbx` 目录，因为不再使用）
- 使用默认的 FreePBX SSL 证书（注意：这将更改对外开放的 https 服务器的默认证书）

## [18.15.19] - 2021-09-07
### 修复
- 默认禁用 postfix，以避免在未正确配置时出现邮件循环和端口冲突
### 变更
- 更新 `default.env` 添加以下变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - 从 `POSTFIX_ENABLED=true` 改为 `#POSTFIX_ENABLED=true`

## [18.15.18] - 2021-09-02
### 修复
- 加快容器启动时间
### 新增
- chronyd (NTP) 服务支持
### 变更
- 更新 `default.env` 添加以下变量：（注意：请勿忘记更新您的自定义 `.env` 文件）
  - `NTP_SERVERS`
  - `NTP_ALLOW_FROM`
  - `APP_PORT_NTP`
  - `NTP_ENABLED`
- 更新 `docker-compose.yml` 添加以下行：（注意：请勿忘记更新您的自定义 `docker-compose.yml` 文件）
  - `${APP_PORT_NTP}:${APP_PORT_NTP}/udp`

## [18.15.17] - 2021-08-31
### 修复
- 修复时区问题导致的时间条件（TimeConditions）不生效（Asterisk 不遵循 `TZ` 变量）

## [18.15.16] - 2021-08-30
### 变更
- 重要提示：更改默认变量值：`TZ=UTC`
  （请在 .env 文件中更改或添加正确的时区位置，以避免破坏 Asterisk 的 CDR 和时间条件功能。例如：`TZ=Europe/Rome`）
- 重要提示：从 docker-compose.yml 中移除卷挂载 `/etc/localtime:/etc/localtime:ro`，改用 `TZ` 变量替代
### 修复
- 修复 APP_PORT_HTTP 变量替换错误

## [18.15.15] - 2021-08-20
### 变更
- 更新 Asterisk 至 18.6.0 LTS
### 修复
- 修复 `APP_PORT_AMI` 变量

## [18.15.14] - 2021-08-11
### 变更
- 将基础操作系统镜像从 CentOS 8 切换为 RockyLinux 8
- 更新 Asterisk 至 18.5.1 LTS
- 更新 MariaDB 至 10.5.12
### 修复
- FOP2 升级脚本临时解决方案

## [18.15.13] - 2021-05-25
### 新增
- 重要提示：在 `default.env` 中新增变量（请记得更新您的 `.env` 副本）：
  - `TZ=empty`（默认不设置）
### 变更
- 更新 Asterisk 至 18.5.0 LTS
- 更新 Zabbix Agent 至 5.4
- 更新 FOP2 至 2.31.30
- 更新 sngrep 至 1.4.9

## [18.15.12] - 2021-05-16
### 变更
- 更新至 Asterisk 18.4.0 LTS
- 更新至 MariaDB 10.5.10
### 修复
- 增强 izpbx supervisor 事件处理程序的行为
- 修复每日日志轮转时容器重启的问题

## [18.15.11] - 2021-04-17
### 变更
- 通过配置自定义的 docker-compose.yml 文件新增多租户支持（这是首个支持该功能的版本，后续将进一步完善）
### 修复
- 如果自定义 MySQL 用户不存在则自动创建（对多租户安装非常有用）

## [18.15.10] - 2021-04-15
### 新增
- 支持远程 Yealink XML 电话本，默认 URL（配置信息请参阅 README.md）：
  - http://izpbxip/pb（电话本菜单）
  - http://izpbxip/pb/yealink/ext（分机电话本）
  - http://izpbxip/pb/yealink/cm（联系人管理共享电话本）
- 重要提示：在 `default.env` 中新增变量（请记得更新您的 `.env` 副本）：
  - `PHONEBOOK_ENABLED="true"`
  - `PHONEBOOK_ADDRESS=`
- 新增 `php-ldap` 软件包
### 修复
- 修复 UserManager 缺少 LDAP 支持的问题
- 修复 `SMTP_ALLOWED_SENDER_DOMAINS` 默认变量

## [18.15.9] - 2021-04-14
### 修复
- 修复 codec_opus 未启用的问题

## [18.15.8] - 2021-04-07
### 变更
- 基于 Asterisk 18.3.0 LTS

## [18.15.7] - 2021-03-30
### 移除
- 重要提示：（破坏性变更）移除/弃用 `default.env` 中的以下变量（请记得更新您的 `.env` 副本）：
  - `ROOT_MAILTO`
### 新增
- 重要提示：在 `default.env` 中新增变量（请记得更新您的 `.env` 副本）：
  - `SMTP_MAIL_TO`
- 新增 `iptables` 软件包
- 新增 `conntrack-tools` 软件包（可使用 `conntrack -L` 列出活动连接，使用 `conntrack -F` 清除连接）
### 修复
- Fail2ban 因缺少 `iptables` 软件包而停止工作（感谢 @fa-at-pulsit）
### 变更
- 将 `ROOT_MAILTO` 默认设置为 `SMTP_MAIL_TO` 变量的内容（无论如何，您仍可在旧版 .env 中继续使用 ROOT_MAILTO 变量以保持兼容）
- 默认情况下，fail2ban 现在使用 `$SMTP_MAIL_FROM` 作为发件人，`$SMTP_MAIL_TO` 作为收件人地址

## [18.15.6] - 2021-03-25
### 变更
- 移除构建时附带的 libresample 归档包，现改用官方 CentOS 仓库软件包
- 修复 /etc/aliases 管理
- 增强首次部署体验
- 允许在初始部署时自定义 'asterisk' 和 'asteriskcdrdb' 数据库名称
- 在 `default.env` 中新增变量（更新您的 `.env` 副本）：
  - `MYSQL_DATABASE_CDR`
### 新增
- 新增 opusfile-devel 作为构建依赖
### 修复
- 恢复缺失的 codec_opus 支持
- 修复缺失 Asterisk 文档（/data/var/lib/asterisk/documentation/thirdparty/），该问题曾导致无法加载额外编解码器（如 codec_opus）

## [18.15.5] - 2021-03-18
### 变更
- 增强 Let's Encrypt 管理，并通过 cronjob（/etc/cron.daily/freepbx-le-renew）启用每日自动续期检查
- Apache 配置重构
- 小幅改进 entrypoint
- 在 `default.env` 中新增变量（更新您的 `.env` 副本）：
  - `LETSENCRYPT_COUNTRY_CODE`
  - `LETSENCRYPT_COUNTRY_STATE`

## [18.15.4] - 2021-03-17
### 变更
- 增强 Let's Encrypt 证书生成，使用 fwconsole 工具（感谢 @alenas）
- 新版 asterisk.sh Zabbix agent 脚本，改进活动通话检测（现在将忽略处于振铃状态的呼叫）
- 容器 Shell 增强
- 在 `default.env` 中新增变量（更新您的 `.env` 副本）：
  - `ZABBIX_HOSTNAME`
  - `ZABBIX_HOSTMETADATA`

## [18.15.3] - 2021-03-14
### 变更
- 将 MariaDB 从 10.5.8 更新至 10.5.9
  - 升级数据表，执行：`source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD`
- 首次安装的杂项优化
- Zabbix agent 脚本更新，新增功能

## [18.15.2] - 2021-03-11
### 变更
- 基于 Asterisk 18.2.2 LTS
### 新增
- 新增 Postfix TLS 和中继主机端口支持（关闭 #9）
- 在 `default.env` 中新增变量（更新您的 `.env` 副本）：
  - `SMTP_STARTTLS=true`

## [18.15.1] - 2021-02-17
### 变更
- 当使用 'network_mode: host' 时，禁用 docker-compose.yml 中的端口映射
- 将 APP_PORT_RTP_END 的默认值从 10200 更改为 20000

## [18.15.0] - 2021-01-28
### 变更
- 基于 Asterisk 18.2.0 LTS
- 首个 18.15.x 正式版本
- 将默认 PBX 引擎从 Asterisk 16 LTS 切换至 Asterisk 18 LTS
- 新版版本命名规则：
  - izPBX 18.15.x = 基于 Asterisk 18 LTS + FreePBX 15 的最新版本
  - izPBX 0.9.x   = 基于 Asterisk 16 LTS + FreePBX 15 的最新版本（不再受支持）
### 修复
- 每次启动时重新设置 FreePBX 和 Asterisk 文件的所有者，以避免权限拒绝错误

## [0.9.14] - 2021-01-21
### 变更
- Asterisk 16.16.0
- Asterisk 18.2.0

## [0.9.13] - 2020-12-22
### 修复
- 修复 SMTP SASL 认证问题

## [0.9.12] - 2020-11-26
### 变更
- Asterisk 16.15.0
- FOP2 2.31.29
- sngrep 1.4.8
### 新增
- 在 dev 分支中构建 Asterisk 18.1.0
- 新增 perl-DBI、perl-DBD-mysql，供 fop2 recording_fop2.pl 使用

## [0.9.11] - 2020-10-28
### 变更
- Asterisk 16.14.0
- 启用编译标志 `--enable app_mysql`，供 MySQL cidlookup 使用
- 实现 `$APP_DATA/.initialized` 文件以检测系统是否已安装
- docker logs 小幅重构
- 修复缺少默认 eth0 接口时 FOP2 注册的问题
- 修复缺少 `/var/run/asterisk`（FreePBX 最新更新所需）的问题
### 新增
- 更新 `default.env` 添加
  - `APP_PORT_AMI=8088`

## [0.9.10] - 2020-09-23
### 变更
- 在 docker-compose.yml 中定义发布版本的不可变镜像标签
- 将 MariaDB 从 10.4 升级至 10.5.5。请记得升级数据库架构，执行：
  - $ docker exec -it izpbx-db bash
  - $ mysql_upgrade -u root -p
### 新增
- 新增 phpMyAdmin 支持
- 更新 `default.env` 添加
  - 注意：请勿忘记相应地更新您的 `.env` 文件，添加以下行：
  - `PMA_ALIAS=/admin/pma`
  - `PMA_ALLOW_FROM=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16`

## [0.9.9] - 2020-09-20
### 变更
- 新增配置变量：`SMTP_MAIL_FROM`，用于设置外发邮件的发件人地址

## [0.9.8] - 2020-09-07
### 变更
- Asterisk 16.13.0
- FOP2 2.31.28
- 新增 glibc-langpack-en 以修复缺失的语言环境消息

## [0.9.7] - 2020-07-14
### 新增
- DNSMASQ（DHCP+TFTP）服务支持
### 变更
- 更新 `default.env` 添加
  - 注意：请勿忘记相应地更新您的 `.env` 文件，添加以下行：
  - `APP_PORT_DHCP=67`
  - `#DHCP_ENABLED=true`
  - `#DHCP_POOL_START=10.1.1.10`
  - `#DHCP_POOL_END=10.1.1.250`
  - `#DHCP_POOL_LEASE=72h`
  - `#DHCP_DOMAIN=izpbx.local`
  - `#DHCP_DNS=10.1.1.1`
  - `#DHCP_GW=10.1.1.1`
  - `#DHCP_NTP=10.1.1.1`
- 更新 `docker-compose.yml` 添加
  - 注意：请勿忘记相应地更新您的 `docker-compose.yml` 文件，添加以下行：
  - `${APP_PORT_DHCP}:${APP_PORT_DHCP}/udp`
- 将 `TFTPD_ENABLED` 重命名为 `TFTP_ENABLED`
### 移除
- 移除 kernel.org 的 tftp-server，替换为 dnsmasq 服务

## [0.9.6] - 2020-07-01
### 新增
- TFTP 服务器支持
### 变更
- 更新 `default.env` 添加 `APP_PORT_TFTP`（请勿忘记相应地更新您的 `.env` 文件）
- 更新 `docker-compose.yml` 添加 `APP_PORT_TFTP`
- 修复 Asterisk 日志轮转

## [0.9.5] - 2020-06-25
### 新增
- FOP2 自动升级支持
### 变更
- Asterisk 16.11.1

## [0.9.4] - 2020-05-15
### 新增
- FOP2 许可证代码管理
### 变更
- 更新 `default.env`：新增 `FOP2_LICENSE_NAME`、`FOP2_LICENSE_CODE`（请勿忘记相应地更新您的 `.env` 文件）

## [0.9.3] - 2020-04-30
### 变更
- Asterisk 16.10.0

## [0.9.2] - 2020-04-30
### 新增
- 持久化 root 家目录支持（用于保留 bash 和 Asterisk 控制台历史记录）
- Docker Shell 界面美化定制

## [0.9.1] - 2020-04-10
### 变更
- 修复拼写错误

## [0.9.0] - 2020-04-08
### 新增
- 首次公开发布
