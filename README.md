# Установка foreman
Несмотря на заявления разработчиков, что foreman - зрелый продукт, его нельзя просто взять и поставить, пользователи должны страдать. Хотя возможно именно в этом продукт достиг максимальной зрелости.
Для облегчения страданий был создан этот репозиторий.

## Требования

### Для установки на хост-системе
    debian 12 (не 13, слишком свежий ruby, и не centos - там другие страдания)
    4 ядра (min 2)
    8 ГБ ОЗУ (min 4)

### Для установки через Docker
    Docker 20.10+
    Docker Compose 2.0+
    4 ГБ свободного места на диске
    4 ядра (min 2)
    8 ГБ ОЗУ (min 4)

## Установка на хост-системе

Запустить с повышенными правами:
```bash
apt install git -y
git clone https://github.com/rsyuzyov/foreman-setup.git
cd foreman-setup
chmod +x foreman-setup.sh
./foreman-setup.sh
```

## Установка через Docker
```bash
git clone https://github.com/rsyuzyov/foreman-setup.git
cd foreman-setup
docker-compose up -d --build
docker-compose logs -f foreman
```
После завершения установки, Foreman будет доступен по адресу:
```
https://foreman.local
Логин: admin
Пароль: changeme
```
**Важно:** Добавьте `foreman.local` в файл `/etc/hosts` вашей хост-системы:
```bash
echo "127.0.0.1 foreman.local" | sudo tee -a /etc/hosts
```

Управление контейнером:
```bash
docker-compose up
docker-compose down
docker-compose restart
docker-compose logs -f
docker-compose exec foreman bash
```
### Настройка FQDN
Чтобы использовать собственное доменное имя, нужно изменить переменную окружения в [`docker-compose.yml`](docker-compose.yml):
```yaml
environment:
  - FOREMAN_FQDN=your.domain.com
```

### Данные и персистентность
Данные сохраняются в volumes:
- `foreman_postgresql` - база PostgreSQL
- `foreman_config` - конфигурация Foreman
- `foreman_data` - данные приложения

Резервное копирование:
```bash
docker-compose exec foreman tar czf /tmp/foreman-backup.tar.gz /etc/foreman /var/lib/foreman
docker cp foreman:/tmp/foreman-backup.tar.gz ./foreman-backup.tar.gz
```

## Интересное
- На момент создания скрипта актуальная версия foreman - 13.7, соответственно она и ставится.  
- Как уже было сказано выше, foreman не в состоянии работать с версиями ruby и гемов из debian 13, они слишком свежи, чтобы подойти для зрелого продукта.  
- apt по умолчанию при доступности использует ipv6, но в ряде случаев скорость скачивания пакетов катастрофически падает, поэтому скрипт отключает ipv6.  
- Отдельная история - репо puppet, оттуда вообще ничего скачать невозможно ни через ipv6, ни через ipv4, скорость рандомно падает ниже 1 Кб/с и установка прерывается.  
Обход - скачать руками, закинуть в ВМ и установить:
```
https://apt.puppet.com/pool/bookworm/puppet8/p/puppet-agent/puppet-agent_8.10.0-1bookworm_amd64.deb  
https://apt.puppet.com/pool/bookworm/puppet8/p/puppetserver/puppetserver_8.7.0-1bookworm_all.deb  
```
В этом репозитории нужные пакеты уже лежат в assets.  
- postgres и redis ставятся из ванильных репозиториев debian, соотвественно не самые свежие версии, но они вполне достаточны для работы.  
