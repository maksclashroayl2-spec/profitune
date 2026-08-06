# Разворачивание ProfiTutors на боевом сервере

Инструкция рассчитана на чистый Ubuntu 22.04/24.04 (стандартный образ
у Timeweb Cloud, REG.RU, Selectel — везде одинаково после того, как
сервер создан). Выполняется по порядку, сверху вниз.

Везде, где встречается `your-domain.ru` — замените на свой настоящий домен.
Везде, где встречается `1.2.3.4` — замените на IP-адрес вашего сервера
(показывается в панели хостинга сразу после создания сервера).


## Шаг 0. Купить сервер и домен

1. Зарегистрируйтесь у выбранного хостера (например, Timeweb Cloud).
2. Закажите VPS: Ubuntu 22.04 или 24.04, 1-2 vCPU, 2 ГБ RAM, 20-30 ГБ NVMe.
3. Купите домен .ru (у того же хостера или на REG.RU).
4. В настройках домена (DNS) добавьте A-запись:
   - Тип: A, Хост: @, Значение: IP-адрес вашего сервера.
   - Тип: A, Хост: www, Значение: тот же IP-адрес.
   DNS обновляется не мгновенно — может занять от 10 минут до нескольких часов.


## Шаг 1. Первый вход на сервер

С компьютера (Windows — через PowerShell, оно поддерживает ssh из коробки):

```
ssh root@1.2.3.4
```

Хостер пришлёт пароль root на почту при создании сервера.

Обновляем систему и ставим всё необходимое:

```bash
apt update && apt upgrade -y
apt install -y python3 python3-venv python3-pip nginx certbot python3-certbot-nginx git ufw
```


## Шаг 2. Отдельный пользователь для сайта

Запускать сайт от root — плохая идея. Создаём отдельного пользователя:

```bash
adduser --system --group --home /opt/profitutors profitutors
mkdir -p /opt/profitutors
chown profitutors:profitutors /opt/profitutors
```


## Шаг 3. Загрузить файлы проекта на сервер

Проще всего — с локального компьютера через `scp` (замените путь к архиву
на свой):

```powershell
scp profischool_v25.zip root@1.2.3.4:/opt/profitutors/
```

На сервере распаковываем — файлы лягут в `/opt/profitutors/profischool_app/`:

```bash
cd /opt/profitutors
apt install -y unzip
unzip profischool_v25.zip
rm profischool_v25.zip
chown -R profitutors:profitutors /opt/profitutors
```


## Шаг 4. Виртуальное окружение Python и зависимости

```bash
su - profitutors -s /bin/bash
cd /opt/profitutors/profischool_app
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
exit
```


## Шаг 5. Настроить переменные окружения

```bash
su - profitutors -s /bin/bash
cd /opt/profitutors/profischool_app
cp deploy/.env.example .env
nano .env
```

Впишите как минимум `SECRET_KEY` (сгенерировать: `python3 -c "import secrets; print(secrets.token_hex(32))"`).
Остальное (Telegram, почта, Sentry) — по желанию, можно дозаполнить позже
и просто перезапустить сервис.

Сохранить в nano: `Ctrl+O`, `Enter`, выйти: `Ctrl+X`.

```bash
exit
```


## Шаг 6. Проверка вручную перед автозапуском

Прежде чем настраивать systemd, стоит один раз запустить руками
и убедиться, что ничего не падает:

```bash
su - profitutors -s /bin/bash
cd /opt/profitutors/profischool_app
set -a; source .env; set +a
.venv/bin/python app.py
```

Если видите `Запуск через waitress на http://0.0.0.0:5000` — всё хорошо,
жмите `Ctrl+C` и продолжайте. Если видите ошибку — читайте текст ошибки,
это почти всегда опечатка в `.env` или не установленная зависимость.

```bash
exit
```


## Шаг 7. Автозапуск через systemd

```bash
cp /opt/profitutors/profischool_app/deploy/profitutors.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable profitutors
systemctl start profitutors
systemctl status profitutors
```

В выводе `status` должно быть зелёное `active (running)`. Если нет —
смотрите логи:

```bash
journalctl -u profitutors -n 50
```


## Шаг 8. Nginx — реверс-прокси и HTTPS

```bash
cp /opt/profitutors/profischool_app/deploy/nginx_profitutors.conf /etc/nginx/sites-available/profitutors
nano /etc/nginx/sites-available/profitutors
```

Замените в файле `your-domain.ru` на свой настоящий домен (два места),
сохраните.

```bash
ln -s /etc/nginx/sites-available/profitutors /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
```

`nginx -t` должен сказать `syntax is ok` и `test is successful` —
если есть ошибка, конфиг не подхватится, читайте текст ошибки.

На этом этапе сайт уже должен открываться по адресу
`http://your-domain.ru` (пока без замочка HTTPS).


## Шаг 9. Бесплатный SSL-сертификат

```bash
certbot --nginx -d your-domain.ru -d www.your-domain.ru
```

Введите email для уведомлений об истечении сертификата, согласитесь
с условиями. Certbot сам допишет нужные строки в конфиг nginx и настроит
автопродление сертификата (раз в 90 дней, без вашего участия).

Проверьте: `https://your-domain.ru` должен открываться с замочком.


## Шаг 10. Firewall

Закрываем всё, кроме SSH и веб-трафика — порт 5000 наружу быть виден
не должен вообще, только через nginx:

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
```

На вопрос про подтверждение — `y`.


## Шаг 11. Финальная проверка

- [ ] Сайт открывается по `https://your-domain.ru` с замочком
- [ ] Регистрация нового аккаунта работает
- [ ] Если настроили почту — код подтверждения приходит
- [ ] Если настроили Telegram-бота — уведомления работают
- [ ] Вход под админом работает, все разделы открываются
- [ ] `sudo systemctl status profitutors` — активен
- [ ] Перезагрузите сервер (`sudo reboot`) и через минуту проверьте,
      что сайт поднялся сам, без вашего участия


## Как потом обновлять сайт (когда я пришлю новую версию)

```bash
su - profitutors -s /bin/bash
cd /opt/profitutors/profischool_app
# загрузите новый app.py и папку templates/ поверх старых (через scp),
# instance/ и .env НЕ трогайте — там ваша база и настройки
.venv/bin/pip install -r requirements.txt   # если появились новые зависимости
exit
sudo systemctl restart profitutors
```


## Если что-то не работает

```bash
sudo systemctl status profitutors        # запущен ли сервис
sudo journalctl -u profitutors -n 100    # последние 100 строк лога сервиса
sudo tail -f /opt/profitutors/profischool_app/instance/logs/app.log   # логи самого приложения
sudo nginx -t                            # проверка конфига nginx
sudo systemctl status nginx              # запущен ли nginx
```
