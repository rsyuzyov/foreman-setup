# Foreman в Docker - Подробное руководство

## Описание созданных файлов

### Dockerfile
Основной файл для сборки Docker-образа с Foreman. Базируется на Debian 12 и повторяет все шаги из [`foreman-setup.sh`](foreman-setup.sh):

- Устанавливает базовые пакеты и настраивает локали (ru_RU.UTF-8, en_US.UTF-8)
- Добавляет официальные репозитории Foreman 3.17
- Устанавливает Java 17 и PostgreSQL
- Копирует и устанавливает .deb пакеты из директории [`assets/`](assets/)
- Устанавливает foreman-installer и плагины

### docker-entrypoint.sh
Скрипт инициализации и запуска контейнера:

- Настраивает hostname и `/etc/hosts`
- Инициализирует и запускает PostgreSQL
- Запускает `foreman-installer` при первом запуске
- Запускает веб-сервер Apache
- Поддерживает контейнер в рабочем состоянии

### docker-compose.yml
Конфигурация для развертывания через Docker Compose:

- Определяет сервис foreman
- Настраивает порты (443, 80, 8140, 8443)
- Создает volumes для персистентности данных
- Настраивает сеть

## Основные отличия от скрипта установки

1. **Отключение IPv6**: В Docker не требуется отключать IPv6 через sysctl, так как это управляется на уровне хоста

2. **Systemd**: Docker-образ использует прямой запуск сервисов вместо systemd

3. **Персистентность**: Данные сохраняются в Docker volumes, что обеспечивает изоляцию и простоту резервного копирования

4. **Privilege mode**: Контейнер требует привилегированного режима для корректной работы Foreman и PostgreSQL

## Структура проекта

```
foreman-setup/
├── Dockerfile              # Основной файл сборки образа
├── docker-compose.yml      # Конфигурация Docker Compose
├── docker-entrypoint.sh    # Скрипт инициализации
├── .dockerignore          # Исключения при сборке
├── foreman-setup.sh       # Оригинальный скрипт установки
├── README.md              # Основная документация
├── DOCKER.md              # Данный файл
└── assets/                # .deb пакеты Puppet
    ├── puppet-agent_8.10.0-1bookworm_amd64.deb
    └── puppetserver_8.7.0-1bookworm_all.deb
```

## Устранение неполадок

### Контейнер не запускается
```bash
# Проверьте логи
docker-compose logs foreman

# Проверьте статус контейнера
docker-compose ps
```

### База данных не инициализируется
```bash
# Удалите volumes и создайте заново
docker-compose down -v
docker-compose up -d
```

### Веб-интерфейс недоступен
```bash
# Проверьте, что порты не заняты на хосте
netstat -tuln | grep -E '443|80'

# Проверьте, что hostname правильно настроен в /etc/hosts
cat /etc/hosts | grep foreman
```

### Ошибки при установке плагинов
```bash
# Подключитесь к контейнеру и проверьте логи Foreman
docker-compose exec foreman bash
tail -f /var/log/foreman/production.log
```

## Безопасность

**ВАЖНО:** После первого запуска обязательно смените пароль администратора!

```bash
# Подключитесь к контейнеру
docker-compose exec foreman bash

# Смените пароль
foreman-rake permissions:reset password=НовыйБезопасныйПароль
```

## Производительность

Для оптимальной производительности рекомендуется:

- Минимум 4 ГБ RAM для контейнера
- SSD для Docker volumes
- Если нужна высокая производительность БД, рассмотрите использование отдельного контейнера PostgreSQL

## Интеграция с существующей инфраструктурой

### Использование внешней БД PostgreSQL

Отредактируйте [`docker-compose.yml`](docker-compose.yml) и добавьте переменные окружения:

```yaml
environment:
  - DB_HOST=postgres.example.com
  - DB_PORT=5432
  - DB_USERNAME=foreman
  - DB_PASSWORD=password
  - DB_DATABASE=foreman
```

### Использование SSL-сертификатов

Смонтируйте сертификаты в контейнер:

```yaml
volumes:
  - ./certs:/etc/foreman/certs:ro
```

## Обновление

Для обновления Foreman:

1. Сделайте резервную копию
2. Остановите контейнер
3. Обновите версию в Dockerfile
4. Пересоберите образ
5. Запустите контейнер

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Дополнительные ресурсы

- [Официальная документация Foreman](https://theforeman.org/documentation.html)
- [Foreman на GitHub](https://github.com/theforeman/foreman)
- [Документация Docker](https://docs.docker.com/)