# 描述

结合 [izPBX](https://github.com/ugoviti/izpbx) 与 [asterisk-chan-quectel](https://github.com/IchthysMaranatha/asterisk-chan-quectel)，将 Quectel LTE 4G 模块集成到 FreePBX 中

# 所需硬件
 * https://www.quectel.com/product/lte-ec25-mini-pcie-series
 * https://amzn.asia/d/gz0bQsh
 * https://www.orico.shop/en/orico-matte-black-usb-30-hub-with-7-port-and-5gbps.html

# 项目目标
云端与本地部署，快速、自动化、可重复的 VoIP PBX 系统部署

# 特性
- 快速初始化引导，部署一套功能完整的 PBX 系统（60 秒内从零安装到运行就绪的一体化 PBX 系统）
- 内置基于 Asterisk® 项目的 PBX 引擎（从源码编译）
- 内置基于 FreePBX® 项目的 WEB 管理界面（预下载模块以实现更快的初始部署）
- 无供应商锁定，您可以通过导入/导出 FreePBX 备份来迁移至 izPBX 或从 izPBX 迁出
- 基于 Rocky Linux 8 64 位操作系统（RHEL 衍生版，长期支持）
- 容器镜像体积小（约 450 MB，而官方 FreePBX ISO 发行版文件为 2300 MB）
- 多租户 PBX 系统支持（请参阅**高级生产环境配置示例**章节）
- 兼容的 VoIP 话机支持自动远程 XML 电话本
- 持久化存储模式用于配置和非易失性数据
- Fail2ban 作为安全监控，用于阻止 SIP 和 HTTP 暴力攻击
- FOP2 操作面板
- 集成 Asterisk Zabbix 代理，用于服务健康监控
- 杂项 `izpbx-*` 工具脚本（如 `izpbx-callstats`）
- `izsynth` 工具 - TTS/文字转语音合成器、背景音乐叠加组装器以及用于 PBX 和家庭自动化系统的音频文件转换器
- `tcpdump` 和 `sngrep` 工具，用于调试 VoIP 通话
- supervisord 作为服务管理器，具备监控和服务故障自动重启功能
- postfix MTA 守护进程，用于发送邮件（通知、语音信箱和 FAX）
- 集成 cron 守护进程，用于执行定时任务
- 集成 TFTP 和 DHCP 服务器（由 DNSMasq 驱动），用于 VoIP 话机自动配置
- 集成 NTP 服务器
- Apache 2.4 和 PHP 7.2（mpm_prefork+mod_php 配置模式）
- 面向公网 PBX 的自动 Let's Encrypt HTTPS 证书管理
- 支持自定义商业 SSL 证书
- 服务日志轮转
- 所有配置通过单一中心 `.env` 文件进行
- 许多可自定义的变量供使用（请查看 `default.env` 文件）
- 仅两个容器设置：（**反模式容器设计**，但 FreePBX 生态系统的运行必需）
  - **izpbx**（izpbx-asterisk 容器：Asterisk 引擎 + FreePBX 前端 + 其他服务）
  - **izpbx-db**（mariadb 容器：数据库后端）

# 截图
#### izPBX 仪表盘 (FreePBX):
![izpbx-dashboard](https://raw.githubusercontent.com/ugoviti/izpbx/main/screenshots/izpbx-dashboard.png)

#### izPBX 操作面板 (FOP2):
![izpbx-izpbx-operator-panel](https://raw.githubusercontent.com/ugoviti/izpbx/main/screenshots/izpbx-operator-panel.png)

#### izPBX 监控仪表盘 (Zabbix):
![izpbx-zabbix-dashboard](https://raw.githubusercontent.com/ugoviti/izpbx/main/screenshots/izpbx-zabbix-dashboard.png)

#### izPBX CLI (Asterisk):
![izpbx-console](https://raw.githubusercontent.com/ugoviti/izpbx/main/screenshots/izpbx-cli.png)

# 部署 izPBX
建议使用 **docker-compose** 方式：

- 将您偏好的 Linux 操作系统安装到虚拟机或裸金属服务器中

- 从 https://www.docker.com/get-started 为您的操作系统安装 Docker 运行时和 docker-compose 工具
  - 基于 RHEL8 发行版的快速安装命令（如果您使用其他发行版，请跳过）：
```
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce -y
eval sudo curl -L "$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | grep "docker-compose-$(uname -s)-$(uname -m)\"" | awk '{print $2}')" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
sudo systemctl enable --now docker
```

- 创建 `docker-compose.yml`，或克隆 git 仓库，或从 https://github.com/ugoviti/izpbx/releases 下载最新 tar 包发布版，并解压到一个目录（例如 `/opt/izpbx`），使用 git 的更快方式：
  - `git clone https://github.com/ugoviti/izpbx.git /opt/izpbx`
  - `cd /opt/izpbx`

- 切换到最新官方发布版：
  - `git checkout tags/$(git tag | sort --version-sort | tail -1)`

- 将默认配置文件 `default.env` 复制为 `.env`：
  - `cp default.env .env`

- 自定义 `.env` 变量，特别是默认密码的安全相关配置：
  - `vim .env`

- 使用 docker-compose 命令部署并启动 izpbx：
  - `docker-compose up -d`

- 等待拉取完成（网络连接良好时约 60 秒），然后将网页浏览器指向您 Docker 宿主机的 IP 地址，按照初始设置向导操作

**注意：** 默认情况下，为正确处理 SIP NAT 和 SIP-RTP UDP 流量，izpbx 容器将使用 `network_mode: host`，因此 izpbx 容器将直接暴露到外部网络，而不使用 docker 内部网络范围（**network_mode: host** 将阻止在同一宿主机内运行多个 izpbx 容器）。
如需在同一宿主机中运行多个 izpbx 容器，请修改 docker-compose.yml 并注释掉 `#network_mode: host`（未经生产环境测试。RTP 流量可能会有问题）。
另一个可用选项是禁用 `network_mode: host`，使用 **macvlan** 网络模式在多租户模式下运行 izPBX。

## 通过 'docker run' 命令的替代部署方式（不推荐）
如果您想不使用 docker-compose 来测试 izPBX，可以使用以下 docker 命令：

1. 启动 MySQL：
`docker run --rm -ti -v ./data/db:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=CHANGEM3 -e MYSQL_PASSWORD=CHANGEM3 --name izpbx-db mariadb:10.4`

2. 启动 izPBX：
`docker run --rm -ti --network=host --privileged --cap-add=NET_ADMIN -v ./data/izpbx:/data -e MYSQL_ROOT_PASSWORD=CHANGEM3 -e MYSQL_PASSWORD=CHANGEM3 -e MYSQL_SERVER=127.0.0.1 -e MYSQL_DATABASE=asterisk -e MYSQL_USER=asterisk -e APP_DATA=/data --name izpbx izpbx-asterisk:latest`

# 升级 izPBX

1. 通过下载新的 tgz 发布版来升级 izpbx 版本，或更改 **docker-compose.yml** 文件中的镜像标签（从 git 发布页面查看上游 docker compose 是否有更新），或者如果您是直接从 GIT 克隆的，使用以下命令作为快速方法：
```
cd /opt/izpbx
git checkout main
git pull
git fetch --tags --all -f
git checkout tags/$(git tag | sort --version-sort | tail -1)
```

2. 使用以下命令升级 **izpbx** 部署：
（注意：**首先**检查 `docker-compose.yml` 和 `default.env` 是否有更新，并在您的 `.env` 文件中做相应更改）
```
docker-compose pull
docker-compose up -d
```

3. 如果 mariadb 数据库版本发生变化，请记得使用以下命令更新表结构
  `source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD`

4. 打开 FreePBX Web URL，从 FreePBX 菜单检查是否有模块更新：**Admin --> Modules Admin --> Check Online --> Upgrade all --> Process**

至此完成

### 跨 FreePBX 大版本升级路径
FreePBX 仅在首次部署时安装到持久化数据目录（当没有已存在的安装时）。

同一发行版的后续容器更新（例如从 18.15.1 到 18.15.2）不会升级 FreePBX 框架（仅 Asterisk 引擎会更新）。

如果您想将 FreePBX 框架/核心升级到大版本（例如从 15 到 16），您有两个选择：

1. 使用 izPBX 容器发布版自动升级（例如，从 18.15.x 切换到 18.16.x 发布版）
2. 使用 **FreePBX Upgrader** 工具手动升级

### 方法 1：使用 izPBX 容器发布版自动升级（推荐）
* 在将 izPBX 切换到新的大版本之前，确保所有 FreePBX 模块已更新到最新版本
* 确保您已对 `data` 目录进行了完整备份（重要！）
* 确保您在 `.env` 文件中启用了 `FREEPBX_AUTOUPGRADE_CORE=true`
* 部署 izPBX 的最新版本（例如，FreePBX 15 对应 18.15.x，FreePBX 16 对应 18.16.x，以此类推）
* izPBX 应能检测到已安装的旧版 FreePBX 并启动升级流程
* 从 **FreePBX / Modules Admin** 页面，检查所有模块是否已更新并重新启用被禁用的模块

### 方法 2：使用 FreePBX Upgrader 工具手动升级
* 在将 izPBX 切换到新的大版本之前，确保所有 FreePBX 模块已更新到最新版本
* 确保您已对 `data` 目录进行了完整备份（重要！）
* 确保您在 `.env` 文件中禁用了 `FREEPBX_AUTOUPGRADE_CORE=false`
* 部署 izPBX 的最新版本（例如，FreePBX 15 对应 18.15.x，FreePBX 16 对应 18.16.x，以此类推）
* izPBX 应使用旧版 FreePBX 启动，但所有依赖项已安装并准备好完成升级
* 打开 FreePBX 菜单：**Admin --> Modules Admin --> Check Online** 选择 **FreePBX Upgrader --> Process**
* 遵循以下说明：https://wiki.freepbx.org/display/FOP/Non+Distro+-+Upgrade+to+FreePBX+16
* 从 **FreePBX / Modules Admin** 页面，检查所有模块是否已更新并重新启用被禁用的模块

# 高级生产环境配置示例

### 多租户 VoIP PBX 配合独立数据库

#### 目标
- 在单个 Docker 宿主机上运行多个 izPBX 实例（必须为每个 izPBX 后端/前端分配一个外部静态 IP）
- 每个 izPBX 实例使用独立数据库

#### 配置
创建一个您希望部署 izpbx 数据文件的目录，并创建 `docker-compose.yml` 和 `.env` 文件：

示例：
```
mkdir yourgreatpbx
cd yourgreatpbx
vim docker-compose.yml
vim .env
```

注意：
- 根据您的环境需求修改 `docker-compose.yml`：
  - `parent:`（必须指定您的以太网卡）
  - `subnet:`（必须匹配您的内网网络范围）
  - `ipv4_address:`（每个 izPBX 前端必须拥有不同的外部 IP）
- 根据您的环境需求修改 `.env`：
  - `MYSQL_SERVER=db`（此处不能使用 localhost）

```yaml
version: '3'

networks:
  izpbx-0-ext:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
      - subnet: 10.1.1.0/24
        #ip_range: "10.1.1.221/30"
        #gateway: 10.1.1.1
  izpbx-1:
    driver: bridge

services:
  db:
    image: mariadb:10.5.9
    ## 警告：如果您升级了镜像标签，请进入容器并运行 mysql_upgrade：
    ## source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD
    command: --sql-mode=ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
    restart: unless-stopped
    env_file:
    - .env
    environment:
    - MYSQL_ROOT_PASSWORD
    - MYSQL_DATABASE
    - MYSQL_USER
    - MYSQL_PASSWORD
    ## 数据库配置
    volumes:
    - ./data/db:/var/lib/mysql
    networks:
      izpbx-1:

  izpbx:
    #hostname: ${APP_FQDN}
    image: izdock/izpbx-asterisk:18.15.11
    restart: unless-stopped
    depends_on:
    - db
    env_file:
    - .env
    volumes:
    - ./data/izpbx:/data
    cap_add:
    - SYS_ADMIN
    - NET_ADMIN
    privileged: true
    networks:
      izpbx-0-ext:
        ipv4_address: 10.1.1.221
      izpbx-1:
```

为您想要部署的每个 izPBX 重复上述步骤。请记住为每次 izpbx 部署创建独立的目录。

#### 部署
进入包含配置文件的每个目录并运行：
- `docker-compose up -d`

### 多租户 VoIP PBX 配合共享全局数据库和单个 docker-compose.yml 文件

#### 目标
- 在单个 Docker 宿主机上运行多个 izPBX 实例（必须为每个 izPBX 后端/前端分配一个外部静态 IP）
- 所有 izPBX 实例共用一个全局数据库

#### 配置
创建一个您希望部署所有 izpbx 数据文件的目录，并为每次 izpbx 部署创建 `docker-compose.yml` 和一个 `PBXNAME.env` 文件：

示例：
```
mkdir izpbx
cd izpbx
vim docker-compose.yml
vim izpbx1.env
vim izpbx2.env
vim izpbx3.env
```
等等...

注意：
- 根据您的环境需求修改 `docker-compose.yml`，更改：
  - `parent:`（必须指定您的以太网卡）
  - `subnet:`（必须匹配您的内网网络范围）
  - `ipv4_address:`（每个 izPBX 前端必须拥有不同的外部 IP）
- 请记得修改每个 `PBXNAME.env` 文件并为 `MYSQL` 设置不同的变量（为获得最佳安全性，每次部署使用不同的密码），例如：
  - `MYSQL_SERVER=db`（所有部署将使用相同的数据库名称）
  - `MYSQL_DATABASE=izpbx1_asterisk`
  - `MYSQL_DATABASE_CDR=izpbx1_asteriskcdrdb`
  - `MYSQL_USER=izpbx1_asterisk`
  - `MYSQL_PASSWORD=izpbx1_AsteriskPasswordV3ryS3cur3`
  - 等等...

```yaml
version: '3'

networks:
  izpbx-0-ext:
    driver: macvlan
    driver_opts:
      parent: enp0s13f0u3u1u3
    ipam:
      config:
      - subnet: 10.1.1.0/24
  izpbx-1:
    driver: bridge

services:
  db:
    image: mariadb:10.5.9
    ## 警告：如果您升级了镜像标签，请进入容器并运行 mysql_upgrade：
    ## source .env ; docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD
    command: --sql-mode=ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
    restart: unless-stopped
    env_file:
    - db.env
    environment:
    - MYSQL_ROOT_PASSWORD
    - MYSQL_DATABASE
    - MYSQL_USER
    - MYSQL_PASSWORD
    ## 数据库配置
    volumes:
    - ./data/db:/var/lib/mysql
    networks:
      izpbx-1:

  izpbx1:
    #hostname: ${APP_FQDN}
    image: izdock/izpbx-asterisk:18.15.11
    restart: unless-stopped
    depends_on:
    - db
    env_file:
    - izpbx1.env
    volumes:
    - ./data/izpbx1:/data
    cap_add:
    - NET_ADMIN
    privileged: true
    networks:
      izpbx-0-ext:
        ipv4_address: 10.1.1.221
      izpbx-1:

  izpbx2:
    #hostname: ${APP_FQDN}
    image: izdock/izpbx-asterisk:18.15.11
    restart: unless-stopped
    depends_on:
    - db
    env_file:
    - izpbx2.env
    volumes:
    - ./data/izpbx2:/data
    cap_add:
    - NET_ADMIN
    privileged: true
    networks:
      izpbx-0-ext:
        ipv4_address: 10.1.1.222
      izpbx-1:

  izpbx3:
    #hostname: ${APP_FQDN}
    image: izdock/izpbx-asterisk:18.15.11
    restart: unless-stopped
    depends_on:
    - db
    env_file:
    - izpbx3.env
    volumes:
    - ./data/izpbx3:/data
    cap_add:
    - NET_ADMIN
    privileged: true
    networks:
      izpbx-0-ext:
        ipv4_address: 10.1.1.223
      izpbx-1:
```

#### 部署
进入包含配置文件的目录并运行：
- `docker-compose up -d`

# 服务管理

### 重启整个 izPBX 部署的命令
`docker-compose restart izpbx`

### 仅重启 izPBX 容器的命令
`docker restart izpbx`

### 仅重启数据库容器的命令
`docker restart izpbx-db`

### 如果您想重启 `izpbx` 容器内的单个服务
进入容器：
`docker exec -it izpbx bash`

重启 izpbx 服务（Asterisk 引擎）：
`supervisorctl restart izpbx`

要重启其他可用服务，请使用 `supervisorctl restart SERVICE`

可用服务：
  - `asterisk`
  - `cron`
  - `fail2ban`
  - `fop2`
  - `httpd`
  - `izpbx`
  - `tftpd`
  - `postfix`
  - `zabbix-agent`

# 已测试的系统和宿主机兼容性
已测试的 Docker 运行时：
  - moby-engine 19.03
  - docker-ce 19.03
  - docker-compose 1.25

已测试的宿主机操作系统：
  - 基于 RHEL 6/7/8 的发行版
  - Fedora Core >30
  - Debian 10
  - Ubuntu 20.04

# 环境默认变量
请参阅 `default.env` 文件：
  - https://github.com/ugoviti/izpbx/blob/main/default.env

# Zabbix Agent 配置
关于在您的 Zabbix 服务器中安装和配置 Asterisk Zabbix 模板，请参阅官方仓库页面：
- https://github.com/ugoviti/zabbix-templates/tree/main/asterisk

# FreePBX 配置最佳实践
* **Settings-->Advanced Settings**
  * CW Enabled by Default: **NO**
  * Country Indication Tones: **Italy**
  * Ringtime Default: **60 seconds**
  * Speaking Clock Time Format: **24H**
  * PHP Timezone: **Europe/Rome**

* **Settings-->Asterisk Logfile Settings**
  * Security Settings-->Allow Anonymous Inbound SIP Calls: **No**
  * Security Settings-->Allow SIP Guests: **No**

* **Settings-->Asterisk SIP Settings**
  * File Name: **security**
  * Security: **ON**（其他全部 OFF）

* **Settings-->Filestore-->Local**
  * Path Name: **Local Storage**
  * Path: **__ASTSPOOLDIR__/backup**

* **Admin-->Backup & Restore**
  * Basic Information-->Backup Name: **Daily Backup**
  * Notifications-->Email Type: **Failure**
  * Storage-->Storage Location: **Local Storage**
  * Schedule and Maintinence-->Enabled: **Yes**
  * Schedule and Maintinence-->Scheduling: Every: **Day** Minute: **00** Hour: **00**
  * Maintinence-->Delete After Runs: **0**
  * Maintinence-->Delete After Days: **14**

* **Admin-->Contact Manager**
  * External
    * Add New Group
      * Name: **PhoneBook**
      * Type: **External**

* **Admin-->Caller ID Lookup Sources**
  * Source Description: **ContactManager**
  * Source type: **Contact Manager**
  * Cache Results: **No**
  * Contact Manager Group(s): **全选**

* **Admin-->Sound Languages-->Setttings**
  * Global Language: **Italian**

# 配置 VoIP XML 电话本查询
注意：已在 Yealink 话机上测试

- 按照上述方式配置 **Contact Manager**（Contact Manager 组名**必须**命名为 **PhoneBook**，否则默认不工作）

## 选项 1：电话本菜单
- 打开 VoIP 话机界面（Yealink 话机界面）：
  - **Directory-->Remote Phone Book**
    - Index 1（XML 菜单的 URL）
      - RemoteURL: **http://PBX_ADDRESS/pb**
      - Display Name: **PhoneBook**

## 选项 2：定义您想使用的每个电话本
- 打开 VoIP 话机界面（Yealink 话机界面）：
  - **Directory-->Remote Phone Book**
    - Index 1（分机电话本的 URL）
      - RemoteURL: **http://PBX_ADDRESS/pb/yealink/ext**
      - Display Name: **Extensions**
    - Index 2（共享电话本的 URL）
      - RemoteURL: **http://PBX_ADDRESS/pb/yealink/cm**
      - Display Name: **Shared Phone Book**

# 常见问题 / 故障排除
- FOP2 常用命令：
    注意：定义用于关联许可证的网络接口名称，例如：`eth0`
    - 进入 izpbx 容器：`docker exec -it izpbx bash`
    - 注册许可证：`/usr/local/fop2/fop2_server --rp=http --register --iface eth0 --name "Company Name" --code "LICENSECODE"`
    - 获取许可证详情：`/usr/local/fop2/fop2_server --rp=http --getinfo --iface eth0`
    - 重新激活许可证：`/usr/local/fop2/fop2_server --rp=http --reactivate --iface eth0`
    - 撤销许可证：`/usr/local/fop2/fop2_server --rp=http --revoke --iface eth0`

- FOP2 因许可证无效而运行在演示模式
  - FOP2 存在一个许可证模型的 bug（已多次向 FOP2 支持团队报告，但尚无官方解决方案）
    要规避此问题，通常需要**重新激活**许可证，但有时无效，因此唯一的解决方案是联系 FOP2 支持团队

- FreePBX 重新加载缓慢 (https://issues.freepbx.org/browse/FREEPBX-20559)
  - 作为临时**解决方案**，进入 izpbx 容器 shell 并运行：
    `docker exec -it izpbx bash`
    `fwconsole setting SIGNATURECHECK 0`

- 恢复出厂设置（警告！您的持久化存储将被清除！）：
  - `docker-compose down`
  - `rm -rf data`
  - `docker-compose up -d`

# 待办事项 / 未来开发计划
- 添加兼容 Raspberry PI 的 ARM 版本
- 通过 Helm Chart 实现 Kubernetes 部署（RTP UDP 端口范围存在重大问题...需要进一步调研，目前尚无有效方案）
- Hylafax+ 服务器 + IAXModem（用于发送 FAX。通过邮件接收 FAX 已可通过 FreePBX FAX 模块实现）
- macOS 宿主机支持？（编辑 docker-compose.yml 并注释 localtime 卷？）
- Windows 宿主机支持（需要使用 docker volume 而非本地目录路径？）

# 本项目的 BUG 和局限性
- izPBX 的开发采用了容器反模式设计理念。
  - FreePBX 并非为容器化应用而设计，其生态系统需要大量模块才能运行
  - FreePBX 模块更新将通过 FreePBX Admin Modules 页面自行管理，而非通过 izPBX 容器更新
- izPBX 必须在每个虚拟机或裸金属宿主机上部署一个实例
  - 使用 `network_mode: host` 时，默认不支持多实例部署
  - 请参阅**高级生产环境配置示例**章节了解多租户解决方案
- 默认使用 `network_mode: host`，因此 PBX 网络直接暴露在宿主机接口上（不使用内部容器网络），默认的 UDP RTP 端口范围可设置为 `10000` 到 `20000`
  - 如果您计划禁用 `network_mode: host`，请调整端口范围（通过 docker 技术栈转发 10000 个端口会导致较高的 CPU 使用率和更长的启动时间）。例如，对于 50 个并发通话：
`APP_PORT_RTP_START=10000`
`APP_PORT_RTP_END=10200`
为获得最佳安全性，请根据您的需求精细调整端口范围，不要使用标准端口范围！
- 在多租户模式下运行时，网络接口顺序不可预测。作为变通方案，使用的网络接口名称必须按字母顺序命名。参考：
  - https://gist.github.com/jfellus/cfee9efc1e8e1baf9d15314f16a46eca
  - https://github.com/moby/moby/issues/20179
- 默认情况下，FreePBX 使用模块包的签名校验，但这会导致重新加载 FreePBX 时延迟极高，因此默认已禁用此功能。参考：
  - https://issues.freepbx.org/browse/FREEPBX-20559
- 无法安装商业 FreePBX 模块
  - sysadmin rpm 模块缺失。正在寻找解决方案
- 缺少用于话机自动配置的良好终端管理器
  - 正在寻找有效方案

# 快速参考
- **开发与维护者**：
  [Ugo Viti](https://github.com/ugoviti/izpbx) @ InitZero S.r.l.

- **问题提交地址**：
  [https://github.com/ugoviti/izpbx/issues](https://github.com/ugoviti/izpbx/issues)

- **获取商业支持的渠道**：
  电子邮件：[support@initzero.it](mailto:support@initzero.it) - 网站：[InitZero Support](https://www.initzero.it/)

- **支持的架构**：
  [`amd64`]

- **支持的 Docker 版本**：
  [最新发布版](https://github.com/docker/docker-ce/releases/latest)（最低要求 1.6，尽力支持）

- **许可证**：
  [GPL v3](https://github.com/ugoviti/izpbx/blob/main/LICENSE)
