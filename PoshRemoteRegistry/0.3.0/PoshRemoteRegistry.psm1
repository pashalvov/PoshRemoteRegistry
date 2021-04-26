# TODO Сделать выводы об ошибках, а не сообщения о них

<#
 .Synopsis
    Проверка доступности удалённой машины с помощью программы tcping.exe.

 .Description
    Проверка доступности проводится с помощью программы tcping.exe. По умолчанию достпность проверяется для порта TCP 135.

 .Parameter ComputerName
    Имя или IP адрес машины.

 .Parameter Port
    [НЕОБЯЗАТЕЛЬНО] По-умолчанию проверяться порт 135, но можно указать любой другой

 .Example
    # Проверить доступность машины по порту TCP135
    Test-TCPing -IPAddress 'имя_компа'

 .Example
    # Проверить доступность машины по порту TCP3389 (RDP)
    Test-TCPing -IPAddress 'имя_компа' -Port 3389

.Notes
    Wiki проекта: https://github.com/pashalvov/PSRemoteRegistry/wiki/%D0%94%D0%BE%D0%B1%D1%80%D0%BE-%D0%BF%D0%BE%D0%B6%D0%B0%D0%BB%D0%BE%D0%B2%D0%B0%D1%82%D1%8C
    Нашёл баг или хочешь доработку: https://github.com/pashalvov/PSRemoteRegistry/pulls
    Сайт проекта: https://github.com/pashalvov/PSRemoteRegistry
#>
function Test-TCPing
{
    param
    (
        # Укажи имя или IP адрес компьютера
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipelineByPropertyName = $True)]
        [Alias('ComputerName')]
        [string]$IPAddress = '127.0.0.1',
        # Укажи порт для проверки
        [Parameter(Mandatory = $false, Position=1, ValueFromPipelineByPropertyName = $True)]
        [string]$Port = "135"
    )

    if ($IPAddress -like '.') {$IPAddress = '127.0.0.1'}

    $TcpingOutput = & tcping -n 3 -w 0.5 -s -4 -c $IPAddress $Port

    foreach ($to in $TcpingOutput)
    {
        if ($to -like "*Port is open*")
        {
            return $true
        }
    }
    return $false
}

<#
.Synopsis
    Получение значений ключей в реестре для удалённых машин.

.Description
    Получаем значение ключей в реестре для удалённых машин. Использует .NET 4.5 и выше с помощью класса [Microsoft.Win32.RegistryKey].

.Parameter ComputerName
    Имя или IP адрес машин или одной машины. Если не указать то работа ведётся на локальной машине.

.Parameter RegistryHive
    Раздел реестра. Значение предопределены заранее: 'ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig'.

.Parameter RegistryKeyPath
    Путь к разделу в реестре. Не забываем экранировать, на всякий.

.Parameter ValueName
    Имя ключа для которого надо получить значение.

.Example
    # Получить значение в реестре
    Get-RegValueData -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion' -ValueName 'ProgramFilesDir'

.Notes
    Wiki проекта: https://github.com/pashalvov/PSRemoteRegistry/wiki/%D0%94%D0%BE%D0%B1%D1%80%D0%BE-%D0%BF%D0%BE%D0%B6%D0%B0%D0%BB%D0%BE%D0%B2%D0%B0%D1%82%D1%8C
    Нашёл баг или хочешь доработку: https://github.com/pashalvov/PSRemoteRegistry/pulls
    Сайт проекта: https://github.com/pashalvov/PSRemoteRegistry
    Это форк проекта: https://github.com/kunaludapi/Powershell-remote-registry
#>
function Get-RegValueData {
    [CmdletBinding(SupportsShouldProcess=$false,
        ConfirmImpact='Medium',
        HelpURI='https://github.com/pashalvov/PSRemoteRegistry/wiki')]
    Param
    (
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('C')]
        [String[]]$ComputerName,
        [Parameter(Position=1, Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [Alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',
        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('KeyPath')]
        [String]$RegistryKeyPath,
        [Parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [Alias('Value')]
        [String]$ValueName
    )
    Begin
    {
        # $RegistryRoot= "[{0}]::{1}"-f 'Microsoft.Win32.RegistryHive', $RegistryHive
        # try
        # {
        #     $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        # }
        # catch
        # {
        #     Write-Error "Incorrect Registry Hive mentioned, $RegistryHive does not exist"
        # }
    }
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            if (Test-TCPing -IPAddress $Computer)
            {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                $key = $reg.OpenSubKey($RegistryKeyPath)
                $Data = $key.GetValue($ValueName)
                $Obj = New-Object -TypeName PSObject
                $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                $Obj | Add-Member -Name RegistryValueName -MemberType NoteProperty -Value "$RegistryKeyPath\$ValueName"
                $Obj | Add-Member -Name RegistryValueData -MemberType NoteProperty -Value $Data
                return $Obj
            }
            else
            {
                Write-Error "Computer Name $Computer not reachable" -Category ConnectionError
            }
        }
    }
    End
    {
        # TODO Что это и нафига? Убрать до релиза
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}

<#
.Synopsis
    Получение списка разделов или списка ключей в разделе реестра удалённой машины.

.Description
    Получаем списки разделов или список ключей в разделе с типами этих значений на удалённых машинах. Вывод либо списка разделов, либо список ключей с дополнительной информацией.
    Рекурсия в текущей версии не поддерживается.

.Parameter ComputerName
    Имя или IP адрес машин или одной машины.

.Parameter RegistryHive
    Раздел реестра. Значение предопределены заранее: 'ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig'.

.Parameter RegistryKeyPath
    Путь к разделу в реестре. Не забываем экранировать, на всякий.

.Parameter Type
    Тип запроса. ChildKey - получить ключи внутри раздела, или ValueData - получить значение ключа.

.Example
    # Получить все значения в разделе реестра
    Get-RegChildItem -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath SOFTWARE\Microsoft\Windows\CurrentVersion\ -Type ValueData

.Example
    # Получить все подразделы в реестре
    Get-RegChildItem -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath SOFTWARE\Microsoft\Windows\CurrentVersion\ -Type ChildKey

.Notes
    Wiki проекта: https://github.com/pashalvov/PSRemoteRegistry/wiki/%D0%94%D0%BE%D0%B1%D1%80%D0%BE-%D0%BF%D0%BE%D0%B6%D0%B0%D0%BB%D0%BE%D0%B2%D0%B0%D1%82%D1%8C
    Нашёл баг или хочешь доработку: https://github.com/pashalvov/PSRemoteRegistry/pulls
    Сайт проекта: https://github.com/pashalvov/PSRemoteRegistry
    Это форк проекта: https://github.com/kunaludapi/Powershell-remote-registry
#>
function Get-RegChildItem
{
    [CmdletBinding(SupportsShouldProcess=$false,
    ConfirmImpact='Medium',
    HelpURI='https://github.com/pashalvov/PSRemoteRegistry/wiki',
    DefaultParameterSetName='GetValue')]
    Param
    (
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('C')]
        [String[]]$ComputerName,

        [Parameter(Position=1, Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [Alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',

        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('ParentKeypath')]
        [String]$RegistryKeyPath,

        [Parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('ChildKey', 'ValueData')]
        [String]$Type

    )
    Begin
    {
        # $RegistryRoot = "[{0}]::{1}"-f 'Microsoft.Win32.RegistryHive', $RegistryHive
        # try
        # {
        #     $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        # }
        # catch
        # {
        #     Write-Error "Incorrect Registry Hive mentioned, $RegistryHive does not exist"
        # }
    }
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            if (Test-TCPing -IPAddress $Computer)
            {
                try
                {
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                    $key = $reg.OpenSubKey($RegistryKeyPath, $true)
                }
                catch
                {
                    Write-Error "Check permissions on computer name $Computer, cannot connect registry"
                    Continue
                }
                if ($null -eq $key.GetSubKeyNames() -or $null -eq $key.GetValueNames()) {
                    Write-Error "Incorrect registry path on $computer"
                    Continue
                }
                switch ($Type)
                {
                    'ChildKey'
                    {
                        foreach ($ck in $key.GetSubKeyNames())
                        {
                            $obj = New-Object -TypeName PSObject
                            $obj | Add-Member -Name ComputerName -MemberType NoteProperty -Value $Computer
                            $obj | Add-Member -Name RegistryKeyPath -MemberType NoteProperty -Value "$RegistryHive\$RegistryKeyPath"
                            $obj | Add-Member -Name ChildKey -MemberType NoteProperty -Value $ck
                            return $obj
                        }
                        break
                    }
                    'ValueData'
                    {
                        foreach ($vn in $key.GetValueNames())
                        {
                            $obj = New-Object -TypeName PSObject
                            $obj | Add-Member -Name ComputerName -MemberType NoteProperty -Value $Computer
                            $obj | Add-Member -Name RegistryKeyPath -MemberType NoteProperty -Value "$RegistryHive\$RegistryKeyPath"
                            $obj | Add-Member -Name ValueName -MemberType NoteProperty -Value $vn
                            $obj | Add-Member -Name ValueData -MemberType NoteProperty -Value $key.GetValue($vn)
                            $obj | Add-Member -Name ValueKind -MemberType NoteProperty -Value $key.GetValueKind($vn)
                            return $obj
                        }
                        break
                    }
                }
            }
            else
            {
                Write-Error "Computer Name $Computer not reachable" -Category ConnectionError
            }
        }
    }
    End
    {
        # TODO Что это и нафига? Убрать до релиза
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}

<#
.Synopsis
    Удаление раздела рекурсивно или удаление ключа реестра на удалённой машине.

.Description
    Удаляет раздел со всеми! подразделами рекусрсивно на удалённой машине. Предупреждений не выводит, используйте с умом. Позволяет выбрать что именно хотите удалить, ключ или раздел.
    По умолчанию удаляет ключ.

.Parameter ComputerName
    Имя или IP адрес машин или одной машины.

.Parameter RegistryHive
    Раздел реестра. Значение предопределены заранее: 'ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig'.

.Parameter RegistryKeyPath
    Путь к разделу в реестре. Не забываем экранировать, на всякий.

.Parameter ChildKey
    Удалить раздел в реестре или...

.Parameter ValueName
    Удалить ключ в реестре.

.Example
    # Удалить ключ в реестре
    Remove-RegKeyValue -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\PSRemoteRegistry\' -ValueName 'Version'

.Example
    # Удалить раздел в реестре
    Remove-RegKeyValue -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\' -ChildKey 'PSRemoteRegistry'

.Notes
    Wiki проекта: https://github.com/pashalvov/PSRemoteRegistry/wiki/%D0%94%D0%BE%D0%B1%D1%80%D0%BE-%D0%BF%D0%BE%D0%B6%D0%B0%D0%BB%D0%BE%D0%B2%D0%B0%D1%82%D1%8C
    Нашёл баг или хочешь доработку: https://github.com/pashalvov/PSRemoteRegistry/pulls
    Сайт проекта: https://github.com/pashalvov/PSRemoteRegistry
    Это форк проекта: https://github.com/kunaludapi/Powershell-remote-registry
#>
function Remove-RegKeyValue
{
    [CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='https://github.com/pashalvov/PSRemoteRegistry/wiki',
    DefaultParameterSetName='DelValue')]
    Param
    (
        [Parameter(ParameterSetName = 'DelValue', Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'DelKey', Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('C')]
        [String[]]$ComputerName,

        [Parameter(ParameterSetName = 'DelValue', Position=1, Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'DelKey', Position=1, Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [Alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',

        [Parameter(ParameterSetName = 'DelValue', Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'DelKey', Position=2, ValueFromPipelineByPropertyName=$True)]
        [Alias('ParentKeypath')]
        [String]$RegistryKeyPath,

        [Parameter(ParameterSetName = 'DelKey',Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String[]]$ChildKey,

        [Parameter(ParameterSetName = 'DelValue',Position=5, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String[]]$ValueName
    )
    Begin
    {
        # $RegistryRoot = "[{0}]::{1}"-f 'Microsoft.Win32.RegistryHive', $RegistryHive
        # try
        # {
        #     $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        # }
        # catch
        # {
        #     Write-Error "Incorrect Registry Hive mentioned, $RegistryHive does not exist"
        # }
    }
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            if (Test-TCPing -IPAddress $Computer)
            {
                try
                {
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                    $key = $reg.OpenSubKey($RegistryKeyPath, $true)
                }
                catch
                {
                    Write-Error "Check permissions on computer name $Computer, cannot connect registry"
                    Continue
                }
                switch ($PsCmdlet.ParameterSetName)
                {
                    'DelValue'
                    {
                        foreach ($regvalue in $ValueName)
                        {
                            if ($key.GetValueNames() -contains $regvalue)
                            {
                                if ($PSCmdlet.ShouldProcess($regvalue, "Удаление ключа реестра"))
                                {
                                    [void]$key.DeleteValue($regvalue)
                                }
                            }
                            else
                            {
                                Write-Error "Registry value name $regvalue doesn't exist on Computer $Computer under path $RegistryKeyPath"
                            }
                        }
                        break
                    }
                    'DelKey'
                    {
                        foreach ($regkey in $ChildKey)
                        {
                            if ($key.GetSubKeyNames() -contains $regkey)
                            {
                                if ($PSCmdlet.ShouldProcess($regkey, "Удаление ветки реестра"))
                                {
                                    [void]$Key.DeleteSubKey("$regkey")
                                }
                            }
                            else
                            {
                                Write-Error "Registry key $regKey doesn't exist on Computer $Computer under path $RegistryKeyPath"
                            }
                        }
                        break
                    }
                }
            }
            else
            {
                Write-Error "Computer Name $Computer not reachable" -Category ConnectionError
            }
        }
    }
    End
    {
        # TODO Что это и нафига? Убрать до релиза
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}

<#
.Synopsis
    Создание раздела реестра или изменение значения уже существующего ключа на удалённой машине.

.Description
    Создаёт или изменяет уже существующий ключ или раздел реестра на удалённой машине.

.Parameter ComputerName
    Имя или IP адрес машин или одной машины.

.Parameter RegistryHive
    Раздел реестра. Значение предопределены заранее: 'ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig'.

.Parameter RegistryKeyPath
    Путь к разделу в реестре. Не забываем экранировать, на всякий.

.Parameter ChildKey
    Удалить раздел в реестре или...

.Parameter ValueName
    Удалить ключ в реестре.

.Example
    # Удалить ключ в реестре
    Write-RegValueData -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\PSRemoteRegistry\' -ValueName 'Version'

.Example
    # Удалить раздел в реестре
    Write-RegValueData -ComputerName 'имя_компа' -RegistryHive LocalMachine -RegistryKeyPath 'SOFTWARE\WOW6432Node\' -ChildKey 'PSRemoteRegistry'

.Notes
    Wiki проекта: https://github.com/pashalvov/PSRemoteRegistry/wiki/%D0%94%D0%BE%D0%B1%D1%80%D0%BE-%D0%BF%D0%BE%D0%B6%D0%B0%D0%BB%D0%BE%D0%B2%D0%B0%D1%82%D1%8C
    Нашёл баг или хочешь доработку: https://github.com/pashalvov/PSRemoteRegistry/pulls
    Сайт проекта: https://github.com/pashalvov/PSRemoteRegistry
    Это форк проекта: https://github.com/kunaludapi/Powershell-remote-registry
#>
function Write-RegValueData
{
    [CmdletBinding(SupportsShouldProcess=$false,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com',
    DefaultParameterSetName='NewValue')]
    Param
    (
        [Parameter(ParameterSetName = 'NewValue', Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'NewKey', Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('C')]
        [String[]]$ComputerName,

        [Parameter(ParameterSetName = 'NewValue', Position=1, Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'NewKey', Position=1, Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [Alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',

        [Parameter(ParameterSetName = 'NewValue', Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'NewKey', Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('ParentKeypath')]
        [String]$RegistryKeyPath,

        [Parameter(ParameterSetName = 'NewKey',Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String]$ChildKey,

        [Parameter(ParameterSetName = 'NewValue',Position=4, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [Alias('Type')]
        [ValidateSet('String', 'Binary', 'DWord', 'QWord', 'MultiString', 'ExpandString')]
        [String]$ValueType,

        [Parameter(ParameterSetName = 'NewValue',Position=5, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String]$ValueName,

        [Parameter(ParameterSetName = 'NewValue',Position=6, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String]$ValueData
    )
    Begin
    {
        # $RegistryRoot= "[{0}]::{1}"-f 'Microsoft.Win32.RegistryHive', $RegistryHive
        # try
        # {
        #     $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        # }
        # catch
        # {
        #     Write-Error "Incorrect Registry Hive mentioned, $RegistryHive does not exist"
        # }
    }
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            if (Test-TCPing -IPAddress $Computer)
            {
                try
                {
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                    $key = $reg.OpenSubKey($RegistryKeyPath, $true)
                }
                catch
                {
                    Write-Error "Check access on computer name $Computer, cannot connect registry"
                    Continue
                }
                switch ($PsCmdlet.ParameterSetName)
                {
                    'NewValue'
                    {
                        try
                        {
                            $ValueType = [Microsoft.Win32.RegistryValueKind]::$ValueType
                            $key.SetValue($ValueName,$ValueData,$ValueType)
                            # TODO Разобратся что это за параметр
                            #$Data = $key.GetValue($ValueName)
                            $Obj = New-Object psobject
                            $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                            $Obj | Add-Member -Name RegistryPath -MemberType NoteProperty -Value "$RegistryKeyPath"
                            $Obj | Add-Member -Name RegistryValueName -MemberType NoteProperty -Value $ValueName
                            $Obj | Add-Member -Name RegistryValueData -MemberType NoteProperty -Value $ValueData
                            return $Obj
                            break
                        }
                        catch
                        {
                            Write-Error "Not able to create $ValueName on remote computer name $Computer"
                            Continue
                        }
                    }
                    'NewKey'
                    {
                        try
                        {
                            if ($key.GetSubKeyNames() -contains $ChildKey)
                            {
                                $Obj = New-Object psobject
                                $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                                $Obj | Add-Member -Name RegistryPath -MemberType NoteProperty -Value $RegistryKeyPath
                                $Obj | Add-Member -Name RegistryChildKey -MemberType NoteProperty -Value $Childkey
                                $Obj
                                Continue
                            }

                            [void]$Key.CreateSubKey("$ChildKey")
                        }
                        catch
                        {
                            Write-Error "Not able to create $ChildKey on remote computer name $Computer"
                            Continue
                        }
                        break
                    }
                }
            }
            else
            {
                Write-Error "Computer Name $Computer not reachable" -Category ConnectionError
            }
        }
    }
    End
    {
        # TODO #2 Что это и нафига? Убрать до релиза
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}

<#
# TODO #1 Сделать сокращения
#region Aliases
#New-Alias -Name ssj -Value Start-RSJob -Force
#endregion Aliases

# TODO Добавить сокращения
$ExportModule = @{
    #Alias = @('gsj','rmsj','rsj','spsj','ssj','wsj')
    Function = @('Test-TCPing','Get-RegValueData','Get-RegChildItem','Remove-RegKeyValue','Write-RegValueData')
    #Variable = @('PoshRS_JobId','PoshRS_Jobs','PoshRS_jobCleanup','PoshRS_RunspacePoolCleanup','PoshRS_RunspacePools')
}
#>

Export-ModuleMember -Function *