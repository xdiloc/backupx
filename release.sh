#!/bin/bash

NAME="backupx_linux_amd64"
OUT_DIR="out"

# @brief Проверяет наличие существующего архива, запрашивает подтверждение на его удаление
# и возвращает статус (0 - файл удален или отсутствует, 1 - файл существует и не был удален)
# $1 - путь к проверяемому файлу
check_and_remove_existing() {
	local archive_path="$1"

	if [ -e "$archive_path" ]; then
		echo "Удалить архив $NAME?"
		find "$OUT_DIR" -maxdepth 1 -type f -name "$(basename "$archive_path")" -ok rm {} \;

		# Если после проверки файл все еще на месте (пользователь ответил 'n' или прервал), возвращаем ошибку
		if [ -e "$archive_path" ]; then
			return 1
		else
			echo "Старый архив успешно удален."
		fi
	fi
	return 0
}

# @brief Создает ZIP-архив с исполняемым файлом, документацией и папкой ресурсов
# $1 - полный путь к архиву с расширением
create_release_zip() {
	local archive_path="$1"
	echo "Пакуем файлы в архив..."
	# Флаг -j убирает пути для файлов, -r сохраняет папку asset
	zip -j "$archive_path" "$OUT_DIR/backupx" README.md LICENSE
	zip -r "$archive_path" asset
	echo "Готово: $archive_path"
}

main() {
	local archive="$OUT_DIR/$NAME.zip"

	# Проверяем и удаляем старый архив перед созданием нового
	if ! check_and_remove_existing "$archive"; then
		echo "Ошибка: старый архив не был удален, создание нового релиза отменено."
		exit 1
	fi

	# Создаем новый релиз
	create_release_zip "$archive"
}

main
