# QWEN.md — quectel-freepbx-docker

## 项目概述

本项目是 [izPBX](https://github.com/ugoviti/izpbx) 的一个定制化 Fork，核心目标是将 **Quectel LTE 4G 模块**（如 EC25 Mini PCIe 系列）通过 `asterisk-chan-quectel` 驱动集成到 FreePBX/Asterisk 电话系统中，实现在 Docker 容器中快速部署支持 4G 蜂窝通话的 VoIP PBX 系统。

- **上游项目**: [ugoviti/izpbx](https://github.com/ugoviti/izpbx)
- **Docker 镜像**: `wiseowls/freepbx-quectel`（发布在 Docker Hub）
- **许可证**: GPL v3

## 技术架构

```
quectel-freepbx-docker/
├── docker-compose.yml          # 双容器编排：freepbx + mariadb
├── default.env                 # 参考环境变量（复制为 stack.env 使用）
├── stack.env                   # 实际运行时使用的环境变量（git-ignored）
├── izpbx-asterisk/             # 自定义 Docker 镜像构建上下文
│   ├── Dockerfile              # 基于 RockyLinux 8，编译 Asterisk + chan_quectel
│   ├── rootfs/                 # 容器运行时文件系统覆盖层
│   │   ├── entrypoint.sh       # 容器入口点脚本
│   │   ├── entrypoint-hooks.sh # 核心初始化钩子（FreePBX 安装、服务配置等）
│   │   └── etc/                # 运行时配置模板（asterisk, fail2ban, supervisord 等）
│   ├── build/                  # 构建辅助文件
│   ├── patch/                  # 补丁文件
│   └── README.md               # 构建与开发说明
├── .drone.yml                  # Drone CI 流水线（上游原始项目）
├── .github/workflows/          # GitHub Actions CI/CD
│   └── docker-image.yml        # 自动构建并推送 Docker 镜像到 Docker Hub
├── CHANGELOG.md                # 上游 izPBX 的变更日志
├── screenshots/                # 截图
└── LICENSE                     # GPL v3
```

### 容器架构（双容器反模式设计）

| 容器 | 镜像 | 说明 |
|------|------|------|
| `freepbx` | `wiseowls/freepbx-quectel` | Asterisk 引擎 + FreePBX Web GUI + chan_quectel + 其他服务 |
| `izpbx-db` | `mariadb:10.6.8` | MariaDB 数据库后端 |

> **注意**: FreePBX 生态并非为容器化设计，因此采用"反模式"双容器方案是必要的妥协。

## 关键组件与版本

| 组件 | 版本 | 说明 |
|------|------|------|
| 基础 OS | Rocky Linux 8 | RHEL 8 兼容长期支持发行版 |
| Asterisk | 18.14.0 LTS | PBX 引擎，源码编译 |
| FreePBX | 16 | Web 管理 GUI |
| MariaDB | 10.6.8 | 数据库 |
| asterisk-chan-quectel | 3.0x86-64 | Quectel 4G 模块驱动（核心定制） |
| asterisk-chan-dongle | master | 华为 3G Dongle 驱动（额外支持） |
| PHP | 7.4 | Web 后端 |
| Apache | 2.4 (mpm_prefork) | Web 服务器 |

## 环境变量配置

运行时配置由 `stack.env` 文件驱动（模板见 `default.env`）。关键变量类别：

- **数据库**: `MYSQL_SERVER`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`
- **网络端口**: `APP_PORT_HTTP`, `APP_PORT_HTTPS`, `APP_PORT_SIP`, `APP_PORT_PJSIP`, `APP_PORT_RTP_START`/`END` 等
- **FreePBX 设置**: `FREEPBX_AUTOUPGRADE_CORE`, `FREEPBX_AUTOUPGRADE_MODULES` 等
- **服务开关**: `CRON_ENABLED`, `HTTPD_ENABLED`, `FAIL2BAN_ENABLED`, `PHONEBOOK_ENABLED` 等
- **安全**: `FAIL2BAN_*` 系列变量控制 fail2ban 行为

## 构建镜像

镜像由 GitHub Actions 自动构建（`.github/workflows/docker-image.yml`），标签策略：

```yaml
# 触发条件：push 到 main 分支
image_tag=wiseowls/freepbx-quectel:$(date +%s)
```

本地开发构建（参考 `izpbx-asterisk/README.md`）：

```bash
cd izpbx-asterisk
docker build --pull --rm \
  --build-arg APP_DEBUG=1 \
  --build-arg APP_VER_BUILD=1 \
  --build-arg APP_BUILD_COMMIT=0000000 \
  --build-arg APP_BUILD_DATE=$(date +%s) \
  --build-arg APP_VER=dev-18.16 \
  --build-arg FREEPBX_VER=16 \
  -t izpbx-asterisk:dev-18.16 .
```

## 部署

```bash
# 1. 准备配置文件
cp default.env stack.env
# 编辑 stack.env，修改密码等关键配置

# 2. 启动服务
docker-compose up -d

# 3. 访问 Web GUI
# http://<docker-host-ip>
```

默认使用 `network_mode: host` 已被注释，改用桥接网络模式并暴露端口。如需 SIP NAT 处理，可启用 `network_mode: host`。

## 与上游 izPBX 的关键差异

1. **Docker 镜像**: 使用 `wiseowls/freepbx-quectel` 替代 `izdock/izpbx-asterisk`
2. **chan_quectel 模块**: 在 Dockerfile 中编译安装 `asterisk-chan-quectel`（Quectel EC25 等 4G 模块的 Asterisk 通道驱动）
3. **环境变量文件**: 使用 `stack.env` 替代 `.env`（docker-compose.yml 中引用 `stack.env`）
4. **CI/CD**: 使用 GitHub Actions 替代 Drone CI，镜像发布到 Docker Hub
5. **网络模式**: 默认采用桥接网络（`network_mode: host` 被注释），端口通过 docker-compose 映射

## 容器运行时初始化流程

`entrypoint-hooks.sh`（约 1600 行）是容器的核心初始化脚本，主要执行以下步骤：

1. 时区配置 (`TZ`)
2. 持久化数据目录符号链接（`APP_DATA=/data` → 各类配置/日志目录）
3. FreePBX 首次安装检测与执行（通过 `$APP_DATA/.initialized` 标记文件）
4. 数据库连接配置与等待就绪
5. 各服务配置生成（Apache、Postfix、Fail2ban、Zabbix、FOP2、NTP 等）
6. FreePBX 模块自动升级（可选）
7. PHPMyAdmin 配置（可选）
8. Let's Encrypt 证书自动管理（可选）
9. supervisord 启动各守护进程

## 服务管理

进入容器管理服务：

```bash
docker exec -it freepbx bash
supervisorctl status          # 查看所有服务状态
supervisorctl restart izpbx   # 重启 Asterisk/FreePBX
```

supervisord 管理的服务包括：`asterisk`, `cron`, `fail2ban`, `fop2`, `httpd`, `izpbx`, `tftpd`, `postfix`, `zabbix-agent`

## 开发约定

- **Shell 脚本**: 使用 Bash，变量默认值使用 `: ${VAR:=default}` 语法
- **Dockerfile**: 基于 RockyLinux 8，使用多阶段 RUN 减少层数（用 `&&` 串联和 `\` 续行）
- **配置管理**: 所有配置通过环境变量集中管理，模板化生成
- **Git 忽略**: `data/`、`test/`、`.env` 被忽略；实际运行时使用 `stack.env`
- **版本策略**: 上游使用 `18.<FreePBX_ver>.<patch>` 格式（如 18.16.13 表示 Asterisk 18 + FreePBX 16）

## 硬件要求

- Quectel EC25 Mini PCIe 系列 4G 模块
- Mini PCIe to USB 适配器
- USB 3.0 Hub
- 目标硬件平台: x86_64 (amd64)
