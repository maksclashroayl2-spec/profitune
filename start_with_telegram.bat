@echo off
REM Впиши сюда свои данные и сохрани файл.
REM После этого просто запускай его двойным кликом вместо "python app.py".

REM --- Telegram-бот (необязательно) ---
set TELEGRAM_BOT_TOKEN=ВПИШИ_СЮДА_ТОКЕН
set TELEGRAM_BOT_USERNAME=ВПИШИ_СЮДА_USERNAME_БОТА

REM --- Почта для кода подтверждения при регистрации (необязательно) ---
REM Если оставить пустым — подтверждение почты отключено, регистрация
REM работает как раньше. Пример для Яндекс.Почты: SMTP_HOST=smtp.yandex.ru, порт 465.
REM Пример для Mail.ru: SMTP_HOST=smtp.mail.ru, порт 465.
REM SMTP_USER и SMTP_PASSWORD — обычно нужен отдельный "пароль приложения",
REM не тот же пароль, что от самого почтового ящика (см. настройки безопасности
REM вашего почтового сервиса).
set SMTP_HOST=
set SMTP_PORT=465
set SMTP_USER=
set SMTP_PASSWORD=
set SMTP_FROM_EMAIL=

REM --- Секретный ключ сайта (обязательно для боевого запуска) ---
REM Сгенерировать: python -c "import secrets; print(secrets.token_hex(32))"
REM Без этой переменной сайт всё равно запустится, но при каждом
REM перезапуске будет разлогинивать всех пользователей.
set SECRET_KEY=

REM --- Мониторинг ошибок (необязательно) ---
REM Ошибки и без этого пишутся в instance/logs/app.log. Если хотите ещё и
REM уведомления (почта/Slack) — заведите бесплатный проект на sentry.io,
REM оттуда возьмите DSN (Settings -> Client Keys) и впишите сюда.
set SENTRY_DSN=

python app.py
pause
