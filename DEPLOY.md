# quectel-freepbx-docker 部署指南

## 目录

1. [环境要求](#环境要求)
2. [快速部署](#快速部署)
3. [配置详解](#配置详解)
4. [网络模式](#网络模式)
5. [Quectel 4G 模块配置](#quectel-4g-模块配置)
6. [多租户部署](#多租户部署)
7. [服务管理](#服务管理)
8. [备份与恢复](#备份与恢复)
9. [升级操作](#升级操作)
10. [常见问题](#常见问题)

---

## 环境要求

### 硬件

| 组件 | 最低要求 | 推荐配置 |
|------|---------|---------|
| CPU | x86_64, 2 核 | 4 核以上 |
| 内存 | 2 GB | 4 GB 以上 |
| 磁盘 | 20 GB | 50 GB+ SSD |
| 网络 | 1 个网口 | 双网口（WAN + LAN） |
| 4G 模块 | Quectel EC25 Mini PCIe | - |
| USB 转接 | Mini PCIe to USB 适配器 | - |
| USB Hub | - | ORICO 7 口 USB 3.0 |

### 软件

| 组件 | 版本 |
|------|------|
| Linux 操作系统 | Rocky Linux 8 / RHEL 8 / CentOS 8 / Ubuntu 20.04 / Debian 10 |
| Docker | 19.03+ |
| Docker Compose | 1.25+ |

### 安装 Docker 环境

**RHEL 8 / Rocky Linux 8 / CentOS 8：**

```bash
# 安装 Docker
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce -y
sudo systemctl enable --now docker

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

**Ubuntu / Debian：**

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sudo sh
sudo systemctl enable --now docker

# 安装 Docker Compose
sudo apt install docker-compose -y
```

---

## 快速部署

### 第一步：获取项目文件

```bash
# 克隆仓库
git clone https://github.com/tkhadimullin/quectel-freepbx-docker.git /opt/freepbx
cd /opt/freepbx
```

### 第二步：配置环境变量

```bash
# 复制模板文件
cp default.env stack.env

# 编辑配置文件（必须修改默认密码！）
vim stack.env
```

**必须修改的关键变量：**

```ini
# 数据库密码（务必修改！）
MYSQL_PASSWORD=你的安全密码
MYSQL_ROOT_PASSWORD=你的安全 Root 密码

# MySQL 服务器地址
# 使用 network_mode: host 时设为 127.0.0.1，否则设为 db
MYSQL_SERVER=127.0.0.1

# 时区设置
TZ=Asia/Shanghai

# FreePBX 时区
FREEPBX_PHPTIMEZONE=Asia/Shanghai
```

### 第三步：启动服务

```bash
# 启动所有容器（后台运行）
docker-compose up -d

# 查看启动日志
docker-compose logs -f

# 等待 60 秒左右，首次启动需要初始化 FreePBX
```

### 第四步：访问 Web 管理界面

打开浏览器访问：`http://<服务器IP>`

首次访问时 FreePBX 会自动完成初始化设置，创建管理员账户。

---

## 配置详解

### stack.env 完整配置说明

#### 数据库配置

```ini
# MySQL 服务器地址
# host 网络模式：127.0.0.1
# bridge 网络模式：db（容器名）
MYSQL_SERVER=127.0.0.1

# 数据库名称
MYSQL_DATABASE=asterisk
MYSQL_DATABASE_CDR=asteriskcdrdb

# 数据库用户
MYSQL_USER=asterisk

# 数据库密码（务必修改）
MYSQL_PASSWORD=CHANGEM3
MYSQL_ROOT_PASSWORD=CHANGEM3
```

#### 网络端口配置

```ini
# Web 服务端口
APP_PORT_HTTP=80          # HTTP Web 管理界面
APP_PORT_HTTPS=443        # HTTPS Web 管理界面

# SIP 信令端口
APP_PORT_PJSIP=5060       # PJSIP（推荐使用）
APP_PORT_SIP=5061         # 传统 chan_sip

# RTP 语音流端口范围
APP_PORT_RTP_START=10000  # RTP 起始端口
APP_PORT_RTP_END=20000    # RTP 结束端口（bridge 模式建议缩小到 10200）

# 其他服务端口
APP_PORT_IAX=4569         # IAX2 协议
APP_PORT_WEBRTC=8089      # WebRTC
APP_PORT_UCP_HTTP=8001    # UCP 用户控制面板 HTTP
APP_PORT_UCP_HTTPS=8003   # UCP 用户控制面板 HTTPS
APP_PORT_AMI=8088         # Asterisk Manager Interface
APP_PORT_MYSQL=3306       # MySQL 数据库
APP_PORT_FOP2=4445        # FOP2 操作面板
APP_PORT_ZABBIX=10050     # Zabbix 监控代理
```

#### FreePBX 高级设置

```ini
# 自动升级核心（谨慎使用，建议生产环境设为 false）
FREEPBX_AUTOUPGRADE_CORE=true

# 自动升级模块（仅首次部署时有效）
FREEPBX_AUTOUPGRADE_MODULES=true

# 系统标识
FREEPBX_FREEPBX_SYSTEM_IDENT=izPBX

# 呼叫等待默认关闭
FREEPBX_ENABLECW=0

# 时区
FREEPBX_PHPTIMEZONE=Asia/Shanghai

# 拨号音地区（it=意大利，可根据需要修改）
FREEPBX_TONEZONE=it
```

#### 服务开关

```ini
# 启用/禁用各服务（true=启用，注释或 false=禁用）
CRON_ENABLED=true         # 定时任务
HTTPD_ENABLED=true        # Apache Web 服务
IZPBX_ENABLED=true        # Asterisk + FreePBX 主服务
FAIL2BAN_ENABLED=true     # 安全防护
PHONEBOOK_ENABLED=true    # XML 电话本
#POSTFIX_ENABLED=true     # 邮件服务（默认禁用）
#FOP2_ENABLED=true        # 操作面板（默认禁用）
#ZABBIX_ENABLED=true      # 监控代理（默认禁用）
#DHCP_ENABLED=true        # DHCP 服务器（默认禁用）
#TFTP_ENABLED=true        # TFTP 服务器（默认禁用）
#NTP_ENABLED=true         # NTP 服务器（默认禁用）
```

#### Fail2ban 安全配置

```ini
FAIL2BAN_ENABLED=true
FAIL2BAN_ASTERISK_ENABLED=true

# 白名单 IP 段（本地网络）
FAIL2BAN_DEFAULT_IGNOREIP=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

# 封禁时间（秒）
FAIL2BAN_DEFAULT_BANTIME=300       # 5 分钟

# 检测窗口（秒）
FAIL2BAN_DEFAULT_FINDTIME=3600     # 1 小时内

# 最大重试次数
FAIL2BAN_DEFAULT_MAXRETRY=10

# 累犯封禁
FAIL2BAN_RECIDIVE_ENABLED=true
FAIL2BAN_RECIDIVE_BANTIME=1814400   # 3 周
FAIL2BAN_RECIDIVE_FINDTIME=15552000 # 6 个月
```

---

## 网络模式

### Bridge 模式（当前默认）

当前 `docker-compose.yml` 使用桥接网络，端口通过 Docker 映射。

**优点：**
- 支持同宿主机运行多个 izPBX 实例
- 容器网络隔离

**缺点：**
- SIP/RTP NAT 穿透需要额外配置
- 大量 RTP 端口映射影响性能

**优化建议：** 缩小 RTP 端口范围

```ini
# 50 路并发通话推荐
APP_PORT_RTP_START=10000
APP_PORT_RTP_END=10200
```

### Host 模式

取消注释 `docker-compose.yml` 中的 `network_mode: host`，并注释 `ports` 和 `networks` 段。

**优点：**
- 无 NAT 问题，SIP/RTP 直接通信
- 性能最优

**缺点：**
- 同宿主机只能运行一个实例
- 容器直接暴露在宿主机网络上

---

## Quectel 4G 模块配置

### 硬件连接

```
Quectel EC25 Mini PCIe 模块
    ↓
Mini PCIe to USB 适配器
    ↓
USB 3.0 Hub
    ↓
服务器 USB 接口
```

插入后验证设备识别：

```bash
# 查看 USB 设备
lsusb | grep -i quectel

# 查看串口设备（通常出现 ttyUSB0-3）
ls /dev/ttyUSB*
```

### Docker USB 设备映射

`docker-compose.yml` 中已配置显式设备映射：

```yaml
services:
  freepbx:
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
      - /dev/ttyUSB1:/dev/ttyUSB1
      - /dev/ttyUSB2:/dev/ttyUSB2
      - /dev/ttyUSB3:/dev/ttyUSB3
```

> **注意**：如果设备名称不同（如某些系统显示为 `/dev/ttyACM*`），需要相应调整 `devices` 配置和 `quectel.conf` 中的路径。

### 驱动配置

4G 模块通道配置位于容器内 `/etc/asterisk/quectel.conf`：

```ini
[quectel0]
audio=/dev/ttyUSB1    ; 音频端口
data=/dev/ttyUSB2     ; AT 命令端口
```

### SMS 短信配置

SMS 行为由 `/etc/asterisk/extensions_custom.conf` 控制：

```ini
; 收到的短信会转发到 pjsip:1 分机
[ext-did-post-custom]
exten => sms,1,Verbose(来自 ${CALLERID(num)} 的短信)

; 外发短信的路由
[sms-out]
exten => _.,1,NoOp(发送短信从 ${MESSAGE(from)} 到 ${MESSAGE(to)})
```

### 验证模块状态

```bash
# 进入容器
docker exec -it freepbx bash

# 查看 Quectel 通道状态
asterisk -rx "quectel show devices"

# 查看设备信息
asterisk -rx "quectel show device quectel0"
```

---

## 多租户部署

### 场景一：独立数据库，Macvlan 网络

适用于需要每个 PBX 实例拥有独立公网 IP 的场景。

**步骤：**

1. 创建部署目录

```bash
mkdir -p /opt/pbx/tenant1 /opt/pbx/tenant2
```

2. 每个目录创建 `docker-compose.yml` 和 `stack.env`

3. 在 `docker-compose.yml` 中配置 macvlan：

```yaml
networks:
  pbx-ext:
    driver: macvlan
    driver_opts:
      parent: eth0    # 宿主机物理网卡名
    ipam:
      config:
      - subnet: 192.168.1.0/24

services:
  izpbx:
    networks:
      pbx-ext:
        ipv4_address: 192.168.1.221   # 不同实例使用不同 IP
```

4. 分别启动

```bash
cd /opt/pbx/tenant1 && docker-compose up -d
cd /opt/pbx/tenant2 && docker-compose up -d
```

### 场景二：共享数据库，单个 compose 文件

在同一个 `docker-compose.yml` 中定义多个 izPBX 实例，共享一个 MariaDB。

详见 `README.md` 中的 **Multi-Tenant VoIP PBX with shared global Database** 章节。

---

## 服务管理

### 容器级别操作

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f freepbx
docker-compose logs -f izpbx-db

# 重启所有服务
docker-compose restart

# 重启单个容器
docker restart freepbx
docker restart izpbx-db

# 停止服务
docker-compose down

# 完全重置（危险！将删除所有数据）
docker-compose down
rm -rf data/
docker-compose up -d
```

### 服务级别操作

```bash
# 进入容器
docker exec -it freepbx bash

# 查看所有服务状态
supervisorctl status

# 重启 Asterisk/FreePBX 服务
supervisorctl restart izpbx

# 重启 Web 服务
supervisorctl restart httpd

# 查看 Asterisk 控制台
asterisk -rvvv
```

### 可用服务列表

| 服务名 | 说明 | 重启命令 |
|--------|------|---------|
| `asterisk` | Asterisk PBX 引擎 | `supervisorctl restart asterisk` |
| `izpbx` | FreePBX 管理服务 | `supervisorctl restart izpbx` |
| `httpd` | Apache Web 服务器 | `supervisorctl restart httpd` |
| `cron` | 定时任务 | `supervisorctl restart cron` |
| `fail2ban` | 安全防护 | `supervisorctl restart fail2ban` |
| `fop2` | FOP2 操作面板 | `supervisorctl restart fop2` |
| `postfix` | 邮件服务 | `supervisorctl restart postfix` |
| `zabbix-agent` | Zabbix 监控 | `supervisorctl restart zabbix-agent` |
| `tftpd` | TFTP 服务器 | `supervisorctl restart tftpd` |

---

## 备份与恢复

### 自动备份（FreePBX 内置）

在 FreePBX Web 界面配置：

1. **Admin → Backup & Restore**
2. 添加备份任务：
   - 备份名称：Daily Backup
   - 存储位置：Local Storage
   - 计划：每天 00:00
   - 保留天数：14 天

### 手动备份

```bash
# 完整备份（包括数据库和配置文件）
cd /opt/freepbx
docker-compose down

# 备份数据目录
tar -czf freepbx-backup-$(date +%Y%m%d).tar.gz data/

# 备份配置文件
cp stack.env stack.env.backup

# 重新启动
docker-compose up -d
```

### 恢复

```bash
cd /opt/freepbx
docker-compose down

# 恢复数据
rm -rf data/
tar -xzf freepbx-backup-20240601.tar.gz

# 恢复配置（如有需要）
cp stack.env.backup stack.env

docker-compose up -d
```

---

## 升级操作

### 升级 Docker 镜像

```bash
cd /opt/freepbx

# 拉取最新镜像
docker-compose pull

# 重新创建容器
docker-compose up -d

# 如果 MariaDB 版本变更，升级数据库表
source stack.env
docker exec -it izpbx-db mysql_upgrade -u root -p$MYSQL_ROOT_PASSWORD
```

### 升级 FreePBX 模块

在 FreePBX Web 界面操作：

1. **Admin → Module Admin**
2. 点击 **Check Online**
3. 选择 **Upgrade all**
4. 点击 **Process**

---

## 常见问题

### 容器启动失败

```bash
# 检查日志
docker-compose logs freepbx

# 常见原因：
# 1. stack.env 未正确创建
# 2. 端口冲突（检查 80、443、5060 等端口）
# 3. MySQL 连接失败
```

### SIP 注册失败

1. 检查分机配置中的 `host` 参数
2. 检查防火墙是否开放了 SIP 和 RTP 端口
3. 如果使用 bridge 模式，确保 RTP 端口范围映射正确

### 4G 模块不工作

```bash
# 进入容器检查设备
docker exec -it freepbx bash
ls /dev/ttyUSB*

# 查看 Quectel 通道
asterisk -rx "quectel show devices"

# 查看 dmesg 日志
dmesg | grep -i quectel
```

### FreePBX 重载缓慢

```bash
# 进入容器关闭签名检查
docker exec -it freepbx bash
fwconsole setting SIGNATURECHECK 0
```

### 磁盘空间不足

```bash
# 检查各目录大小
du -sh /opt/freepbx/data/*

# 清理旧日志
docker exec -it freepbx bash
find /var/log -name "*.log" -mtime +30 -delete
```

### FOP2 许可证问题

```bash
docker exec -it freepbx bash

# 重新激活许可证
/usr/local/fop2/fop2_server --rp=http --reactivate --iface eth0

# 重新注册
/usr/local/fop2/fop2_server --rp=http --register --iface eth0 \
  --name "公司名称" --code "许可证代码"
```

---

## 生产环境检查清单

- [ ] 修改 `stack.env` 中所有默认密码
- [ ] 配置正确的时区 (`TZ`, `FREEPBX_PHPTIMEZONE`)
- [ ] 启用 `FAIL2BAN_ENABLED=true`
- [ ] 配置防火墙，仅开放必要端口
- [ ] 根据网络环境选择合适的网络模式
- [ ] 配置自动备份计划
- [ ] 测试 4G 模块通话功能
- [ ] 生产环境建议设置 `FREEPBX_AUTOUPGRADE_CORE=false`
- [ ] 定期检查日志和磁盘空间
