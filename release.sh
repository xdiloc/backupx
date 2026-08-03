#!/bin/bash

NAME="backupx_linux_amd64"

# Флаг -j убирает пути для основных файлов (они упаковываются в корень),
# а папку asset добавляем через -r (она сохранится как папка asset/ в архиве)
zip -j out/$NAME.zip out/backupx README.md LICENSE
zip -r out/$NAME.zip asset

echo "Готово: out/$NAME.zip"
