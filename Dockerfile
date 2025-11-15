FROM debian:12

# Предотвращение интерактивных запросов при установке пакетов
ENV DEBIAN_FRONTEND=noninteractive

# Установка локали
ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8
ENV LC_CTYPE=ru_RU.UTF-8

# Настройка hostname (можно переопределить при запуске)
ARG FOREMAN_FQDN=foreman.local
ENV FOREMAN_FQDN=${FOREMAN_FQDN}

# Обновление системы и установка базовых пакетов
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
        ca-certificates \
        wget \
        gnupg \
        lsb-release \
        locales \
        systemd \
        systemd-sysv && \
    rm -rf /var/lib/apt/lists/*

# Настройка локалей
RUN sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen && \
    sed -i 's/^# *\(ru_RU.UTF-8 UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=ru_RU.UTF-8

# Настройка /etc/hosts для Foreman
RUN echo "127.0.0.1 ${FOREMAN_FQDN} $(echo ${FOREMAN_FQDN} | cut -d. -f1)" >> /etc/hosts

# Добавление репозиториев Foreman
RUN wget -O- https://deb.theforeman.org/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/foreman.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/foreman.gpg] http://deb.theforeman.org/ bookworm 3.17" > /etc/apt/sources.list.d/foreman.list && \
    echo "deb [signed-by=/usr/share/keyrings/foreman.gpg] http://deb.theforeman.org/ plugins 3.17" > /etc/apt/sources.list.d/foreman-plugins.list && \
    apt-get update

# Установка Java и PostgreSQL
RUN apt-get install -y \
        openjdk-17-jdk \
        postgresql \
        postgresql-contrib && \
    rm -rf /var/lib/apt/lists/*

# Копирование и установка .deb пакетов из assets
COPY assets/*.deb /tmp/assets/
RUN dpkg -i /tmp/assets/*.deb || true && \
    apt-get update && \
    apt-get --fix-broken install -y && \
    rm -rf /tmp/assets && \
    rm -rf /var/lib/apt/lists/*

# Установка Foreman и плагинов
RUN apt-get update && \
    apt-get install -y \
        foreman-installer \
        ruby-foreman-fog-proxmox && \
    rm -rf /var/lib/apt/lists/*

# Создание скрипта для инициализации и запуска
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Открытие портов
# 443 - HTTPS для веб-интерфейса Foreman
# 80 - HTTP (редирект на HTTPS)
# 8140 - Puppet Server
# 8443 - Smart Proxy
EXPOSE 443 80 8140 8443

VOLUME ["/var/lib/postgresql", "/etc/foreman", "/var/lib/foreman"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]