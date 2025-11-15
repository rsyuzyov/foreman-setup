#!/bin/bash
set -e

# Функция для логирования
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Запуск контейнера Foreman..."

# Настройка hostname
if [ -n "$FOREMAN_FQDN" ]; then
    log "Настройка hostname: $FOREMAN_FQDN"
    hostname $(echo $FOREMAN_FQDN | cut -d. -f1)
    sed -i "1i127.0.0.1 ${FOREMAN_FQDN} $(echo ${FOREMAN_FQDN} | cut -d. -f1)" /etc/hosts
fi

# Инициализация PostgreSQL
if [ ! -d "/var/lib/postgresql/15/main" ] || [ -z "$(ls -A /var/lib/postgresql/15/main)" ]; then
    log "Инициализация базы данных PostgreSQL..."
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/main"
    
    # Настройка конфигурации PostgreSQL
    echo "host all all 127.0.0.1/32 md5" >> /var/lib/postgresql/15/main/pg_hba.conf
    echo "listen_addresses = 'localhost'" >> /var/lib/postgresql/15/main/postgresql.conf
fi

# Запуск PostgreSQL
log "Запуск PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/main -l /var/log/postgresql/postgresql.log start"

# Ожидание готовности PostgreSQL
log "Ожидание готовности PostgreSQL..."
for i in {1..30}; do
    if su - postgres -c "psql -c 'SELECT 1'" &>/dev/null; then
        log "PostgreSQL готов"
        break
    fi
    sleep 1
done

# Проверка, был ли уже выполнен foreman-installer
if [ ! -f "/etc/foreman/foreman-installer-configured" ]; then
    log "Запуск foreman-installer..."
    foreman-installer \
        --enable-foreman-plugin-ansible \
        --enable-foreman-proxy-plugin-ansible \
        --foreman-initial-admin-username=admin \
        --foreman-initial-admin-password=changeme
    
    # Создание маркера успешной установки
    touch /etc/foreman/foreman-installer-configured
    
    log "Установка Foreman завершена!"
    log "Веб-интерфейс доступен по адресу: https://${FOREMAN_FQDN}"
    log "Логин: admin"
    log "Пароль: changeme"
else
    log "Foreman уже настроен, запуск сервисов..."
fi

# Запуск Apache/Nginx (в зависимости от установки)
if command -v apache2ctl &> /dev/null; then
    log "Запуск Apache..."
    apache2ctl start
fi

# Поддержание контейнера в работающем состоянии
log "Контейнер Foreman готов к работе"

# Выполнение переданной команды или поддержание работы
if [ "$1" = "bash" ] || [ -z "$1" ]; then
    # Бесконечный цикл для поддержания контейнера
    tail -f /dev/null
else
    exec "$@"
fi