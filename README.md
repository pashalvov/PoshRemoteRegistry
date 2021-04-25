# PSRemoteRegistry
Форк этого проекта: https://github.com/kunaludapi/Powershell-remote-registry

## Удалённая работа с реестром в PowerShell

### Минимальные требования:
- Версия PowerShell - 5.1
- ОС - Windows 10
- [tcping.exe](https://elifulkerson.com/projects/tcping.php) 0.39 или выше

### Установка
- Качаем себе архив релиза и распаковываем в любое место
- Качаем прогу tcping.exe [отсюда](https://elifulkerson.com/projects/tcping.php) и сохраняем её в C:\Windows или C:\Windows\System32 (это нужно что бы не искать её и не писать полный путь к ней), либо куда угодно и добавляем папку с ней у переменной PATH. Не забываем снять признак того что файл был скачан из инета, например такой коммандой `Unblock-File -Path 'путь_к_файлу'`
- Добавляем с своему скрипту путь до нужной функции ` 'Путь_к_нужной_функции.ps1'`
- Когда научусь сделаю NuGet пакет, но не сейчас :) Или уже научился - [PoshRemoteRegistry](https://www.powershellgallery.com/packages/PoshRemoteRegistry)

### Примеры использования

[PSRemoteRegistry_Examples.ps1](https://raw.githubusercontent.com/pashalvov/PSRemoteRegistry/master/%D0%9F%D1%80%D0%B8%D0%BC%D0%B5%D1%80%D1%8B/PSRemoteRegistry_Examples.ps1)

```powershell
Clear-Host

Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Filter '*.ps1' -File | ForEach-Object {. $_.FullName}

# Укажи для начала имя машины, или массив через запятую
$ComputerName = 'имя_компа'
$RegistryKeyPath = 'SOFTWARE\WOW6432Node\PSRemoteRegistry'
$ValueName = 'ModuleName'
$ValueData = 'PSRemoteRegistry'

# Создание раздела реестра
Write-RegValue -ComputerName $ComputerName -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\' -ChildKey 'PSRemoteRegistry'

# Создание ключа с типом String
Write-RegValue -ComputerName $ComputerName -RegistryHive LocalMachine -RegistryKeyPath $RegistryKeyPath -ValueType String -ValueName $ValueName -ValueData $ValueData

# Создание ключа с типом DWORD
$ValueName = 'Installed'
$ValueData = 1
Write-RegValue -ComputerName $ComputerName -RegistryHive LocalMachine -RegistryKeyPath $RegistryKeyPath -ValueType DWord -ValueName $ValueName -ValueData $ValueData

# Изменение значения ключа
$ValueName = 'Installed'
$ValueData = 0
Write-RegValue -ComputerName $ComputerName -RegistryHive LocalMachine -RegistryKeyPath $RegistryKeyPath -ValueType DWord -ValueName $ValueName -ValueData $ValueData

# Удаление ключа
Remove-RegKeyValue -ComputerName $ComputerName -RegistryHive LocalMachine -RegistryKeyPath $RegistryKeyPath -ValueName $ValueName

# Удаление раздела с ключом внутри
Remove-RegKeyValue -ComputerName $ComputerName -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\' -ChildKey 'PSRemoteRegistry'

# Замер скорости работы при получении списка ПО из реестра
[timespan]$Measures = (Measure-Command {Get-InstalledSoftwareInfo -ComputerName $ComputerName})
Write-Host ("Получения списка ПО выполнено за {0:c}" -f $Measures)
```