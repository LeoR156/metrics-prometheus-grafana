# Automated Monitoring Stack
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

### ☁️ Infrastructure-as-Code проект для автоматического развертывания кластера мониторинга с нуля. Позволяет за 5 минут поднять сервера в облаке и накатить на них метрики.

### Стек :hammer_and_wrench: :
* :building_construction: Terraform v1.16.2 on linux_amd64 - для создания ВМ в облаке Yandex Cloud.
* :rocket: ansible [core 2.20.1] - для автоматической установки нужных компонентов и накатки конфигураций.
* :whale: docker - для изоляции сервисов и запуска на любых машинах.
* :memo: prometheus и node exporters - для опроса и получения метрик с целевых серверов.
* :bar_chart: grafana - для красивой визуализации данных.

***

## Краткая архитектура 💡
* Главный сервер (general_server): настраивается вручную, вписывается первым под группой `servers` в inventory-файл и настраивается в файле **general_server.yml**, который должен быть расположен в папке **host_vars**.
* Terraform идёт в облако Yandex Cloud и поднимает нужное количество серверов (настраивается в файле **variable.tf**). После развертывания серверов создает inventory-файл с настройками каждой машины в папке **host_vars**, чтобы запустить плейбук можно было без ручного ввода.
* Ansible получает готовую конфигурацию и идёт на general_server, чтобы поднять три контейнера: prometheus, grafana и alertmanager. Он динамически подставляет переменные из папки **group_vars**, чтобы контейнеры получили готовую конфигурацию. Затем он идёт на остальные сервера, ставит node_exporter с официального репозитория на GitHub, настраивает systemd-службу и автозапуск.

## Безопасность 🔒:
* Пароли и логины хранятся в папке **group_vars** в файле **vault.yml**, который, в свою очередь, зашифрован мастер-паролем хранилища Ansible Vault.
* Сразу настраивается basic_auth на всех сервисах: Grafana, Node_Exporters.
* Стейт Terraform и ключи игнорируются Git.
* Подключение к серверам идёт строго по SSH-ключам.

***

## Быстрый старт 🚀:
### Вам понадобится:
* Аккаунт Yandex Cloud с ключами. Можно получить тут: <a href="https://console.yandex.cloud" target="_blank" rel="noopener noreferrer">Консоль Yandex Cloud</a>. Поместите ключи в папку **terraform-infra**.
* Операционная система Linux с установленной на ней terraform, ansible и git. Команда для установки (работает на Ubuntu и Debian): `sudo apt update && sudo apt install -y ansible terraform git`
* Токен вашего телеграмм бота и ваш личный ID. Можно получить здесь: [BotFather](https://t.me/BotFather). ID можно узнать здесь: [Get ID](https://t.me/userinfobot).
#### Не обязательно:
* Домен для получения ssl сертификата.

***
### Конкретные действия для развёртывания:
* Клонируйте и перейдите в скачанный репозиторий командой: `git clone https://github.com/LeoR156/metrics-prometheus-grafana && cd metrics-prometheus-grafana/group_vars/all/`
* Откройте файл **vault.yml** и сотрите содержимое командой: `> vault.yml && nano vault.yml`.
* Напишите туда ваши реальные данные по шаблону c сохранением кавычек:
```yaml
grafana_admin_user: "ваш_логин_для_grafana"
grafana_admin_password: "ваш_пароль_для_grafana"

prom_admin_user: "ваш_логин_для_prometheus"
prom_admin_password: "ваш_пароль_для_prometheus"

exporter_user: "ваш_логин_для_exporters"
exporter_password: "ваш_пароль_для_exporters"

domain: "ваш_домен" # Удалите строку, если нет.
email: "ваш_email"

telegram_bot_token: "токен_вашего_бота"
telegram_chat_id: "ваш_телеграм_id"
```
* Примените изменения: `Ctrl + X`, `Y` и `Enter`.
* Желательно применить шифрование командой: `ansible-vault encrypt vault.yml`. Придумайте и введите пароль. 
  ⚠️ **Важно:** *Если шифруете, то запомните пароль, иначе для его просмотра нужно будет расшифровать файл командой `ansible-vault decrypt <путь_и_имя_файла>`*.
* Вернитесь на две папки выше командой `cd ../..` и перейдите в папку **host_vars** командой `cd host_vars/`. Создайте файл **general_server.yml** и введите туда данные командой `nano general_server.yml` (**с сохранением кавычек**):
```yaml
ansible_host: "ваш_IP_главного_сервера"
ansible_user: "ваш_юзер"
ansible_ssh_private_key_file: "путь_до_ssh_ключа"
```
* Примените изменения: `Ctrl + X`, `Y` и `Enter`.
* Переместитесь в папку **terraform-infra** командами: `cd .. && cd terraform-infra/`
  ⚠️ **Убедитесь, что файл с ключами Яндекса находится именно в этой папке!**
* Скачайте плагины провайдера командой `terraform init`. Дождитесь полной загрузки. По окончании убедитесь, что установка прошла корректно (сообщение `Terraform has been successfully initialized!`).
* Выполните команду `terraform plan`, чтобы предварительно ознакомиться с изменениями. Затем команду `terraform apply`, чтобы применить изменения (нужно ввести `yes`). Дождитесь, пока Terraform закончит свою работу.
* Вернитесь в корень проекта командой `cd ..` и запустите плейбук командой: `ansible-playbook -i terraform-infra/inventory.ini playbook.yml --ask-vault-pass` *(введите пароль, если задавали его ранее)*.
* Пару-тройку минут — и Ansible сделает свою работу!

### Подключение и первый дашборд:
* Зайдите на IP главного сервера, порт 3001. Шаблон: `http://<IP_general_server>:3001`. **Важно:** Если указывали домен, то переходите прямо на него.
* Введите логин и пароль от Grafana, который вы задавали ранее в файле **vault.yml**.
* Зайдите на вкладку **Dashboards** слева экрана > нажмите **New** справа > нажмите **Import dashboard** > вставьте ID `1860` и нажмите **Load** > затем снова **Import**.

#### Готово! Метрики настроены.

***

# Планы дальнейшего развития проекта:
* ~~Разбить таски по ролям Ansible.~~ > сделано :white_check_mark:
* ~~Добавить возможность получения SSL-сертификата ради безопасного HTTPS соединения.~~ > сделано :white_check_mark:
* ~~Прикрутить Alertmanager + Telegram Notifications.~~ > сделано :white_check_mark:
