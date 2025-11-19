#!/bin/bash
set -e

FOREMAN_VERSION="3.17"
SKIP_CHECKS="--skip-checks-i-know-better"

while [[ $# -gt 0 ]]; do
  case $1 in
    -v)
      FOREMAN_VERSION="$2"
      shift 2
      ;;
    -check)
      SKIP_CHECKS=""
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$SKIP_CHECKS" ]; then
  CHECKS_STATUS="включены"
else
  CHECKS_STATUS="отключены"
fi

echo "Устанавливаемая версия Foreman: $FOREMAN_VERSION, проверки $CHECKS_STATUS"

. /etc/os-release
if [[ "$ID" != "debian" || "$VERSION_ID" != "12" ]]; then
  echo "Неподходящая версия ОС: ${PRETTY_NAME}, установка рассчитана на debian 12"
  exit 1
fi

# Настройка /etc/hosts для корректного разрешения FQDN в реальный IP
# Foreman требует, чтобы FQDN разрешался в IP интерфейса, а не 127.0.0.1/127.0.1.1
CURRENT_IP=$(hostname -I | awk '{print $1}')
FQDN=$(hostname -f)
SHORTNAME=$(hostname -s)

if [ -n "$CURRENT_IP" ]; then
  # Удаляем старые записи для FQDN, если они указывают на loopback
  sed -i "/^127\.0\.[01]\.1[[:space:]].*$FQDN/d" /etc/hosts
  
  # Добавляем запись с реальным IP, если её нет
  if ! grep -q "^$CURRENT_IP.*$FQDN" /etc/hosts; then
    echo "$CURRENT_IP $FQDN $SHORTNAME" >> /etc/hosts
  fi
fi

apt update && apt dist-upgrade -y
apt install -y ca-certificates wget gnupg lsb-release locales

sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^# *\(ru_RU.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
update-locale LANG=ru_RU.UTF-8

export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8
export LC_CTYPE=ru_RU.UTF-8

[ -f /usr/share/keyrings/foreman.gpg ] && rm -f /usr/share/keyrings/foreman.gpg
wget -O- https://deb.theforeman.org/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/foreman.gpg 2>/dev/null || true
echo "deb [signed-by=/usr/share/keyrings/foreman.gpg] http://deb.theforeman.org/ bookworm $FOREMAN_VERSION" | tee /etc/apt/sources.list.d/foreman.list
echo "deb [signed-by=/usr/share/keyrings/foreman.gpg] http://deb.theforeman.org/ plugins $FOREMAN_VERSION" | tee /etc/apt/sources.list.d/foreman-plugins.list
apt update

dpkg -i ./assets/*.deb
apt --fix-broken install -y 
apt install -y -o Acquire::ForceIPv4=true openjdk-17-jdk postgresql foreman-installer
systemctl enable postgresql
systemctl start postgresql

foreman-installer \
  $SKIP_CHECKS \
  --enable-apache-mod-status \
  --enable-foreman \
  --enable-foreman-cli \
  --enable-foreman-cli-ansible \
  --enable-foreman-cli-bootdisk \
  --enable-foreman-cli-discovery \
  --enable-foreman-cli-puppet \
  --enable-foreman-cli-remote-execution \
  --enable-foreman-cli-ssh \
  --enable-foreman-cli-tasks \
  --enable-foreman-cli-templates \
  --enable-foreman-cli-webhooks \
  --enable-foreman-proxy \
  --enable-puppet \
  --enable-foreman-plugin-ansible \
  --enable-foreman-plugin-bootdisk \
  --enable-foreman-plugin-default-hostgroup \
  --enable-foreman-plugin-dhcp-browser \
  --enable-foreman-plugin-discovery \
  --enable-foreman-plugin-expire-hosts \
  --enable-foreman-plugin-monitoring \
  --enable-foreman-plugin-proxmox \
  --enable-foreman-plugin-puppet \
  --enable-foreman-plugin-puppetdb \
  --enable-foreman-plugin-remote-execution \
  --enable-foreman-plugin-rescue \
  --enable-foreman-plugin-snapshot-management \
  --enable-foreman-plugin-statistics \
  --enable-foreman-plugin-tasks \
  --enable-foreman-plugin-templates \
  --enable-foreman-plugin-webhooks \
  --enable-foreman-proxy-plugin-ansible \
  --enable-foreman-proxy-plugin-discovery \
  --enable-foreman-proxy-plugin-monitoring \
  --enable-foreman-proxy-plugin-remote-execution-script \
  --enable-foreman-proxy-plugin-shellhooks \
  --foreman-initial-admin-username=admin \
  --foreman-initial-admin-password=changeme

echo "Foreman installation completed. Access the web interface at: https://$(hostname -f)"
