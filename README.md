# Установка foreman в lxc контейнер на debian
lxc используется в Proxmox в качестве системы конейнеризации по умолчанию и предоставляет возможность использования контейнеров с максимально привычным походом к администрированию.
Скрипт также подойдет для установки на хост, в этом случае можно удалить код с модификацией /etc/hosts.
Для установки в docker можно использовать официальный docker-compose

## Требования
Контейнер:  
- Привилегированный, либо должна быть включена опция keyctl
- debian 12 (не 13, там слишком свежий ruby)
- 4 ядра (min 2)
- 8 ГБ ОЗУ (min 4)
- опции: keyctl, nesting  

Для proxmox до 9 дополнительно в конфиг (/etc/pve/nodes/$(hostname)/lxc/<id>.conf) добавить:
```
lxc.apparmor.profile = unconfined
lxc.cgroup.devices.allow = a
lxc.cap.drop =
```

## Установка
Запустить с повышенными правами:
```bash
apt install git -y
git clone https://github.com/rsyuzyov/foreman-setup.git
cd foreman-setup
chmod +x foreman-setup.sh
./foreman-setup.sh
```

## Примечания
- На момент создания скрипта актуальная версия foreman - 13.7, соответственно она и ставится.  
- Как уже было сказано выше, foreman не в состоянии работать с версиями ruby и гемов из debian 13, они слишком свежи, чтобы подойти для зрелого продукта.  
- Отдельная история - репо puppet, оттуда вообще ничего скачать невозможно ни через ipv6, ни через ipv4, скорость рандомно падает ниже 1 Кб/с и установка прерывается.  
Обход - скачать руками, закинуть в ВМ и установить:
```
https://apt.puppet.com/pool/bookworm/puppet8/p/puppet-agent/puppet-agent_8.10.0-1bookworm_amd64.deb  
https://apt.puppet.com/pool/bookworm/puppet8/p/puppetserver/puppetserver_8.7.0-1bookworm_all.deb  
```
В этом репозитории нужные пакеты уже лежат в assets.  
- postgres и redis ставятся из ванильных репозиториев debian, они вполне достаточны для работы.

