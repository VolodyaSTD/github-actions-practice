#!/usr/bin/env bash
# Тест 2: данные в БД совпадают с тем, что показывает сайт
set -euo pipefail

set -a
source .env
set +a

BASE_URL="http://localhost:${APP_PORT}"
mkdir -p artifacts

# Функция: выполнить SQL-запрос в контейнере с базой
psql_db() {
  docker-compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -At -c "$1"
}

echo "Проверка функции: в таблице items $(psql_db 'SELECT COUNT(*) FROM items;') записей"

echo " Проверка 1: количество записей "
DB_COUNT=$(psql_db "SELECT COUNT(*) FROM items;")
WEB_COUNT=$(curl -s "$BASE_URL/" | sed -n 's/.*<span id="items-count">\([0-9]*\)<\/span>.*/\1/p')
echo "Записей в БД: $DB_COUNT"
echo "Записей на сайте: $WEB_COUNT"

if [ "$DB_COUNT" = "$WEB_COUNT" ]; then
  echo " Количество совпадает"
else
  echo " Количество не совпадает"
  exit 1
fi

echo " Проверка 2: содержимое таблицы "
# Из БД: строки вида "1|Ноутбук"
psql_db "SELECT id || '|' || name FROM items ORDER BY id;" > artifacts/db-items.txt

# С сайта: достаём из HTML такие же строки "1|Ноутбук"
curl -s "$BASE_URL/" \
  | sed -n 's/.*<tr class="item" data-id="\([0-9]*\)">.*<td class="name">\([^<]*\)<\/td>.*/\1|\2/p' \
  > artifacts/web-items.txt

echo "--- Из БД ---"
cat artifacts/db-items.txt
echo "--- С сайта ---"
cat artifacts/web-items.txt

if diff artifacts/db-items.txt artifacts/web-items.txt; then
  echo " Данные в БД и на сайте совпадают"
else
  echo " Данные различаются (< из БД, > с сайта)"
  exit 1
fi

echo " Проверка 3: новая запись из БД появляется на сайте "
TEST_NAME="Проверка-${GITHUB_RUN_ID:-local}"
NEW_ID=$(psql_db "INSERT INTO items (name, price) VALUES ('$TEST_NAME', 1) RETURNING id;" | head -n1)
echo "Добавили в БД запись id=$NEW_ID: $TEST_NAME"

curl -s "$BASE_URL/" > artifacts/page-after-insert.html
psql_db "DELETE FROM items WHERE id = $NEW_ID;" > /dev/null
echo "Тестовая запись удалена из БД"

if grep -q "$TEST_NAME" artifacts/page-after-insert.html; then
  echo " Новая запись появилась на сайте"
else
  echo " Новой записи нет на сайте"
  exit 1
fi

echo "- Тест 2 (БД = сайт):  PASSED, $DB_COUNT записей совпадают, новая запись отображается" >> artifacts/test-report.md
echo "Результат записан в artifacts/test-report.md"
