#!/bin/bash
# 作者: Ugo Viti <ugo.viti@initzero.it>
# 版本: 20210313
#set -ex

## 应用特定变量
: ${APP_DESCRIPTION:="izPBX Cloud Telephony System"}
: ${APP_CHART:=""}
: ${APP_RELEASE:=""}
: ${APP_NAMESPACE:=""}

: ${ASTERISK_VER:=""}
: ${FREEPBX_VER:=""}

# 覆盖容器应用使用的默认数据目录（供有状态应用使用）
: ${APP_DATA:=""}

# 时区管理临时解决方案
: ${TZ:="UTC"}
[ -e "/etc/localtime" ] && rm -f /etc/localtime
[ -e "/etc/timezone" ] && rm -f /etc/timezone
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
echo "$TZ" > /etc/timezone


# 用于持久化数据的默认目录和配置文件路径数组
declare -A appDataDirs=(
  [CRONDIR]=/var/spool/cron
  [ASTHOME]=/home/asterisk
  [ASTETCDIR]=/etc/asterisk
  [ASTVARLIBDIR]=/var/lib/asterisk
  [ASTSPOOLDIR]=/var/spool/asterisk
  [HTTPDHOME]=/var/www
  [HTTPDLOGDIR]=/var/log/httpd
  [ASTLOGDIR]=/var/log/asterisk
  [F2BLOGDIR]=/var/log/fail2ban
  [F2BLIBDIR]=/var/lib/fail2ban
  [FOP2APPDIR]=/usr/local/fop2
  [ROOTHOME]=/root
  [DNSMASQDIR]=/etc/dnsmasq.d
  [DNSMASQLEASEDIR]=/var/lib/dnsmasq
  [TFTPDIR]=/var/lib/tftpboot
)

# 配置文件
declare -A appFilesConf=(
  [FPBXCFGFILE]=/etc/freepbx.conf
  [AMPCFGFILE]=/etc/amportal.conf
)

# 缓存目录
declare -A appCacheDirs=(
  [ASTRUNDIR]=/var/run/asterisk
  [PHPOPCACHEDIR]=/var/lib/php/opcache
  [PHPSESSDIR]=/var/lib/php/session
  [PHPWSDLDIR]=/var/lib/php/wsdlcache
)

# FreePBX 目录
declare -A fpbxDirs=(
  [AMPWEBROOT]=/var/www/html
  [ASTETCDIR]=/etc/asterisk
  [ASTVARLIBDIR]=/var/lib/asterisk
  [ASTAGIDIR]=/var/lib/asterisk/agi-bin
  [ASTSPOOLDIR]=/var/spool/asterisk
  [ASTLOGDIR]=/var/log/asterisk
  [AMPBIN]=/var/lib/asterisk/bin
  [AMPSBIN]=/var/lib/asterisk/sbin
  [AMPCGIBIN]=/var/www/cgi-bin
  [AMPPLAYBACK]=/var/lib/asterisk/playback
  [CERTKEYLOC]=/etc/asterisk/keys
)

# Asterisk 额外目录
declare -A fpbxDirsExtra=(
  [ASTMODDIR]=/usr/lib64/asterisk/modules
)

# FreePBX 日志文件
declare -A fpbxFilesLog=(
  [FPBXDBUGFILE]=/var/log/asterisk/freepbx_debug.log
  [FPBXLOGFILE]=/var/log/asterisk/freepbx.log
  [FPBXSECLOGFILE]=/var/log/asterisk/freepbx_security.log
)

# FreePBX 可自定义设置
: ${FREEPBX_HTTPBINDPORT:="$APP_PORT_AMI"}

# FreePBX 可自定义 SIP 设置
declare -A fpbxSipSettings=(
  [rtpstart]=${APP_PORT_RTP_START}
  [rtpend]=${APP_PORT_RTP_END}
  [udpport-0.0.0.0]=${APP_PORT_PJSIP}
  [tcpport-0.0.0.0]=${APP_PORT_PJSIP}
  [bindport]=${APP_PORT_SIP}
)


# 20200318 仍无法修改
#declare -A freepbxIaxSettings=(
#  [bindport]=${APP_PORT_IAX}
#)

## 其他变量

# 主机名配置
[ ! -z ${APP_FQDN} ] && hostname "${APP_FQDN}" && export HOSTNAME=${HOSTNAME} # 如果定义了 APP_FQDN，则将主机名设置为 APP_FQDN
: ${SERVERNAME:=$HOSTNAME}      # （**$HOSTNAME**）默认 Web 服务器主机名

# 定义 phonebook menu.xml 中使用的 PHONEBOOK_ADDRESS。
: ${PHONEBOOK_ADDRESS:=""}
if [ -z "$PHONEBOOK_ADDRESS" ]; then
  [ "$HTTPD_HTTPS_ENABLED" = "true" ] && PHONEBOOK_PROTO=https || PHONEBOOK_PROTO=http

  if [ -z ${APP_FQDN} ]; then
      PHONEBOOK_ADDRESS="$PHONEBOOK_PROTO://$(hostname -I | awk '{print $1}')"
    else
      PHONEBOOK_ADDRESS="$PHONEBOOK_PROTO://${APP_FQDN}"
  fi
fi

# MySQL 配置
: ${MYSQL_SERVER:="db"}
: ${MYSQL_DATABASE:="asterisk"}
: ${MYSQL_DATABASE_CDR:="asteriskcdrdb"}
: ${MYSQL_USER:="asterisk"}
: ${MYSQL_PASSWORD:=""}
: ${MYSQL_ROOT_USER:="root"}
: ${MYSQL_ROOT_PASSWORD:=""}
: ${APP_PORT_MYSQL:="3306"}

# fop2（通过查询 FreePBX 设置自动获取）
#: ${FOP2_AMI_HOST:="localhost"}
#: ${FOP2_AMI_PORT:="5038"}
#: ${FOP2_AMI_USERNAME:="admin"}
#: ${FOP2_AMI_PASSWORD:="amp111"}
: ${FOP2_AUTOUPGRADE:="false"}

# Apache httpd 配置
: ${HTTPD_HTTPS_ENABLED:="false"}
: ${HTTPD_REDIRECT_HTTP_TO_HTTPS:="false"}
: ${HTTPD_ALLOW_FROM:=""}

: ${HTTPD_HTTPS_CERT_FILE:="${fpbxDirs[CERTKEYLOC]}/default.crt"}
: ${HTTPD_HTTPS_KEY_FILE:="${fpbxDirs[CERTKEYLOC]}/default.key"}
#: ${HTTPD_HTTPS_CHAIN_FILE:="${fpbxDirs[CERTKEYLOC]}/default.chain.crt"}

# phpMyAdmin 配置
: ${PMA_CONFIG:="/etc/phpMyAdmin/config.inc.php"}
: ${PMA_ALIAS:="/admin/pma"}
: ${PMA_ALLOW_FROM:="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"}

## Zabbix 配置
: ${ZABBIX_USR:="zabbix"}
: ${ZABBIX_GRP:="zabbix"}
: ${ZABBIX_SERVER:="127.0.0.1"}
: ${ZABBIX_SERVER_ACTIVE:="${ZABBIX_SERVER}"}
: ${ZABBIX_HOSTNAME:="$HOSTNAME"}
: ${ZABBIX_HOSTMETADATA:="izPBX"}

## 默认 supervisord 服务状态
#: ${SYSLOG_ENABLED:="true"}
#: ${POSTFIX_ENABLED:="true"}
: ${CRON_ENABLED:="true"}
: ${HTTPD_ENABLED:="true"}
: ${ASTERISK_ENABLED:="false"}
: ${IZPBX_ENABLED:="true"}
: ${FAIL2BAN_ENABLED:="true"}
: ${POSTFIX_ENABLED:="false"}
: ${DNSMASQ_ENABLED:="false"}
: ${DHCP_ENABLED:="false"}
: ${TFTP_ENABLED:="false"}
: ${NTP_ENABLED:="false"}
: ${ZABBIX_ENABLED:="false"}
: ${FOP2_ENABLED:="false"}
: ${PMA_ENABLED:="false"}
: ${PHONEBOOK_ENABLED:="true"}

## 守护进程配置
# 兼容旧配置：如果定义了 ROOT_MAILTO，则设置 SMTP_MAIL_TO=$ROOT_MAILTO
: ${SMTP_MAIL_TO:="$ROOT_MAILTO"}
## 默认 cron 邮件地址
: ${ROOT_MAILTO:="$SMTP_MAIL_TO"} # 默认 root 邮件地址

# postfix
: ${SMTP_RELAYHOST:=""}
: ${SMTP_RELAYHOST_USERNAME:=""}
: ${SMTP_RELAYHOST_PASSWORD:=""}
: ${SMTP_STARTTLS:="true"}
: ${SMTP_ALLOWED_SENDER_DOMAINS:=""}
: ${SMTP_MESSAGE_SIZE_LIMIT:="0"}
: ${SMTP_MAIL_FROM:="izpbx@localhost.localdomain"}
: ${SMTP_MAIL_TO:="root@localhost.localdomain"}
# smarthost 配置
: ${RELAYHOST:="$SMTP_RELAYHOST"}
: ${RELAYHOST_USERNAME:="$SMTP_RELAYHOST_USERNAME"}
: ${RELAYHOST_PASSWORD:="$SMTP_RELAYHOST_PASSWORD"}
: ${ALLOWED_SENDER_DOMAINS:="$SMTP_ALLOWED_SENDER_DOMAINS"}
: ${MESSAGE_SIZE_LIMIT:="$SMTP_MESSAGE_SIZE_LIMIT"}

# fail2ban
: ${FAIL2BAN_DEFAULT_SENDER:="$SMTP_MAIL_FROM"}
: ${FAIL2BAN_DEFAULT_DESTEMAIL:="$SMTP_MAIL_TO"}

# 操作系统特定变量
## 检测当前操作系统
: ${OS_RELEASE:="$(cat /etc/os-release | grep ^"ID=" | sed 's/"//g' | awk -F"=" '{print $2}')"}

# 操作系统特定路径
if   [ "$OS_RELEASE" = "debian" ]; then
# Debian 路径
: ${SUPERVISOR_DIR:="/etc/supervisor/conf.d/"}
: ${PMA_DIR:="/var/www/html/admin/pma"}
: ${PMA_CONF:="$PMA_DIR/config.inc.php"}
#: ${PMA_CONF:="/etc/phpmyadmin/config.inc.php"}
: ${PMA_CONF_APACHE:="/etc/phpmyadmin/apache.conf"}
: ${PHP_CONF:="/etc/php/7.3/apache2/php.ini"}
: ${NRPE_CONF:="/etc/nagios/nrpe.cfg"}
: ${NRPE_CONF_LOCAL:="/etc/nagios/nrpe_local.cfg"}
: ${ZABBIX_CONF:="/etc/zabbix/zabbix_agentd.conf"}
: ${ZABBIX_CONF_LOCAL:="/etc/zabbix/zabbix_agentd.conf.d/local.conf"}
elif [ "$OS_RELEASE" = "alpine" ]; then
# Alpine 路径
: ${SUPERVISOR_DIR:="/etc/supervisor.d"}
: ${PMA_CONF:="/etc/phpmyadmin/config.inc.php"}
: ${PMA_CONF_APACHE:="/etc/apache2/conf.d/phpmyadmin.conf"}
: ${PHP_CONF:="/etc/php/php.ini"}
: ${ZABBIX_CONF_LOCAL:="/etc/zabbix/zabPHONEBOOK_ADDRESSbix_agentd.conf.d/local.conf"}
else
# 回退到基于 RHEL 的发行版
: ${SUPERVISOR_DIR:="/etc/supervisord.d"}
: ${HTTPD_CONF_DIR:="/etc/httpd"} # Apache 配置目录
: ${PMA_CONF_APACHE:="/etc/httpd/conf.d/phpMyAdmin.conf"}
: ${ZABBIX_CONF:="/etc/zabbix/zabbix_agentd.conf"}
: ${ZABBIX_CONF_LOCAL:="/etc/zabbix/zabbix_agentd.d/local.conf"}
fi


## 杂项函数
check_version() { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

print_path() {
  echo ${@%/*}
}

print_fullname() {
  echo ${@##*/}
}

print_name() {
  print_fullname $(echo ${@%.*})
}

print_ext() {
  echo ${@##*.}
}

# 如果指定目录为空则返回 true
dirEmpty() {
    [ -z "$(ls -A "$1/")" ]
}

fixOwner() {
  usr=$1
  shift
  grp=$1
  shift
  file="$@"
  if [ -e "${file}" ]; then
      if [ "$(stat -c "%U %G" "${file}")" != "${usr} ${grp}" ];then
          echo "---> 正在修复所有者: '${file}'"
          chown ${usr}:${grp} "${file}"
      fi
    else
      echo "---> 警告: 文件或目录不存在: '${file}'"
  fi
}

fixPermission() {
  usr=$1
  shift
  grp=$1
  shift
  file="$@"
  if [ -e "${file}" ]; then
      if [ "$(stat -c "%a" "${file}")" != "770" ];then
          echo "---> 正在修复权限: '${file}'"
          chmod 0770 "${file}"
      fi
    else
      echo "---> 警告: 文件或目录不存在: '${file}'"
  fi
}

# 如果需要，将默认配置移动到自定义目录
symlinkDir() {
  local dirOriginal="$1"
  local dirCustom="$2"

  echo "--> 检测到目录数据覆盖: 原始:[$dirOriginal] 自定义:[$dirCustom]"

  # 如果目标目录为空，从原始目录复制数据文件
  if [ -e "$dirOriginal" ] && dirEmpty "$dirCustom"; then
    echo "--> 检测到空目录 '$dirCustom'，正在将 '$dirOriginal' 内容复制到 '$dirCustom'..."
    rsync -a -q "$dirOriginal/" "$dirCustom/"
  fi

  # 如果目录不存在则创建
  if [ ! -e "$dirOriginal" ]; then
      # 如果目标目录不存在则创建
      echo "--> 警告: 原始数据目录不存在... 正在创建空目录: '$dirOriginal'"
      mkdir -p "$dirOriginal"
  fi

  # 重命名目录
  if [ -e "$dirOriginal" ]; then
      echo -e "--> 正在将 '${dirOriginal}' 重命名为 '${dirOriginal}.dist'"
      mv "$dirOriginal" "$dirOriginal".dist
  fi

  # 符号链接目录
  echo "--> 正在将 '$dirCustom' 符号链接到 '$dirOriginal'"
  ln -s "$dirCustom" "$dirOriginal"
}

symlinkFile() {
  local fileOriginal="$1"
  local fileCustom="$2"

  echo "--> 检测到文件数据覆盖: 原始:[$fileOriginal] 自定义:[$fileCustom]"

  if [ -e "$fileOriginal" ]; then
      # 如果目标文件为空，从原始目录复制数据文件
      if [ ! -e "$fileCustom" ]; then
        echo "--> 信息: 检测到文件 '$fileCustom' 不存在。正在将 '$fileOriginal' 复制到 '$fileCustom'..."
        rsync -a -q "$fileOriginal" "$fileCustom"
      fi
      echo -e "--> 正在将 '${fileOriginal}' 重命名为 '${fileOriginal}.dist'... "
      mv "$fileOriginal" "$fileOriginal".dist
    else
      echo "--> 警告: 原始数据文件不存在... 正在从不存在的源创建符号链接: '$fileOriginal'"
      #touch "$fileOriginal"
  fi

  echo "--> 正在将 '$fileCustom' 符号链接到 '$fileOriginal'"
  # 如果父目录不存在则创建
  [ ! -e "$(dirname "$fileCustom")" ] && mkdir -p "$(dirname "$fileCustom")"
  ln -s "$fileCustom" "$fileOriginal"

}

# 启用/禁用和配置服务
chkService() {
  local SERVICE_VAR="$1"
  eval local SERVICE_ENABLED="\$$(echo $SERVICE_VAR)"
  eval local SERVICE_DAEMON="\$$(echo $SERVICE_VAR | sed 's/_.*//')_DAEMON"
  local SERVICE="$(echo $SERVICE_VAR | sed 's/_.*//' | sed -e 's/\(.*\)/\L\1/')"
  [ -z "$SERVICE_DAEMON" ] && local SERVICE_DAEMON="$SERVICE"
  if [ "$SERVICE_ENABLED" = "true" ]; then
    autostart=true
    echo "=> 正在启用 $SERVICE_DAEMON 服务... 因为 $SERVICE_VAR=$SERVICE_ENABLED"
    echo "--> 正在配置 $SERVICE_DAEMON 服务..."
    cfgService_$SERVICE
   else
    autostart=false
    echo "=> 正在禁用 $SERVICE_DAEMON 服务... 因为 $SERVICE_VAR=$SERVICE_ENABLED"
  fi
  sed "s/autostart=.*/autostart=$autostart/" -i ${SUPERVISOR_DIR}/$SERVICE_DAEMON.ini
}

## postfix 服务
cfgService_postfix() {
# 修复 inet_protocols IPv6 问题
postconf -e inet_protocols=ipv4

# 设置主机名
if [ ! -z "$HOSTNAME" ]; then
	postconf -e myhostname="$HOSTNAME"
else
	postconf -# myhostname
fi

# 如果需要，设置中继主机
if [ ! -z "$RELAYHOST" ]; then
	echo -n "- 正在将所有邮件转发到 $RELAYHOST"
	postconf -e relayhost=$RELAYHOST

	if [ -n "$RELAYHOST_USERNAME" ] && [ -n "$RELAYHOST_PASSWORD" ]; then
		echo " 使用用户名 $RELAYHOST_USERNAME。"
		echo "$RELAYHOST $RELAYHOST_USERNAME:$RELAYHOST_PASSWORD" >> /etc/postfix/sasl_passwd
		postmap hash:/etc/postfix/sasl_passwd
		postconf -e "smtp_sasl_auth_enable=yes"
		postconf -e "smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd"
		postconf -e "smtp_sasl_security_options=noanonymous"
	else
		echo " 不带任何身份验证。请确保您的服务器已配置为接受来自此 IP 的邮件。"
	fi
else
	echo "---> postfix 将尝试直接将邮件投递到目标服务器。请确保您的 DNS 已正确设置！"
	postconf -# relayhost
	postconf -# smtp_sasl_auth_enable
	postconf -# smtp_sasl_password_maps
	postconf -# smtp_sasl_security_options
fi

# 设置我的网络，仅列出本地回环范围内的网络
#network_table=/etc/postfix/network_table
#touch $network_table
#echo "127.0.0.0/8    any_value" >  $network_table
#echo "10.0.0.0/8     any_value" >> $network_table
#echo "172.16.0.0/12  any_value" >> $network_table
#echo "192.168.0.0/16 any_value" >> $network_table
## 暂时忽略 IPv6
##echo "fd00::/8" >> $network_table
#postmap $network_table
#postconf -e mynetworks=hash:$network_table

if [ ! -z "$SMTP_MYNETWORKS" ]; then
  echo "---> 正在启用 mynetworks: $SMTP_MYNETWORKS"
  postconf -e mynetworks=$SMTP_MYNETWORKS
else
  postconf -e "mynetworks=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
fi

if [ "$SMTP_STARTTLS" = "true" ]; then
  echo "---> 正在作为 SMTP 客户端启用 TLS 支持"
  postconf -e smtp_use_tls=yes
fi

# 按空格分割
if [ ! -z "$ALLOWED_SENDER_DOMAINS" ]; then
	echo -n "---> 正在设置允许的发件人域名: $ALLOWED_SENDER_DOMAINS"
	allowed_senders=/etc/postfix/allowed_senders
	rm -f $allowed_senders $allowed_senders.db > /dev/null
	touch $allowed_senders
	for i in $ALLOWED_SENDER_DOMAINS; do
		echo -n " $i"
		echo -e "$i\tOK" >> $allowed_senders
	done
	echo
	postmap $allowed_senders

	postconf -e "smtpd_restriction_classes=allowed_domains_only"
	postconf -e "allowed_domains_only=permit_mynetworks, reject_non_fqdn_sender reject"
	postconf -e "smtpd_recipient_restrictions=reject_non_fqdn_recipient, reject_unknown_recipient_domain, reject_unverified_recipient, check_sender_access hash:$allowed_senders, reject"
else
	postconf -# "smtpd_restriction_classes"
	postconf -e "smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,reject_unverified_recipient"
fi

# 使用 587 端口（提交）
echo "---> 正在启用 587 端口的提交协议"
sed -i -r -e 's/^#submission/submission/' /etc/postfix/master.cf

# 配置 /etc/aliases
[ ! -f /etc/aliases ] && echo "postmaster: root" > /etc/aliases

if   ! grep ^"root:" /etc/aliases 2>&1 >/dev/null; then
  echo "root: ${SMTP_MAIL_TO}" >> /etc/aliases
  newaliases
elif ! grep ^"root:.*${SMTP_MAIL_TO}" /etc/aliases 2>&1 >/dev/null; then
  echo sed "s/^root:.*/root: ${SMTP_MAIL_TO}/" -i /etc/aliases
  newaliases
fi

# 启用日志输出到 stdout
postconf -e "maillog_file = /dev/stdout"

# 修复 send-mail 问题: fatal: parameter inet_interfaces: no local interface found for ::1
postconf -e "inet_protocols = ipv4"

# 设置最大邮件大小限制
postconf -e "mailbox_size_limit = 0"
postconf -e "message_size_limit = ${MESSAGE_SIZE_LIMIT}"

# 设置发件人邮箱地址
if [ ! -z "$SMTP_MAIL_FROM" ]; then
  echo "/.+/ $SMTP_MAIL_FROM" > /etc/postfix/sender_canonical_maps
  echo "/From:.*/ REPLACE From: $SMTP_MAIL_FROM" > /etc/postfix/header_checks
  postconf -e "sender_canonical_maps = regexp:/etc/postfix/sender_canonical_maps"
  postconf -e "smtp_header_checks = regexp:/etc/postfix/header_checks"
fi
}

## cron 服务
cfgService_cron() {
  if   [ "$OS_RELEASE" = "debian" ]; then
    cronDir="/var/spool/cron/ing supervisord config fbs"
  else
    cronDir="/var/spool/cron"
  fi

  if [ -e "$cronDir" ]; then
    if [ "$(stat -c "%U %G %a" "$cronDir")" != "root root 0700" ];then
      echo "---> 正在修复权限: '$cronDir'"
      chown root:root "$cronDir"
      chmod u=rwx,g=wx,o=t "$cronDir"
    fi
  fi
}

## 根据 SECTION 和 KEY=VALUE 解析和编辑 ini 配置文件

# 输入流格式: SECTION KEY=VALUE
#   echo RECIDIVE ENABLED=false | iniParser /etc/fail2ban/jail.d/99-local.conf

# FIXME: 目前匹配所有文件节
# 使用全局环境变量并在发送到 iniParser 之前进行解析的多值示例:
#  set FAIL2BAN_DEFAULT_FINDTIME=3600
#  set FAIL2BAN_DEFAULT_MAXRETRY=10
#  set FAIL2BAN_RECIDIVE_ENABLED=false
#  set FAIL2BAN_RECIDIVE_BANTIME=1814400
#  set | grep ^"FAIL2BAN_" | sed -e 's/^FAIL2BAN_//' | sed -e 's/_/ /' | iniParser /etc/fail2ban/jail.d/99-local.conf
iniParser() {
  ini="$@"
  while read setting ; do
    section="$(echo $setting | cut -d" " -f1)"
    k=$(echo $setting | sed -e "s/^${section} //" | cut -d"=" -f-1 | tr '[:upper:]' '[:lower:]')
    v=$(echo $setting | sed -e "s/'//g" | cut -d"=" -f2-)
    sed -e "/^\[${section}\]$/I,/^\(\|;\|#\)\[/ s/^\(;\|#\)${k}/${k}/" -e "/^\[${section}\]$/I,/^\[/ s|^${k}.*=.*|${k}=${v}|I" -i "${ini}"
  done
}

## fail2ban 服务
cfgService_fail2ban() {
  echo "--> 正在重新配置 Fail2ban 设置..."
  # ini 配置文件解析函数
  # 修复默认日志路径
  echo "DEFAULT LOGTARGET=/var/log/fail2ban/fail2ban.log" | iniParser "/etc/fail2ban/fail2ban.conf"
  touch /var/log/fail2ban/fail2ban.log
  # 配置所有设置
  set | grep ^"FAIL2BAN_" | sed -e 's/^FAIL2BAN_//' | sed -e 's/_/ /' | iniParser "/etc/fail2ban/jail.d/99-local.conf"
}

## Apache 服务
cfgService_httpd() {

  # 本地函数
  print_ApacheAllowFrom() {
    if [ ! -z "${HTTPD_ALLOW_FROM}" ]; then
        for IP in $(echo ${HTTPD_ALLOW_FROM} | sed -e "s/'//g") ; do
          echo "    Require ip ${IP}"
        done
    else
        echo "    Require all granted"
    fi
  }

echo "--> 正在设置 Apache ServerName 为 ${SERVERNAME}"
sed "s/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/" -i "${HTTPD_CONF_DIR}/conf.modules.d/00-mpm.conf"
sed "s/LoadModule mpm_event_module/#LoadModule mpm_event_module/"     -i "${HTTPD_CONF_DIR}/conf.modules.d/00-mpm.conf"
sed "s/^#ServerName.*/ServerName ${SERVERNAME}/" -i "${HTTPD_CONF_DIR}/conf/httpd.conf"
sed "s/^User .*/User ${APP_USR}/"               -i "${HTTPD_CONF_DIR}/conf/httpd.conf"
sed "s/^Group .*/Group ${APP_GRP}/"             -i "${HTTPD_CONF_DIR}/conf/httpd.conf"
sed "s/^Listen .*/Listen ${APP_PORT_HTTP}/"       -i "${HTTPD_CONF_DIR}/conf/httpd.conf"

# 禁用默认 ssl.conf 并使用 virtual.conf
[ -e "${HTTPD_CONF_DIR}/conf.d/ssl.conf" ] && mv "${HTTPD_CONF_DIR}/conf.d/ssl.conf" "${HTTPD_CONF_DIR}/conf.d/ssl.conf-dist"

echo "--> 正在配置 Apache 虚拟主机并创建空的 ${HTTPD_CONF_DIR}/conf.d/virtual.conf 文件"
echo "" > "${HTTPD_CONF_DIR}/conf.d/virtual.conf"

echo "# 默认虚拟主机

<VirtualHost *:${APP_PORT_HTTP}>
  DocumentRoot /var/www/html" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"

if [ "${HTTPD_REDIRECT_HTTP_TO_HTTPS}" = "true" ]; then
echo "--> 正在为默认虚拟主机设置从 HTTP 到 HTTPS 的自动重定向"
echo "  <IfModule mod_rewrite.c>
    RewriteEngine on
    RewriteCond %{REQUEST_URI} !\.well-known/acme-challenge
    RewriteCond %{REQUEST_URI} !\.freepbx-known
    RewriteCond %{HTTPS} off
    #RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
    RewriteRule .? https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
  </IfModule>" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"
fi

echo "
  <Directory /var/www/html>
    Options Includes FollowSymLinks
    AllowOverride All
$(print_ApacheAllowFrom)
  </Directory>
</VirtualHost>
" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"

if [ ! -z "${APP_FQDN}" ]; then
  echo "--> 正在设置 Apache 虚拟主机为: ${APP_FQDN}，端口 ${APP_PORT_HTTP}"
  echo "# ${APP_FQDN} 虚拟主机
  <VirtualHost *:${APP_PORT_HTTP}>
    ServerName ${APP_FQDN}" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"

  if [ "${HTTPD_REDIRECT_HTTP_TO_HTTPS}" = "true" ]; then
  echo "--> 正在为 ${APP_FQDN} 虚拟主机设置从 HTTP 到 HTTPS 的自动重定向"
  echo "# 启用 HTTP 到 HTTPS 的自动重写
<IfModule mod_rewrite.c>
  RewriteEngine on
  RewriteCond %{REQUEST_URI} !\.well-known/acme-challenge
  RewriteCond %{REQUEST_URI} !\.freepbx-known
  RewriteCond %{HTTPS} off
  #RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
  RewriteRule .? https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</IfModule>
" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"
  fi

  # 关闭虚拟主机指令
  echo "<Directory /var/www/html>
    Options Includes FollowSymLinks
    AllowOverride All
$(print_ApacheAllowFrom)
  </Directory>
</VirtualHost>
" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"
fi

if [ "${HTTPD_HTTPS_ENABLED}" = "true" ]; then
  echo "--> 正在启用 Apache SSL 引擎"

  ## 如果需要，重新创建自签名证书
  # 检测指定证书的 CN
  [ -e "${HTTPD_HTTPS_CERT_FILE}" ] && local CERT_CN=$(openssl x509 -noout -subject -in ${HTTPD_HTTPS_CERT_FILE} | sed 's/.*CN = //;s/, .*//')

  # 定义证书主题
  [ -z "$APP_FQDN" ] && local CERT_SUBJ="/CN=izpbx" || CERT_SUBJ="/CN=$APP_FQDN"

  if [[ ! -e "${HTTPD_HTTPS_CERT_FILE}" && ! -e "${HTTPD_HTTPS_KEY_FILE}" ]]; then
    echo "---> 警告: SSL 证书文件 (HTTPD_HTTPS_CERT_FILE=${HTTPD_HTTPS_CERT_FILE} HTTPD_HTTPS_KEY_FILE=${HTTPD_HTTPS_KEY_FILE}) 不存在"
    echo "----> 正在生成新的自签名证书（有效期 10 年）以避免 Web 服务器崩溃"
    # 如果目录不存在则创建
    [ ! -e "$(dirname "${HTTPD_HTTPS_CERT_FILE}")" ] && mkdir "$(dirname "${HTTPD_HTTPS_CERT_FILE}")"
    [ ! -e "$(dirname "${HTTPD_HTTPS_KEY_FILE}")" ]  && mkdir "$(dirname "${HTTPD_HTTPS_KEY_FILE}")"
    openssl req -subj "$CERT_SUBJ" -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -keyout "${HTTPD_HTTPS_KEY_FILE}" -out "${HTTPD_HTTPS_CERT_FILE}"
  elif [[ ! -z "$APP_FQDN" && "$CERT_CN" = "izpbx" ]]; then
    echo "---> 警告: 当前 SSL 证书 CN '$CERT_CN' (${HTTPD_HTTPS_CERT_FILE}) 与配置的 APP_FQDN '$APP_FQDN' 变量不匹配"
    echo "----> 正在生成新的自签名证书（有效期 10 年）"
    openssl req -subj "$CERT_SUBJ" -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -keyout "${HTTPD_HTTPS_KEY_FILE}" -out "${HTTPD_HTTPS_CERT_FILE}"
  elif [[ ! -z "$APP_FQDN" && "$APP_FQDN" != "$CERT_CN" ]]; then
    echo "---> 警告: 当前 SSL 证书 CN '$CERT_CN' (${HTTPD_HTTPS_CERT_FILE}) 与配置的 APP_FQDN '$APP_FQDN' 变量不匹配"
    echo "----> 注意: 请替换错误的证书来修复此问题"
  fi

  echo "
# 启用 HTTPS 监听
Listen ${APP_PORT_HTTPS} https
SSLPassPhraseDialog    exec:/usr/libexec/httpd-ssl-pass-dialog
SSLSessionCache        shmcb:/run/httpd/sslcache(512000)
SSLSessionCacheTimeout 300
SSLCryptoDevice        builtin
" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"

  if [[ -z "${APP_FQDN}" && "${LETSENCRYPT_ENABLED}" = "true" ]]; then
    echo "--> 警告: LETSENCRYPT_ENABLED=${LETSENCRYPT_ENABLED} 但未定义 APP_FQDN，请将 APP_FQDN 设置为有效的互联网 FQDN 域名后重试... 改为启用自签名证书"
  fi

  if [[ ! -z "${APP_FQDN}" && "${LETSENCRYPT_ENABLED}" = "true" ]]; then
    echo "# 使用 Let's Encrypt 证书启用 SSL 虚拟主机
<VirtualHost *:${APP_PORT_HTTPS}>
  ServerName ${APP_FQDN}

  ErrorLog                 logs/ssl_error_log
  TransferLog              logs/ssl_access_log
  LogLevel                 warn

  SSLEngine               on
  SSLHonorCipherOrder     on
  SSLCipherSuite          PROFILE=SYSTEM
  SSLProxyCipherSuite     PROFILE=SYSTEM
  SSLCertificateFile      ${fpbxDirs[CERTKEYLOC]}/integration/webserver.crt
  SSLCertificateKeyFile   ${fpbxDirs[CERTKEYLOC]}/integration/webserver.key
  SSLCertificateChainFile ${fpbxDirs[CERTKEYLOC]}/integration/certificate.pem
  
  <Directory /var/www/html>
    Options Includes FollowSymLinks
    AllowOverride All
$(print_ApacheAllowFrom)
  </Directory>
</VirtualHost>
" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"
  else
    echo "# 启用默认 SSL 虚拟主机（使用自签名证书）
<VirtualHost _default_:${APP_PORT_HTTPS}>
  ErrorLog                 logs/ssl_error_log
  TransferLog              logs/ssl_access_log
  LogLevel                 warn
  
  SSLEngine                on
  SSLHonorCipherOrder      on
  SSLCipherSuite           PROFILE=SYSTEM
  SSLProxyCipherSuite      PROFILE=SYSTEM
  SSLCertificateFile       ${HTTPD_HTTPS_CERT_FILE}
  SSLCertificateKeyFile    ${HTTPD_HTTPS_KEY_FILE}
  $([ ! -z "${HTTPD_HTTPS_CHAIN_FILE}" ] && echo "SSLCertificateChainFile  ${HTTPD_HTTPS_CHAIN_FILE}")

  <Directory /var/www/html>
    Options Includes FollowSymLinks
    AllowOverride All
$(print_ApacheAllowFrom)
  </Directory>
</VirtualHost>
" >> "${HTTPD_CONF_DIR}/conf.d/virtual.conf"
  fi
fi
}

cfgService_asterisk() {
  echo "=> 正在启动 Asterisk"
}

## freepbx+asterisk service
cfgService_izpbx() {

  freepbxReload() {
    echo "---> 正在重新加载 FreePBX..."
    su - ${APP_USR} -s /bin/bash -c "fwconsole reload"
  }

  freepbxChown() {
    echo "---> 正在设置 FreePBX 权限..."
    fwconsole chown
  }

  freepbxSettingsFix() {
    # 重新加载 freepbx 配置
    echo "---> FIXME: 对 FreePBX 损坏的模块和配置应用临时解决方案..."

    # 创建缺失的日志文件
    [ ! -e "${fpbxDirs[ASTLOGDIR]}/full" ] && touch "${fpbxDirs[ASTLOGDIR]}/full" && chown ${APP_USR}:${APP_GRP} "${file}" "${fpbxDirs[ASTLOGDIR]}/full"

    # 修正路径，并在不存在时重新链接 fwconsole 和 amportal
    [ ! -e "/usr/sbin/fwconsole" ] && ln -s ${fpbxDirs[AMPBIN]}/fwconsole /usr/sbin/fwconsole
    [ ! -e "/usr/sbin/amportal" ]  && ln -s ${fpbxDirs[AMPBIN]}/amportal  /usr/sbin/amportal

    # 重置 FreePBX 配置文件权限
    for file in ${appFilesConf[@]}; do
      chown ${APP_USR}:${APP_GRP} "${file}"
    done

    # 修正 freepbx 目录路径
    if [ ! -z "${APP_DATA}" ]; then
      echo "----> 正在修正数据库配置中的系统目录路径..."
      for k in ${!fpbxDirs[@]}; do
        [ "$(fwconsole setting ${k} | awk -F"[][{}]" '{print $2}')" != "${fpbxDirs[$k]}" ] && fwconsole setting ${k} ${fpbxDirs[$k]}
      done
      for k in ${!fpbxFilesLog[@]}; do
        [ "$(fwconsole setting ${k} | awk -F"[][{}]" '{print $2}')" != "${fpbxFilesLog[$k]}" ] && fwconsole setting ${k} ${fpbxFilesLog[$k]}
      done
    fi
    
    # 修正缺失的文档目录，防止加载额外编解码器（如 codec_opus）时出现问题
    if [ ! -z "${APP_DATA}" ]; then
      if [ "$(ls -1 "${appDataDirs[ASTVARLIBDIR]}.dist/documentation/thirdparty/")" != "$(ls -1 "${APP_DATA}${appDataDirs[ASTVARLIBDIR]}/documentation/thirdparty/")" ]; then
        echo "----> 正在修正 asterisk 文档目录... ${APP_DATA}${appDataDirs[ASTVARLIBDIR]}/documentation/thirdparty"
        rsync -a -P "${appDataDirs[ASTVARLIBDIR]}.dist/documentation/thirdparty/" "${APP_DATA}${appDataDirs[ASTVARLIBDIR]}/documentation/thirdparty/"
      fi
    fi
    
    # FIXME @20200318 freepbx 15.x 警告的临时解决方案
    sed 's/^preload = chan_local.so/;preload = chan_local.so/' -i ${fpbxDirs[ASTETCDIR]}/modules.conf
    sed 's/^enabled =.*/enabled = yes/' -i ${fpbxDirs[ASTETCDIR]}/hep.conf

    # FIXME @20200322 https://issues.freepbx.org/browse/FREEPBX-21317（不再需要）
    #[ $(fwconsole ma list | grep backup | awk '{print $4}' | sed 's/\.//g') -lt 150893 ] && su - ${APP_USR} -s /bin/bash -c "fwconsole ma downloadinstall backup --edge"

    # FIXME @20210321 FreePBX 不会将非默认的 'asteriskcdrdb' 数据库配置到 DB 中
    [ "$(fwconsole setting CDRDBNAME | awk -F"[][{}]" '{print $2}')" != "${MYSQL_DATABASE_CDR}" ] && fwconsole setting CDRDBNAME ${MYSQL_DATABASE_CDR}

    ## 修正 Asterisk/FreePBX 文件权限
    freepbxChown
  }
  
  echo "---> 正在验证 FreePBX 配置"

  # freepbx 安装脚本参数说明:
  #    --webroot=WEBROOT            Filesystem location from which FreePBX files will be served [default: "/var/www/html"]
  #    --astetcdir=ASTETCDIR        Filesystem location from which Asterisk configuration files will be served [default: "/etc/asterisk"]
  #    --astmoddir=ASTMODDIR        Filesystem location for Asterisk modules [default: "/usr/lib64/asterisk/modules"]
  #    --astvarlibdir=ASTVARLIBDIR  Filesystem location for Asterisk lib files [default: "/var/lib/asterisk"]
  #    --astagidir=ASTAGIDIR        Filesystem location for Asterisk agi files [default: "/var/lib/asterisk/agi-bin"]
  #    --astspooldir=ASTSPOOLDIR    Location of the Asterisk spool directory [default: "/var/spool/asterisk"]
  #    --astrundir=ASTRUNDIR        Location of the Asterisk run directory [default: "/var/run/asterisk"]
  #    --astlogdir=ASTLOGDIR        Location of the Asterisk log files [default: "/var/log/asterisk"]
  #    --ampbin=AMPBIN              Location of the FreePBX command line scripts [default: "/var/lib/asterisk/bin"]
  #    --ampsbin=AMPSBIN            Location of the FreePBX (root) command line scripts [default: "/usr/sbin"]
  #    --ampcgibin=AMPCGIBIN        Location of the Apache cgi-bin executables [default: "/var/www/cgi-bin"]
  #    --ampplayback=AMPPLAYBACK    Directory for FreePBX html5 playback files [default: "/var/lib/asterisk/playback"]

  # 将关联数组转换为 variable=paths，例如 AMPWEBROOT=/var/www/html（不再需要）
  #for k in ${!fpbxDirs[@]}      ; do eval $k=${fpbxDirs[$k]}      ;done
  #for k in ${!fpbxDirsExtra[@]} ; do eval $k=${fpbxDirsExtra[$k]} ;done
  #for k in ${!fpbxFilesLog[@]}  ; do eval $k=${fpbxFilesLog[$k]}  ;done    

  ## 启用持久化并基于 APP_DATA 重定向目录路径，创建/修改缺失目录的属主
  # 处理目录
  if [ ! -z "${APP_DATA}" ]; then
    echo "---> 使用 '${APP_DATA}' 作为 FreePBX 安装的基础目录"
    # 处理目录
    for k in ${!fpbxDirs[@]}; do
      v="${fpbxDirs[$k]}"
      eval fpbxDirs[$k]=${APP_DATA}$v
      [ ! -e "$v" ] && mkdir -p "$v"
      if [ "$(stat -c "%U %G" "$v" 2>/dev/null)" != "${APP_USR} ${APP_GRP}" ];then
      echo "---> 正在修正权限: $k=$v"
      chown ${APP_USR}:${APP_GRP} "$v"
      fi
    done
    
    # 处理日志文件
    for k in ${!fpbxFilesLog[@]}; do
      v="${fpbxFilesLog[$k]}"
      eval fpbxFilesLog[$k]=${APP_DATA}$v
      [ ! -e "$v" ] && touch "$v"
      if [ "$(stat -c "%U %G" "$v" 2>/dev/null)" != "${APP_USR} ${APP_GRP}" ];then
      echo "---> 正在修正权限: $k=$v"
      chown ${APP_USR}:${APP_GRP} "$v"
      fi
    done
  fi

  # 配置 CDR ODBC
  echo "--> 正在配置 FreePBX ODBC"
  # 修正 mysql odbc inst 文件路径
  sed -i 's/\/lib64\/libmyodbc5.so/\/lib64\/libmaodbc.so/' /etc/odbcinst.ini
  # 创建 mysql odbc
  echo "[MySQL-asteriskcdrdb]
Description = MariaDB connection to '${MYSQL_DATABASE_CDR}' CDR database
driver = MySQL
server = ${MYSQL_SERVER}
database = ${MYSQL_DATABASE_CDR}
Port = ${APP_PORT_MYSQL}
option = 3
Charset=utf8" > /etc/odbc.ini

  # 遗留兼容：处理 ${APP_DATA}/.initialized 文件缺失但 izpbx 已部署的情况
  if [[ -e "${appFilesConf[FPBXCFGFILE]}" && ! -e ${APP_DATA}/.initialized ]]; then
    echo "--> 信息: 找到 '${appFilesConf[FPBXCFGFILE]}' 配置文件但缺少 '${APP_DATA}/.initialized'... 正在创建"
    echo "--> 注意: 如需从头部署 izPBX，请删除 '${appFilesConf[FPBXCFGFILE]}' 和 '${APP_DATA}/.initialized' 文件"
    touch "${APP_DATA}/.initialized"
  fi
  
  # 如果尚未部署则初始化 izpbx
  if [ ! -e ${APP_DATA}/.initialized ]; then
      # 首次运行，初始化 izpbx
      cfgService_freepbx_install
      # 保存当前已安装的 freepbx 版本
      FREEPBX_VER_INSTALLED="$(${fpbxDirs[AMPBIN]}/fwconsole -V | awk '{print $NF}' | awk -F'.' '{print $1}')"
    else
      # 保存当前已安装的 freepbx 版本
      FREEPBX_VER_INSTALLED="$(${fpbxDirs[AMPBIN]}/fwconsole -V | awk '{print $NF}' | awk -F'.' '{print $1}')"

      # 'fwconsole -V' 并非总是可靠，直接从数据库读取当前安装版本
      if [ -z "${FREEPBX_VER_INSTALLED##*[!0-9]*}" ]; then
        FREEPBX_VER_INSTALLED="$(mysql -h ${MYSQL_SERVER} -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} ${MYSQL_DATABASE} --batch --skip-column-names --raw --execute="SELECT value FROM admin WHERE variable = 'version';" | awk '{print $NF}' | awk -F'.' '{print $1}')"
      fi

      # 如果为空则将版本保存到 .initialized 文件
      #[ -z "$(cat "${APP_DATA}/.initialized")" ] && ${fpbxDirs[AMPBIN]}/fwconsole -V > "${APP_DATA}/.initialized"

      echo "--> 信息: 找到 '${APP_DATA}/.initialized' 文件 - 检测到 FreePBX 版本: $FREEPBX_VER_INSTALLED"
      [ ! -e "${appFilesConf[FPBXCFGFILE]}" ] && echo "---> 警告: 缺少配置文件: ${appFilesConf[FPBXCFGFILE]}"

      # izpbx 已初始化，更新配置文件
      echo "---> 正在重新配置 '${appFilesConf[FPBXCFGFILE]}'..."
      [[ ! -z "${APP_PORT_MYSQL}" && ${APP_PORT_MYSQL} -ne 3306 ]] && export MYSQL_SERVER="${MYSQL_SERVER}:${APP_PORT_MYSQL}"
      sed "s/^\$amp_conf\['AMPDBHOST'\] =.*/\$amp_conf\['AMPDBHOST'\] = '${MYSQL_SERVER}';/"   -i "${appFilesConf[FPBXCFGFILE]}"
      sed "s/^\$amp_conf\['AMPDBNAME'\] =.*/\$amp_conf\['AMPDBNAME'\] = '${MYSQL_DATABASE}';/" -i "${appFilesConf[FPBXCFGFILE]}"
      sed "s/^\$amp_conf\['AMPDBUSER'\] =.*/\$amp_conf\['AMPDBUSER'\] = '${MYSQL_USER}';/"     -i "${appFilesConf[FPBXCFGFILE]}"
      sed "s/^\$amp_conf\['AMPDBPASS'\] =.*/\$amp_conf\['AMPDBPASS'\] = '${MYSQL_PASSWORD}';/" -i "${appFilesConf[FPBXCFGFILE]}"
  fi

  # 对 FreePBX bug 应用临时修复和解决方案
  freepbxSettingsFix

  # 从环境变量重新配置 freepbx
  echo "---> 正在根据需要重新配置 FreePBX 高级设置..."
  set | grep ^"FREEPBX_" | grep -v -e ^"FREEPBX_MODULES_" -e ^"FREEPBX_AUTOUPGRADE_" -e ^"FREEPBX_VER" | sed -e 's/^FREEPBX_//' -e 's/=/ /' | while read setting ; do
    k="$(echo $setting | awk '{print $1}')"
    v="$(echo $setting | awk '{print $2}')"
    currentVal=$(fwconsole setting $k | awk -F"[][{}]" '{print $2}')
    [ "$currentVal" = "true" ] && currentVal="1"
    [ "$currentVal" = "false" ] && currentVal="0"
    if [ "$currentVal" != "$v" ]; then
      echo "---> 正在重新配置高级设置: ${k}=${v}"
      fwconsole setting $k $v
    fi
  done

  # 使用 FreePBX API bootstrap 基于 docker 变量内容重新配置 freepbx 设置
  echo "---> 正在根据需要重新配置 FreePBX SIP 设置..."
  for k in ${!fpbxSipSettings[@]}; do
    v="${fpbxSipSettings[$k]}"
    cVal=$(echo "<?php include '/etc/freepbx.conf'; \$FreePBX = FreePBX::Create(); echo \$FreePBX->sipsettings->getConfig('${k}');?>" | php)
    if [ "$cVal" != "${v}" ];then
      echo "---> 正在重新配置 SIP 设置: ${k}=${v}"
      echo "<?php include '/etc/freepbx.conf'; \$FreePBX = FreePBX::Create(); \$FreePBX->sipsettings->setConfig('${k}',${v}); needreload();?>" | php
    fi
  done

  # FIXME: 20200315 iaxsettings 目前无法正常工作
  #echo "---> 正在根据需要重新配置 FreePBX IAX2 设置..."
  #for k in ${!freepbxIaxSettings[@]}; do
  #  v="${freepbxIaxSettings[$k]}"
  #  echo "<?php include '/etc/freepbx.conf'; \$FreePBX = FreePBX::Create(); \$FreePBX->iaxsettings->setConfig('${k}',${v}); needreload();?>" | php
  #done

  # 检查是否需要升级 FreePBX 主版本
  cfgService_freepbx_upgrade_check
}

cfgService_freepbx_upgrade_check() {
  #set -x
  if [ -e "${APP_DATA}/.initialized" ]; then
    if [ $FREEPBX_VER_INSTALLED -lt $FREEPBX_VER ];then
      echo
      echo "=========================================================================================="
      echo "==> !!! 检测到可升级的 FreePBX 安装 !!!"
      echo "=========================================================================================="
      echo "==> 已安装 FreePBX 版本: ${FREEPBX_VER_INSTALLED}"
      echo "==> 可用 FreePBX 版本: ${FREEPBX_VER}"
      echo "=========================================================================================="
      if [ "$FREEPBX_AUTOUPGRADE_CORE" = "true" ]; then
        echo "==> 信息: FreePBX 自动升级已启用"
        echo "==> 注意: 升级前请确保已备份您的安装"
        let UPGRADABLE=${FREEPBX_VER}-${FREEPBX_VER_INSTALLED}
        if [ $UPGRADABLE = 1 ]; then
            cfgService_freepbx_upgrade
          else
            echo
            echo "==> 警告: 无法直接从 ${FREEPBX_VER_INSTALLED} 升级到 ${FREEPBX_VER} 版本"
            echo "==>          您必须先升级到前一个主版本，然后再升级到 ${FREEPBX_VER} 版本"
            echo
        fi
        else
          echo "==> 信息: FreePBX 自动升级已禁用"
          echo
      fi
    fi
  fi
}

cfgService_freepbx_upgrade() {
  echo "=========================================================================================="
  echo "==> 开始升级 FreePBX 从 '${FREEPBX_VER_INSTALLED}' 到 '${FREEPBX_VER}'"
  # FIXME: @20211128 临时方案
  [ -e "/tmp/cron.error" ] && rm -f /tmp/cron.error

  # FIXME: @20211130 检查未来版本是否仍需此操作
  echo "--> 步骤:[1] FIXME: 正在为问题 FREEPBX-21703 打补丁 'Encoding.php'"
  patch "${fpbxDirs[AMPWEBROOT]}/admin/libraries/Composer/vendor/neitanod/forceutf8/src/ForceUTF8/Encoding.php" "/usr/src/php74.patch"
  echo "--> 步骤:[2] 正在启动 freepbx 服务"
  fwconsole start
  echo "--> 步骤:[3] 正在升级所有模块"
  fwconsole ma upgradeall
  echo "--> 步骤:[4] 正在安装 versionupgrade 模块"
  fwconsole ma downloadinstall versionupgrade
  fwconsole chown
  fwconsole reload
  echo "--> 步骤:[5] 正在从 FreePBX $FREEPBX_VER_INSTALLED 升级到 $FREEPBX_VER"
  #fwconsole versionupgrade --check
  fwconsole versionupgrade --upgrade
  if [ $? != 0 ]; then
    # FIXME: @20211130 检查未来版本是否仍需此操作
    echo "--> 步骤:[5-b] FIXME: 正在为问题 FREEPBX-22983 应用临时解决方案"
    # 参考: https://community.freepbx.org/t/2021-09-17-security-fixes-release-update/78054
    fwconsole ma downloadinstall framework --tag=16.0.10.42
    echo "--> 步骤:[5-c] 正在再次升级所有模块"
    fwconsole ma upgradeall
  fi
  echo "--> 步骤:[6] 正在完成升级"
  fwconsole chown
  fwconsole reload
  fwconsole stop
  echo "==> 升级完成: FreePBX 从 '${FREEPBX_VER_INSTALLED}' 到 '${FREEPBX_VER}'"
  echo "=========================================================================================="
  echo
}

# 如果 FreePBX 未安装则安装
cfgService_freepbx_install() {

  mysqlQuery() {
    mysql -h ${MYSQL_SERVER} -P ${APP_PORT_MYSQL} -u ${MYSQL_ROOT_USER} --password=${MYSQL_ROOT_PASSWORD} -N -B -e "$@"
  }
  
  checkMysql() {
    mysqlQuery "SELECT 1;" >/dev/null
  }
  
  # 全局尝试计数器
  n=1 ; t=5
  
  until [ $n -eq $t ]; do
  cd /usr/src/freepbx
  echo
  echo "====================================================================="
  echo "=> !!! 检测到全新安装 :: FreePBX 尚未初始化 !!! <="
  echo "====================================================================="
  echo "--> 缺少 '${APP_DATA}/.initialized' 文件... 正在初始化 FreePBX... 尝试:[$n/$t]"

  # 如果未定义 MYSQL_ROOT_PASSWORD 则使用 mysql 用户，并跳过初始 MySQL 部署
  if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
    echo "--> 注意: 未定义 root 用户密码，跳过 MySQL 初始化"
    MYSQL_ROOT_USER="${MYSQL_USER}"
    MYSQL_ROOT_PASSWORD="${MYSQL_PASSWORD}"
    SKIP_MYSQL_INIT="true"
  fi
  
  # 如果 asterisk 未运行则启动
  if ! asterisk -r -x "core show version" 2>/dev/null ; then ./start_asterisk start ; fi

  # 连接 MySQL 数据库的计数器
  myn=1 ; myt=10
  
  until [ $myn -eq $myt ]; do
    checkMysql
    RETVAL=$?
    if [ $RETVAL = 0 ]; then
        myn=$myt
      else
        let myn+=1
        echo "--> 警告: 无法连接到 MySQL 数据库 '${MYSQL_SERVER}'... 等待数据库就绪... 10 秒后重试... 尝试:[$myn/$myt]"
        sleep 10
    fi
  done
  
  # 最终检查 MySQL 是否可达，否则退出并不尝试安装 FreePBX
  checkMysql && [ $? != 0 ] && "=> 错误: ${myt} 次尝试后仍无法连接到 MySQL 数据库。请检查数据库连接、用户名、密码和权限... 正在退出" && exit 1

  echo "--> 正在安装 FreePBX 到 '${fpbxDirs[AMPWEBROOT]}'"
  echo "---> 开始安装 FreePBX @ $(date)"
  # https://github.com/FreePBX/announcement/archive/release/15.0.zip
  
  # 设置默认 freepbx 安装选项
  FPBX_OPTS+=" --webroot=${fpbxDirs[AMPWEBROOT]}"
  FPBX_OPTS+=" --astetcdir=${fpbxDirs[ASTETCDIR]}"
  FPBX_OPTS+=" --astmoddir=${fpbxDirs[ASTMODDIR]}"
  FPBX_OPTS+=" --astvarlibdir=${fpbxDirs[ASTVARLIBDIR]}"
  FPBX_OPTS+=" --astagidir=${fpbxDirs[ASTAGIDIR]}"
  FPBX_OPTS+=" --astspooldir=${fpbxDirs[ASTSPOOLDIR]}"
  FPBX_OPTS+=" --astrundir=${appCacheDirs[ASTRUNDIR]}"
  FPBX_OPTS+=" --astlogdir=${fpbxDirs[ASTLOGDIR]}"
  FPBX_OPTS+=" --ampbin=${fpbxDirs[AMPBIN]}"
  FPBX_OPTS+=" --ampsbin=${fpbxDirs[AMPSBIN]}"
  FPBX_OPTS+=" --ampcgibin=${fpbxDirs[AMPCGIBIN]}"
  FPBX_OPTS+=" --ampplayback=${fpbxDirs[AMPPLAYBACK]}"
  
  # 如果 mysql 运行在非标准端口，则更改 mysql 服务器地址
  [[ ! -z "${APP_PORT_MYSQL}" && ${APP_PORT_MYSQL} -ne 3306 ]] && export MYSQL_SERVER="${MYSQL_SERVER}:${APP_PORT_MYSQL}"
  #set -x
  
  ## 创建 mysql 用户和数据库（如果不存在）
  if [ "$SKIP_MYSQL_INIT" != "true" ]; then
    echo "---> 正在创建并授权 FreePBX 数据库: ${MYSQL_DATABASE}, ${MYSQL_DATABASE_CDR}"
    # freepbx mysql 用户
    mysqlQuery "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    # freepbx asterisk 配置数据库
    mysqlQuery "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE}"
    mysqlQuery "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;"
    # freepbx asterisk CDR 数据库
    mysqlQuery "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_CDR}"
    mysqlQuery "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_CDR}.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;"
  fi
  
  # 验证数据库是否存在且可访问
  mysqlQuery "USE ${MYSQL_DATABASE};"     ; [ $? != 0 ] && echo "---> 警告: 无法访问 ${MYSQL_DATABASE} 数据库。请检查数据库是否存在以及权限... 正在退出" && exit 1
  mysqlQuery "USE ${MYSQL_DATABASE_CDR};" ; [ $? != 0 ] && echo "---> 警告: 无法访问 ${MYSQL_DATABASE_CDR} 数据库。请检查数据库是否存在以及权限... 正在退出" && exit 1

  # 安装 freepbx
  set -x
  ./install -n --skip-install --no-ansi --dbhost=${MYSQL_SERVER} --dbuser=${MYSQL_USER} --dbpass=${MYSQL_PASSWORD} --dbname=${MYSQL_DATABASE} --cdrdbname=${MYSQL_DATABASE_CDR} ${FPBX_OPTS}
  RETVAL=$?
  set +x
  echo "---> 结束安装 FreePBX @ $(date)"
  unset FPBX_OPTS

  # 如果安装成功
  if [ $RETVAL = 0 ]; then
    # 对 FreePBX 已知 bug 应用修复和临时解决方案
    freepbxSettingsFix
    #freepbxChown

    : ${FREEPBX_MODULES_CORE:="
      framework
      core
      dashboard
      sipsettings
      voicemail
    "}

    # 有序模块安装
    : ${FREEPBX_MODULES_PRE:="
      userman
      pm2
    "}
    
    : ${FREEPBX_MODULES_EXTRA:="
      soundlang
      callrecording
      cdr
      conferences
      customappsreg
      featurecodeadmin
      infoservices
      logfiles
      music
      manager
      arimanager
      filestore
      recordings
      announcement
      asteriskinfo
      backup
      callforward
      callwaiting
      daynight
      calendar
      certman
      cidlookup
      contactmanager
      donotdisturb
      fax
      findmefollow
      iaxsettings
      miscapps
      miscdests
      ivr
      parking
      phonebook
      presencestate
      printextensions
      queues
      cel
      timeconditions
      bulkhandler
      speeddial
      weakpasswords
      ucp
    "}

    # 禁用的模块
    : ${FREEPBX_MODULES_DISABLED:="
    "}

    echo "--> 正在启用扩展 FreePBX 仓库..."
    su - ${APP_USR} -s /bin/bash -c "fwconsole ma enablerepo extended"
    su - ${APP_USR} -s /bin/bash -c "fwconsole ma enablerepo unsupported"

    echo "--> 正在从本地仓库安装 FreePBX 前置模块到 '${fpbxDirs[AMPWEBROOT]}/admin/modules'"
    for module in ${FREEPBX_MODULES_PRE}; do
      echo "---> 正在安装模块: ${module}"
      # 前置模块需要以 root 身份安装
      su - ${APP_USR} -s /bin/bash -c "fwconsole ma install ${module}"
    done

    echo "--> 正在从本地仓库安装 FreePBX 扩展模块到 '${fpbxDirs[AMPWEBROOT]}/admin/modules'"
    for module in ${FREEPBX_MODULES_EXTRA}; do
      echo "---> 正在安装模块: ${module}"
      su - ${APP_USR} -s /bin/bash -c "fwconsole ma install ${module}"
    done

    if [ "${FREEPBX_AUTOUPDATE_MODULES_FIRSTDEPLOY}" = "true" ]; then
      echo "--> 正在自动升级 FreePBX 模块"
      su - ${APP_USR} -s /bin/bash -c "fwconsole ma upgradeall"
    fi

    # 重新加载 freePBX
    freepbxReload
    
    # 标记此次部署为已初始化
    touch "${APP_DATA}/.initialized"
    # 保存当前 FreePBX 版本号
    [ -z "$(cat "${APP_DATA}/.initialized")" ] && ${fpbxDirs[AMPBIN]}/fwconsole -V > "${APP_DATA}/.initialized"

    # 调试：在此暂停
    #sleep 300
  fi

  if [ $RETVAL = 0 ]; then
      n=$t
    else
      let n+=1
      echo "--> 安装 FreePBX 时出现问题... 10 秒后重新开始... 尝试:[$n/$t]"
      sleep 10
  fi
  done
  
  # 停止 asterisk
  if asterisk -r -x "core show version" 2>/dev/null ; then
    echo "--> 正在停止 Asterisk"
    asterisk -r -x "core stop now"
    echo "=> FreePBX 安装完成"
  fi
  echo "======================================================================"
}

## dnsmasq 服务
cfgService_dnsmasq() {
  [ "$DHCP_ENABLED" = "true" ] && cfgService_dhcp
  [ "$TFTP_ENABLED" = "true" ] && cfgService_tftp
}

## chronyd 服务（NTP 服务器）
cfgService_ntp() {
  # 如果设置了 NTP_SERVERS 变量，则禁用默认的 ntp pool 地址
  echo "# chronyd ntp 服务器配置
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony

bindcmdaddress 0.0.0.0
$([ -z "$NTP_SERVERS" ] && echo "pool 2.pool.ntp.org iburst" || for server in $NTP_SERVERS ; do echo "pool $server iburst"; done)

$(for subnet in $NTP_ALLOW_FROM ; do echo "allow $subnet"; done)
" > /etc/chrony.conf
}

## dhcp 服务
cfgService_dhcp() {
  echo "--> 正在配置 DHCP 服务"
  if [[ ! -z "$DHCP_POOL_START" || ! -z "$DHCP_POOL_END" || ! -z "$DHCP_POOL_LEASE" ]]; then
    sed "s|^#dhcp-range=.*|dhcp-range=$DHCP_POOL_START,$DHCP_POOL_END,$DHCP_POOL_LEASE|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  else
    echo "--> 警告: DHCP 服务器已启用但请指定 DHCP_POOL_START:[$DHCP_POOL_START] DHCP_POOL_END:[$DHCP_POOL_END] DHCP_POOL_LEASE:[$DHCP_POOL_LEASE]"
  fi
  
  if [ ! -z "$DHCP_DOMAIN" ]; then
    sed "s|^local=.*|local=/$DHCP_DOMAIN/|"   -i "${appDataDirs[DNSMASQDIR]}/local.conf"
    sed "s|^domain=.*|domain=/$DHCP_DOMAIN/|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
    sed "s|^#dhcp-option=option:domain-name,.*|dhcp-option=option:domain-name,$DHCP_DOMAIN|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  fi

  [ ! -z "$DHCP_DNS" ] && sed "s|^#dhcp-option=6,.*|dhcp-option=6,$DHCP_DNS|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  [ ! -z "$DHCP_DNS" ] && sed "s|^dhcp-option=6,.*|dhcp-option=6,$DHCP_DNS|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  
  [ ! -z "$DHCP_GW" ] && sed "s|^#dhcp-option=3,.*|dhcp-option=3,$DHCP_GW|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  [ ! -z "$DHCP_GW" ] && sed "s|^dhcp-option=3,.*|dhcp-option=3,$DHCP_GW|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  
  [ ! -z "$DHCP_NTP" ] && sed "s|^#dhcp-option=option:ntp-server,.*|dhcp-option=option:ntp-server,$DHCP_NTP|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
}

## tftp 服务
cfgService_tftp() {
  echo "--> 正在配置 TFTP 服务"
  sed "s|^#dhcp-option=66|dhcp-option=66|"                  -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  sed "s|^#enable-tftp|enable-tftp|"                        -i "${appDataDirs[DNSMASQDIR]}/local.conf"
  sed "s|^#tftp-root=.*|tftp-root=${appDataDirs[TFTPDIR]}|" -i "${appDataDirs[DNSMASQDIR]}/local.conf"
}

## zabbix 服务
cfgService_zabbix() {
  # 注释 zabbix 全局配置
  if [ -w "$ZABBIX_CONF" ]; then
    sed 's/^LogFile=/#LogFile=/g' -i $ZABBIX_CONF
    sed 's/^Hostname=/#Hostname=/g' -i $ZABBIX_CONF
    sed 's/^Server=/#Server=/g' -i $ZABBIX_CONF
    sed 's/^ServerActive=/#ServerActive=/g' -i $ZABBIX_CONF
  fi
  # zabbix 用户自定义本地配置
  echo "#DebugLevel=4
#LogFileSize=1
#EnableRemoteCommands=1
LogRemoteCommands=1
LogType=console

Server=${ZABBIX_SERVER}
ServerActive=${ZABBIX_SERVER_ACTIVE}

$(if [ "${ZABBIX_HOSTNAME}" = "${HOSTNAME}" ]; then
    echo "HostnameItem=system.hostname"
  else
    echo "Hostname=${ZABBIX_HOSTNAME}"
fi)

$(if [ ! -z "${ZABBIX_HOSTMETADATA}" ]; then
  echo "HostMetadataItem=system.uname"
  echo "HostMetadata=${ZABBIX_HOSTMETADATA}"
fi)
" > "$ZABBIX_CONF_LOCAL"
}

cfgService_fop2 () {
  [ ! -e "${appDataDirs[FOP2APPDIR]}/fop2.cfg" ] && cfgService_fop2_install

  if [ -e "${appDataDirs[FOP2APPDIR]}/fop2.cfg" ]; then
    # 从 freepbx 获取 asterisk manager 配置
    : ${FOP2_AMI_HOST:="$(fwconsole setting ASTMANAGERHOST | awk -F"[][{}]" '{print $2}')"}
    : ${FOP2_AMI_PORT:="$(fwconsole setting ASTMANAGERPORT | awk -F"[][{}]" '{print $2}')"}
    : ${FOP2_AMI_USERNAME:="$(fwconsole setting AMPMGRUSER | awk -F"[][{}]" '{print $2}')"}
    : ${FOP2_AMI_PASSWORD:="$(fwconsole setting AMPMGRPASS | awk -F"[][{}]" '{print $2}')"}
  
    # 重新配置 fop2.cfg
    sed "s|^manager_host.*=.*|manager_host=${FOP2_AMI_HOST}|" -i "${appDataDirs[FOP2APPDIR]}/fop2.cfg"
    sed "s|^manager_port.*=.*|manager_port=${FOP2_AMI_PORT}|" -i "${appDataDirs[FOP2APPDIR]}/fop2.cfg"
    sed "s|^manager_user.*=.*|manager_user=${FOP2_AMI_USERNAME}|" -i "${appDataDirs[FOP2APPDIR]}/fop2.cfg"
    sed "s|^manager_secret.*=.*|manager_secret=${FOP2_AMI_PASSWORD}|" -i "${appDataDirs[FOP2APPDIR]}/fop2.cfg"
   
    # FOP2 许可证代码管理
    # 许可接口
    [ -z "${FOP2_LICENSE_IFACE}" ] && FOP2_LICENSE_IFACE=eth0
    FOP2_LICENSE_OPTS+=" --rp=http --iface ${FOP2_LICENSE_IFACE}"
    # 如果指定了接口名称，则修改 fop2 命令
    [ ! -z "${FOP2_LICENSE_IFACE}" ] && sed "s|^command.*=.*|command=/usr/local/fop2/fop2_server -i ${FOP2_LICENSE_IFACE}|" -i "${SUPERVISOR_DIR}/fop2.ini"

    # fop2 版本升级检查
    if [ "$FOP2_AUTOUPGRADE" = "true" ]; then
      [ -e "${appDataDirs[FOP2APPDIR]}/fop2_server" ] && FOP2_VER_CUR=$("${appDataDirs[FOP2APPDIR]}/fop2_server" -v 2>/dev/null | awk '{print $3}')
      if   [ $(check_version $FOP2_VER_CUR) -lt $(check_version $FOP2_VER) ]; then
        echo "=> 信息: 检测到 FOP2 更新... 正在从 $FOP2_VER_CUR 升级到 $FOP2_VER"
        cfgService_fop2_upgrade
      elif [ $(check_version $FOP2_VER_CUR) -gt $(check_version $FOP2_VER) ]; then
        echo "=> 警告: 指定的 FOP2_VER=$FOP2_VER 比已安装版本 $FOP2_VER_CUR 更旧"
      else
        echo "=> 信息: 指定的 FOP2_VER=$FOP2_VER，已安装版本: $FOP2_VER_CUR"
      fi
    fi
    
    if [ ! -e "${appDataDirs[FOP2APPDIR]}/fop2.lic" ]; then
        if [ -z "${FOP2_LICENSE_CODE}" ]; then
            echo "--> 信息: FOP2 未授权且未定义 'FOP2_LICENSE_CODE' 变量... 以演示模式运行"
          else
            echo "--> 信息: 正在注册 FOP2"
            echo "---> 名称: ${FOP2_LICENSE_NAME}"
            echo "---> 代码: ${FOP2_LICENSE_CODE}"
            echo "---> 接口: ${FOP2_LICENSE_IFACE} ($(ip a show dev ${FOP2_LICENSE_IFACE} | grep 'link/ether' | awk '{print $2}'))"
            set -x
            ${appDataDirs[FOP2APPDIR]}/fop2_server --register --name "${FOP2_LICENSE_NAME}" --code "${FOP2_LICENSE_CODE}" $FOP2_LICENSE_OPTS
            set +x
            echo "--> 信息: FOP2 许可证代码信息:"
            ${appDataDirs[FOP2APPDIR]}/fop2_server --getinfo $FOP2_LICENSE_OPTS
            echo "--> 信息: FOP2 许可证代码状态:"
            ${appDataDirs[FOP2APPDIR]}/fop2_server --test $FOP2_LICENSE_OPTS
        fi
      else
        #FOP2_LICENSE_STATUS="$(${appDataDirs[FOP2APPDIR]}/fop2_server --getinfo $FOP2_LICENSE_OPTS)"
        FOP2_LICENSE_STATUS="$(${appDataDirs[FOP2APPDIR]}/fop2_server --test $FOP2_LICENSE_OPTS)"
        if [ ! -z "$(echo $FOP2_LICENSE_STATUS | grep "Demo")" ]; then
          echo "--> 警告: 正在重新激活 FOP2 许可证，因为:"
          echo $FOP2_LICENSE_STATUS
          set -x
          ${appDataDirs[FOP2APPDIR]}/fop2_server --reactivate $FOP2_LICENSE_OPTS
          local RETVAL=$?
          set +x
          if [ $RETVAL != 0 ]; then
            echo "echo --> 错误: 重新激活许可证失败... 正在尝试撤销并重新注册:"
            set -x
            ${appDataDirs[FOP2APPDIR]}/fop2_server --revoke   --name "${FOP2_LICENSE_NAME}" --code "${FOP2_LICENSE_CODE}" $FOP2_LICENSE_OPTS
            ${appDataDirs[FOP2APPDIR]}/fop2_server --register --name "${FOP2_LICENSE_NAME}" --code "${FOP2_LICENSE_CODE}" $FOP2_LICENSE_OPTS
            set +x
          fi
          unset RETVAL
        fi
        echo "--> 信息: FOP2 许可证代码信息:"
        ${appDataDirs[FOP2APPDIR]}/fop2_server --getinfo $FOP2_LICENSE_OPTS
        echo "--> 信息: FOP2 许可证代码状态:"
        ${appDataDirs[FOP2APPDIR]}/fop2_server --test $FOP2_LICENSE_OPTS
    fi
  fi
}

cfgService_pma() {
    echo "=> 正在启用并配置 phpMyAdmin"
    # 移除未使用的 http 别名
    sed "/^Alias \/phpMyAdmin \/usr\/share\/phpMyAdmin/d" -i "${PMA_CONF_APACHE}"
    # 重新配置 http 别名
    sed "s|^Alias /phpmyadmin /usr/share/phpMyAdmin|Alias ${PMA_ALIAS} /usr/share/phpMyAdmin|" -i "${PMA_CONF_APACHE}"
    # 允许来自内部网络的连接
    #sed "s|Require local|Require ip ${PMA_ALLOW_FROM}|" -i "${PMA_CONF_APACHE}"
    cat <<EOF >> "${PMA_CONF_APACHE}"
<Directory /usr/share/phpMyAdmin/>
  AddDefaultCharset UTF-8
$(for FROM in ${PMA_ALLOW_FROM}; do echo "    Require ip $FROM"; done)
</Directory>
EOF
    # 配置数据库访问
    sed "s|'localhost';|'${MYSQL_SERVER}';|" -i "${PMA_CONFIG}"
}

cfgService_phonebook() {
    echo "=> 正在启用远程 XML 电话本支持"
    
    echo "Alias /pb /usr/local/share/phonebook

<Directory /usr/local/share/phonebook>
    AddDefaultCharset UTF-8
    DirectoryIndex menu.xml index.php
$(print_ApacheAllowFrom)
</Directory>
" > "${HTTPD_CONF_DIR}/conf.d/phonebook.conf"

echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<CompanyIPPhoneMenu>
    <!-- Title can show on the phone depending on settings in phone -->
    <Title>PhoneBook Menu</Title>
    <MenuItem>
       	<!-- This name shows in the menu when the button is pressed -->
        <Name>Extensions</Name>
        <URL>${PHONEBOOK_ADDRESS}/pb/yealink/ext</URL>
    </MenuItem>
    <MenuItem>
        <Name>Shared PhoneBook</Name>
        <URL>${PHONEBOOK_ADDRESS}/pb/yealink/cm</URL>
    </MenuItem>
</CompanyIPPhoneMenu>
" > "/usr/local/share/phonebook/menu.xml"
}

cfgService_letsencrypt() {
  echo "=> 正在为 '$APP_FQDN' 生成 Let's Encrypt 证书"
  if   [ -z "$APP_FQDN" ]; then
    echo "--> 警告: 跳过 Let's Encrypt 证书请求，因为未定义 APP_FQDN"
  elif [ -z "$LETSENCRYPT_COUNTRY_CODE" ]; then
    echo "--> 警告: 跳过 Let's Encrypt 证书请求，因为未定义 LETSENCRYPT_COUNTRY_CODE"
  elif [ -z "$LETSENCRYPT_COUNTRY_STATE" ]; then
    echo "--> 警告: 跳过 Let's Encrypt 证书请求，因为未定义 LETSENCRYPT_COUNTRY_STATE"
  elif [ -z "$SMTP_MAIL_TO" ]; then
    echo "--> 警告: 跳过 Let's Encrypt 证书请求，因为未定义 SMTP_MAIL_TO"
  else
    # 生成 Let's Encrypt 证书
    # 注意: Apache Web 服务器必须运行才能完成 certbot 握手
    # FIXME: 如果 FQDN 地址与发起请求的出站地址不同，认证过程将失败:
    #        Error 'Requested host 'APP_FQDN' does not resolve to 'EXTERNAL OUTGOING IP'...
    CERTOK=1
    
    # 续期现有证书
    if [ -e "${fpbxDirs[CERTKEYLOC]}/$APP_FQDN.pem" ]; then
      echo "--> '$APP_FQDN' 的 Let's Encrypt 证书已存在... 检查并更新所有证书"
      httpd -k start
      fwconsole certificates --updateall
      [ $? -eq 0 ] && CERTOK=0
      [ $CERTOK -eq 0 ] && fwconsole certificates --default=$APP_FQDN
      [ $CERTOK -eq 0 ] && echo "--> 默认 FreePBX 证书已配置为 ${fpbxDirs[CERTKEYLOC]}/$APP_FQDN.pem"
      httpd -k stop
    fi

    # 申请新证书
    if [ $CERTOK -eq 1 ]; then
      httpd -k start
      set -x
      fwconsole certificates -n --generate --type=le --hostname=$APP_FQDN --country-code=$LETSENCRYPT_COUNTRY_CODE --state=$LETSENCRYPT_COUNTRY_STATE --email=$SMTP_MAIL_FROM
      set +x
      [ $? -eq 0 ] && CERTOK=0
      [ $CERTOK -eq 0 ] && fwconsole certificates --default=$APP_FQDN
      [ $CERTOK -eq 0 ] && echo "--> 默认 FreePBX 证书已配置为 ${fpbxDirs[CERTKEYLOC]}/$APP_FQDN.pem"
      httpd -k stop
    fi
  fi
}

cfgService_fop2_install() {
  echo
  echo "=> !!! FOP2 尚未初始化 :: 检测到全新安装 !!! 正在下载和安装 FOP2..."
  echo
  fwconsole start
  if [ -z "$FOP2_VER" ]; then
    # 自动安装最新版本
    wget -O - http://download.fop2.com/install_fop2.sh | bash
   else
    curl -fSL --connect-timeout 30 http://download2.fop2.com/fop2-$FOP2_VER-centos-x86_64.tgz | tar xz -C /usr/src
    cd /usr/src/fop2 && make install && /usr/local/fop2/generate_override_contexts.pl -write
  fi

  pkill fop2_server
  fwconsole stop
}

cfgService_fop2_upgrade() {
  #:${FOP2_VER:=$1}
  #[ -z "${FOP2_VER}" ] && echo "--> 错误: 未定义 FOP2 升级版本... 请定义 FOP2_VER 变量或作为参数传入... 正在退出" && return

  # 容器临时方案
  export TERM=linux
  echo "-i ${FOP2_LICENSE_IFACE}" > /etc/sysconfig/fop2

  curl -fSL --connect-timeout 30 http://download2.fop2.com/fop2-$FOP2_VER-centos-x86_64.tgz | tar xz -C /usr/src
  cd /usr/src/fop2 && make install
}

cfgBashEnv() {
  echo '. /etc/os-release
  APP="izPBX"
  DOMAIN="$(hostname | cut -d'.' -f2)"
  if [ ! -z "$DOMAIN" ];then DOMAIN=".${DOMAIN}" ; fi
  
  if [ -t 1 ]; then
    export PS1="(${APP})\e[1;34m[\e[1;33m\u@\e[1;32m\h\e[2m$DOMAIN\e[0m: \e[1;37m\w\[\e[1;34m]\e[1;36m\\$ \e[0m"
  fi

  # 别名
  alias d="ls -lAsh --color"
  alias cp="cp -ip"
  alias rm="rm -i"
  alias mv="mv -i"

  echo -e -n "\E[1;34m"
  figlet -w 120 "${APP}"

  : ${APP_VER:="unknown"}
  : ${APP_VER_BUILD:="unknown"}
  : ${APP_BUILD_COMMIT:="unknown"}
  : ${APP_BUILD_DATE:="unknown"}
  
  [ "${APP_BUILD_DATE}" != "unknown" ] && APP_BUILD_DATE=$(date -d @${APP_BUILD_DATE} +"%Y-%m-%d")
  
  echo -e "\E[1;36m${APP} \E[1;32m${APP_VER}\E[1;36m (build: \E[1;32m${APP_VER_BUILD}\E[1;36m commit: \E[1;32m${APP_BUILD_COMMIT}\E[1;36m date: \E[1;32m${APP_BUILD_DATE}\E[1;36m), Asterisk \E[1;32m${ASTERISK_VER:-unknown}\E[1;36m, FreePBX \E[1;32m${FREEPBX_VER:-unknown}\E[1;36m, ${NAME} \E[1;32m${VERSION_ID:-unknown}\E[1;36m, Kernel \E[1;32m$(uname -r)\E[0m"
  echo'
}

runHooks() {
  # 配置 supervisord
  echo "--> 正在修正 supervisord 配置文件..."
  if   [ "$OS_RELEASE" = "debian" ]; then
    echo "---> 检测到 Debian Linux"
    sed 's|^files = .*|files = /etc/supervisor/conf.d/*.ini|' -i /etc/supervisor/supervisord.conf
    mkdir -p /var/log/supervisor /var/log/proftpd /var/log/dbconfig-common /var/log/apt/ /var/log/apache2/ /var/run/nagios/
    touch /var/log/wtmp /var/log/lastlog
    [ ! -e /sbin/nologin ] && ln -s /usr/sbin/nologin /sbin/nologin
  else
    echo "---> 检测到基于 RHEL 的 Linux 发行版"
    mkdir -p /run/supervisor
    sed 's/\[supervisord\]/\[supervisord\]\nuser=root/' -i /etc/supervisord.conf
    sed 's|^file=.*|file=/run/supervisor/supervisor.sock|' -i /etc/supervisord.conf
    sed 's|^pidfile=.*|pidfile=/run/supervisor/supervisord.pid|' -i /etc/supervisord.conf
    sed 's|^nodaemon=.*|nodaemon=true|' -i /etc/supervisord.conf
    # 配置 Web 服务器安全
    #echo unix_http_server username=admin | iniParser /etc/supervisord.conf
    #echo unix_http_server password=izpbx | iniParser /etc/supervisord.conf
    
#     echo "
# [eventlistener:processes]
# command=stop-supervisor.sh
# events=PROCESS_STATE_STOPPED, PROCESS_STATE_EXITED, PROCESS_STATE_FATAL" >> /etc/supervisord.conf
    
  fi

  # 检查并创建缺失的容器目录
  if [ ! -z "${APP_DATA}" ]; then
    echo "=> 检测到持久化存储路径... 正在使用基础目录重定位并重新配置系统数据和配置文件: ${APP_DATA}"
    for dir in ${appDataDirs[@]}
      do
        dir="${APP_DATA}${dir}"
        if [ ! -e "${dir}" ];then
          echo "--> 正在创建缺失的目录: '$dir'"
          mkdir -p "${dir}"
        fi
      done

    # 如需则链接到自定义数据目录
    for dir in ${appDataDirs[@]}; do
      symlinkDir "${dir}" "${APP_DATA}${dir}"
    done

    for file in ${appFilesConf[@]}; do
      # echo FILE=$file
      symlinkFile "${file}" "${APP_DATA}${file}"
    done
   else
    echo "=> 警告: 未检测到持久化存储路径... 容器重启后配置将丢失"
  fi

  # 检查文件和目录权限
  echo "--> 正在验证文件权限"

  # TFTPDIR 权限和路径修正
  fixOwner "${APP_USR}" "${APP_GRP}" "${appDataDirs[TFTPDIR]}"
  [ ! -e "/tftpboot" ] && ln -s "${appDataDirs[TFTPDIR]}" "/tftpboot"

#   for dir in ${appDataDirs[@]}; do
#     [ ! -z "${APP_DATA}" ] && dir="${APP_DATA}${dir}"
#     fixOwner "${APP_USR}" "${APP_GRP}" "${dir}"
#   done
#   for dir in ${appCacheDirs[@]}; do
#     [ ! -e "${dir}" ] && mkdir -p "${dir}"
#     fixOwner "${APP_USR}" "${APP_GRP}" "${dir}"
#   done
#   for file in ${appFilesConf[@]}; do
#     [ ! -z "${APP_DATA}" ] && file="${APP_DATA}${file}"
#     fixOwner "${APP_USR}" "${APP_GRP}" "${file}"
#   done

  # 自定义 bash 环境
  cfgBashEnv > /etc/profile.d/izpbx.sh

  # 启用/禁用和配置服务
  #chkService SYSLOG_ENABLED
  chkService POSTFIX_ENABLED
  chkService CRON_ENABLED
  chkService FAIL2BAN_ENABLED
  chkService HTTPD_ENABLED
  chkService ASTERISK_ENABLED
  chkService IZPBX_ENABLED
  chkService ZABBIX_ENABLED
  chkService FOP2_ENABLED
  chkService NTP_ENABLED

  # dnsmasq 管理
  [[ "$DHCP_ENABLED" = "true" || "$TFTP_ENABLED" = "true" ]] && DNSMASQ_ENABLED=true
  chkService DNSMASQ_ENABLED

  # phpMyAdmin 配置
  [ "${PMA_ENABLED}" = "true" ] && cfgService_pma || mv "${PMA_CONF_APACHE}" "${PMA_CONF_APACHE}-disabled"

  # 远程 XML 电话本支持
  [ ${PHONEBOOK_ENABLED} = "true" ] && cfgService_phonebook

  # Let's Encrypt 证书生成
  [[ "${HTTPD_HTTPS_ENABLED}" = "true" && "${LETSENCRYPT_ENABLED}" = "true" ]] && cfgService_letsencrypt
}

runHooks
