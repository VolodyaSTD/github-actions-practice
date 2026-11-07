#!/usr/bin/env bash
# Тест 1: приложение работает и подключено к БД
set -euo pipefail

# Загружаем переменные из .env (APP_PORT, DB_USER и другие)
set -a
source .env
set +a

BASE_URL="http://localhost:${APP_PORT}"
echo "Адрес приложения: $BASE_URL"

echo " Ждём запуска приложения "
for i in $(seq 1 30); do
  if curl -s -o /dev/null "$BASE_URL/health"; then
    echo "Приложение отвечает"
    break
  fi
  echo "Ещё не готово, попытка $i из 30"
  sleep 2
done

echo " Проверка 1: подключение к базе данных "
HEALTH=$(curl -sS "$BASE_URL/health" || true)
echo "Ответ /health: $HEALTH"

if echo "$HEALTH" | grep -q '"database":"connected"'; then
  echo " Приложение работает и подключено к БД"
else
  echo " Приложение не может подключиться к БД"
  exit 1
fi

echo " Проверка 2: API отдаёт данные из БД "
API_COUNT=$(curl -sS "$BASE_URL/api/items/count" || true)
echo "API вернул записей: $API_COUNT"

if [[ "$API_COUNT" =~ ^[0-9]+$ ]] && [ "$API_COUNT" -gt 0 ]; then
  echo " API возвращает данные из БД"
else
  echo " API вернул некорректный ответ"
  exit 1
fi
