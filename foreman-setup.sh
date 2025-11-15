#!/bin/bash
set -e

# apt по умолчанию пытается работать на ipv6, но не всегда справляется
grep -qxF "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
grep -qxF "net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
grep -qxF "net.ipv6.conf.lo.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" | tee -a /etc/sysctl.conf

# foreman требует в hosts запись для fqdn, если ip динамический
grep -qxF "127.0.0.1 $(hostname -f) $(hostname -s)" /etc/hosts || sed -i "1i127.0.0.1 $(hostname -f) $(hostname -s)" /etc/hosts

apt update && apt dist-upgrade -y
apt install -y ca-certificates wget gnupg lsb-release locales

sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^# *\(ru_RU.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

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
