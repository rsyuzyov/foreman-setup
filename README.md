# Установка foreman в lxc контейнер на debian
lxc используется в Proxmox в качестве системы конейнеризации по умолчанию и предоставляет возможность использования контейнеров с максимально привычным походом к администрированию - контейнер выглядит как обычная ОС, но дает все преимущества контейнеризации, такие как мгновенный запуск и почти нулевые накладные расходы.  
Скрипт также подойдет для установки на хост.  
Для установки в docker можно использовать официальный [docker-compose](https://github.com/theforeman/foreman/blob/develop/docker-compose.yml)  

## Требования
Контейнер:  
- Привилегированный, либо должна быть включена опция keyctl
- debian 12 (не 13, там слишком свежий ruby)
- 4 ядра (min 2)
- 8 ГБ ОЗУ (min 4)
- опции: keyctl, nesting  

## Установка
Запустить с повышенными правами:
```bash
apt update -y
apt install git -y
git clone https://github.com/rsyuzyov/foreman-setup.git
cd foreman-setup
chmod +x foreman-setup.sh
./foreman-setup.sh
cd ..
```
После окончания установки в консоли будут написаны адрес, логин и пароль для входа в интерфейс:
- адрес: https://hostname
- логин: admin
- пароль: changeme

### Параметры и примеры использования
Установка версии по умолчанию (3.17) без проверок:
```bash
./foreman-setup.sh
```

Установка версии 3.16 с проверками:
```bash
./foreman-setup.sh -v 3.16 -check
```

Использование внешнего сервера PostgreSQL:
```bash
./foreman-setup.sh -pghost srv-db -pglogin postgres -pgpass yourpwd
```

Использование внешнего сервера Redis:
```bash
./foreman-setup.sh -redishost srv-redis -redispass yourpwd
```

## Примечания
### Репозиторий puppet
Весьма странная история: при установке пакетов скорость рандомно падает ниже 1 Кб/с и установка прерывается, хоть через ipv6, хоть через ipv4.  
Обход: скачать руками, закинуть в ВМ и установить:  
```
https://apt.puppet.com/pool/bookworm/puppet8/p/puppet-agent/puppet-agent_8.10.0-1bookworm_amd64.deb  
https://apt.puppet.com/pool/bookworm/puppet8/p/puppetserver/puppetserver_8.7.0-1bookworm_all.deb  
```
В этом репозитории нужные пакеты уже лежат в assets.  
### Postgres и Redis
Ставятся из ванильных репозиториев debian, вполне достаточны для работы.

