# PoshRemoteRegistry
Форк этого проекта: https://github.com/kunaludapi/Powershell-remote-registry

## Удалённая работа с реестром в PowerShell

### Минимальные требования:
- Версия PowerShell - 5.1
- ОС - Windows 10

### Установка:
```powershell
Install-Module -Name PoshRemoteRegistry -AllowPrerelease
Import-Module PoshRemoteRegistry
```

### Примеры использования:

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