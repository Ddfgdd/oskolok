# Осколок

Сборка Minecraft на двоих: скайблок, тех-автоматизация и RPG (боссы, измерения, магия).
Minecraft 1.21.1, NeoForge 21.1.266, около 400 модов. Формат пака — CurseForge.

План сборки: https://claude.ai/artifact/1T2aT8rVHVucCijYj2queh

## Как установить

1. Скачай `Oskolok-<версия>.zip` со страницы **Releases** этого репозитория.
2. В CurseForge App открой Minecraft → **Create Custom Profile** → **Import** и выбери скачанный zip.
   Моды CurseForge скачает сам, в архиве только их список.
3. В настройках профиля выдели 10 ГБ памяти (минимум 8 ГБ).
4. Запускай. Первая загрузка идёт несколько минут.

Версия 0.1.0 — тестовая: проверяем, что все моды запускаются вместе.
Квестов, рецептов и стартового острова в ней ещё нет.

## Если не запускается

Пришли окно с ошибкой и файл `logs/latest.log` из папки профиля
(CurseForge App → правой кнопкой по профилю → Open Folder).
Если игра упала — ещё файл из папки `crash-reports`.

## Что в репозитории

| Путь | Что это |
| --- | --- |
| `modlist.csv` | Мод-лист с категориями и версиями |
| `build/cf-ids.txt` | ID проекта и файла каждого мода на CurseForge |
| `build/build-pack.ps1` | Скрипт сборки пака |
| `build/manifest.json` | Манифест CurseForge последней сборки |
| `build/modlist-cf.csv` | Что попало в манифест |
| `build/overrides/` | Конфиги и файлы, которые идут поверх модов |

Пересборка: `powershell -ExecutionPolicy Bypass -File build/build-pack.ps1 -Version 0.1.1`
