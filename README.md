# Automated Monitoring Stack
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)



### Infrastructure-as-Code проект для автоматического развертывания кластера мониторинга с нуля. Позволяет за 5 минут поднять сервера в облаке и накатить на них метрики.

### Стек :hammer_and_wrench::
* :building_construction: __terraform Terraform v1.16.2 on linux_amd64 - для создания ВМ в облаке Yandex Cloud.__
* :rocket: __ansible [core 2.20.1] - для автоматической установки нужных компонентов и накатки конфигураций.__
* :whale: __docker - для изоляции сервисов и запуске на любых машинах.__
* :memo: __prometheus и node exporters - для опроса и получения метрик с целевых серверов.__
* :bar_chart: __grafana - для красивой визуализации данных.__

***

## __Краткая архитектура__ 💡
* Главный сервер (general_server): настраивается в ручную, вписывается первым под группой ` servers ` в inventory и настраивается в файле ` general_server `, который должен быть расположен в папке `host_vars`.
* terraform идёт в облако Yandex Cloud и поднимает нужное количество серверов (настраивается в variable.tf). После развертывания серверов создает inventory файл с настройками каждой машины в папке `host_vars`, чтобы запустить плейбук можно было без ручного ввода.
* Ansible получает готовую конфигурацию и идёт на `general_server`, чтобы поднять два контейнера: __prometheus и grafana__. Он динамически подставляет переменные из папки `group_vars`, чтобы контейнеры получили готовую конфигурацию. Затем он идёт на остальные сервера, ставит `node_exporter` с официального репозитория на GitHub, настраивает __systemd__ службу и автозапуск.

## Безопасность :lock::
* Пароли и логины хранятся в папке `group_vars` в файле `vault.yml`, который в свою очередь зашифрован мастер-паролем хранилища __vault Ansible__.
* Сразу настраивается __basic_auth__ на всех сервисах: Grafana, Ansible, Node_Exporters
* Стейт terraform и ключи __игнорируются__ git.
* Подключение к серверам идёт строго по __ssh ключам__.

  ***

## Быстрый старт:
### Вам понадобится:
* Аккаунт Yandex Cloud с ключами. Можно получить тут: <a href="https://console.yandex.cloud" target="_blank" rel="noopener noreferrer">Консоль Yandex Cloud</a>. Поместите ключи в папку `terraform-infra/`
* Операционная система Linux с установленной на ней terraform, ansible и git. Команды для установки (__работает на: ubuntu и debian__): 'sudo apt update && sudo apt install -y ansible terraform git'

### Конкретные действия для развёртывания:
* Клонируйте и перейдите в скачанный репозиторий командой `git clone https://github.com/LeoR156/metrics-prometheus-grafana && cd metrics-prometheus-grafana/group_vars/all/`
* Откройте `vault.yml` и сотрите содержимое. Команда `> vault.yml && nano vault.yml`.
* Напишите туда ваши реальные данные по шаблону c сохранением кавычек:
```
grafana_admin_user: "ваш_логин_для_grafana"
grafana_admin_password: "ваш_пароль_для_grafana"

prom_admin_user: "ваш_логин_для_prometheus"
prom_admin_password: "ваш_пароль_для_prometheus"

exporter_user: "ваш_логин_для_exportes"
exporter_password: "ваш_пароль_для_exporters"

```
* Примените изменения: `ctrl + x`, `y` и `enter`
* Желательно применить шифрование, команда: `ansible-vault encrypt vault.yml`. Придумайте и введите пароль. ⚠️: __Если шифруете, то запомните пароль, иначе для просмотра нужно будет расшифровать файл командой: `ansible-vault decrypt <путь_и_имя_файла>` __
* Вернитесь на две папки выше командой `cd ../..` и перейдите в папку `host_vars` командой `cd host_vars/`. Создайте файл `general_server.yml` и введите туда данные командой `nano general_server.yml`. (__с сохранением кавычек__)
```
ansible_host: "ваш_IP_главного_сервера"
ansible_user: "ваш_юзер"
ansible_ssh_private_key_file: "путь_до_ssh_ключа"
```
* Примените изменения: `ctrl + x`, `y` и `enter`
* Переместитесь в `terraform_infra` командами `cd .. && cd terraform-infra/`
* ⚠️: __Убедитесь, что файл с ключами яндекса находится именно в этой папке!__
* Скачайте плагины провайдера командой `terraform init`. Дождитесь полной загрузки. По окончании убедитесь, что установка прошла корректно: сообщение `Terraform has been successfully initialized!`
* `terraform plan` - предварительно ознакомиться с изменениями. `terraform apply` - команда применить измениня, нужно ввести __yes__. Дождитесь, пока terraform знакончит свою работу.
* Вернитесь в папку `metrics-prometheus-grafana командой `cd ..` и запустите плейбук командой `ansible-playbook -i terraform-infra/inventory.ini playbook.yml --ask-vault-pass`. __введите пароль, если задавали его ранее__
* #### Пару-тройку минут и ansible сделает свою работу

### Подключение и первый дашборд:
* Зайдите на IP general_server, порт 3001. Шаблон: `http://<IP_general_server>:3001`
* Введите логин и пароль от `grafana`, который вы задавали ранее в файле `vault.yml`
* Зайдите на вкладку `dashboards` слева экрана > нажмите `new` справа > нажмите `import dashboards` > вставьте ID 1860 и нажмите `load` > затем снова `import`.
#### Готово! Метрики настроены.


# Планы дальнейшего развитий проекта:
### * Разбить таски по ролям ansible.
### * Добавить возможность получения ssl сертификата ради безопасного https соединения.
### * Прикрутить алерт-менеджер + Telegram Notifications.


 


  
