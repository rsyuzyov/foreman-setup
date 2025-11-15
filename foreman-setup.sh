#!/bin/bash
set -e

. /etc/os-release
if [[ "$ID" != "debian" || "$VERSION_ID" != "12" ]]; then
  echo "Неподходящая версия ОС: ${PRETTY_NAME}, установка рассчитана на debian 12"
  exit 1
fi

# apt по умолчанию пытается работать на ipv6, но не всегда справляется
grep -qxF "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
grep -qxF "net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
grep -qxF "net.ipv6.conf.lo.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" | tee -a /etc/sysctl.conf

# foreman требует в hosts запись fqdn для 127.0.0.1, если ip динамический; запись должна быть первой, не должно быть других записей для fqdn
# Используем facter для получения FQDN, если доступен
if [ -x /opt/puppetlabs/bin/facter ]; then
    HOSTNAME_F=$(/opt/puppetlabs/bin/facter fqdn)
else
    HOSTNAME_F=$(hostname -f)
fi
HOSTNAME_S=$(hostname -s)
grep -v "^127.0.1.1 " /etc/hosts | grep -v "^127.0.0.1 $HOSTNAME_F" | grep -v "^127.0.0.1 $HOSTNAME_S$" > /tmp/hosts.tmp
grep -qxF "127.0.0.1 $HOSTNAME_F $HOSTNAME_S" /tmp/hosts.tmp || sed -i "1i127.0.0.1 $HOSTNAME_F $HOSTNAME_S" /tmp/hosts.tmp
cat /tmp/hosts.tmp > /etc/hosts
rm -f /tmp/hosts.tmp

apt update && apt dist-upgrade -y
apt install -y ca-certificates wget gnupg lsb-release locales

sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^# *\(ru_RU.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

[ -f /usr/share/keyrings/foreman.gpg ] && rm -f /usr/share/keyrings/foreman.gpg
wget -O- https://deb.theforeman.org/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/foreman.gpg 2>/dev/null || true
echo "deb [signed-by=/usr/share/keyrings/foreman.gpg] http://deb.theforeman.org/ bookworm 3.17" | tee /etc/apt/sources.list.d/foreman.list
echo "deb [signed-by=/usr/share/keyrings/foreman.gpg] http://deb.theforeman.org/ plugins 3.17" | tee /etc/apt/sources.list.d/foreman-plugins.list
apt update

apt --fix-broken install -y 
apt install -y openjdk-17-jdk
apt install -y postgresql
systemctl enable postgresql
systemctl start postgresql

# Установка из репы puppet не возможна из-за низкой скорости скачаивания; скачать руками, закинуть в ВМ и установить:
#https://apt.puppet.com/pool/bookworm/puppet8/p/puppet-agent/puppet-agent_8.10.0-1bookworm_amd64.deb
#https://apt.puppet.com/pool/bookworm/puppet8/p/puppetserver/puppetserver_8.7.0-1bookworm_all.deb
dpkg -i ./assets/*.deb || true
apt --fix-broken install -y 

apt install -y foreman-installer
apt install -y ruby-foreman-fog-proxmox

foreman-installer --enable-foreman-plugin-ansible --enable-foreman-proxy-plugin-ansible

echo "Foreman installation completed. Access the web interface at: https://$(hostname -f)"
