Clear-Host

Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Filter '*.ps1' -File | ForEach-Object {. $_.FullName}

$ComputerName = 'LEVIK888'
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