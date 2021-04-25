# PSRemoteRegistry
Форк этого проекта: https://github.com/kunaludapi/Powershell-remote-registry

## Удалённая работа с реестром в PowerShell

### Минимальные требования:
- Версия PowerShell - 5.1
- ОС - Windows 10
- [tcping.exe](https://elifulkerson.com/projects/tcping.php) 0.39 или выше

### Установка
- Качаем себе архив релиза и распаковываем в любое место
- Качаем прогу tcping.exe [отсюда](https://elifulkerson.com/projects/tcping.php) и сохраняем её в C:\Windows или C:\Windows\System32 (это нужно что бы не искать её и не писать полный путь к ней), либо куда угодно и добавляем папку с ней у переменной PATH. Не забываем снять признак того что файл был скачан из инета, например такой коммандой:
```powershell
Unblock-File -Path 'путь_к_файлу'
```
- Добавляем с своему скрипту путь до нужной функции:
```powershell
. 'Путь_к_нужной_функции.ps1'
```
- Когда научусь сделаю NuGet пакет, но не сейчас :)