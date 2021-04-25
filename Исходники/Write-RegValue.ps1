function Write-RegValue
{
    [CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com',
    DefaultParameterSetName='NewValue')]
    Param
    ( 
        [Parameter(ParameterSetName = 'NewValue', Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'NewKey', Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('C')]
        [String[]]$ComputerName = '.',

        [Parameter(ParameterSetName = 'NewValue', Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'NewKey', Position=1, ValueFromPipelineByPropertyName=$True)]
        [Alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',

        [Parameter(ParameterSetName = 'NewValue', Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Parameter(ParameterSetName = 'NewKey', Position=2, ValueFromPipelineByPropertyName=$True)]
        [Alias('ParentKeypath')]
        [String]$RegistryKeyPath = 'SYSTEM\CurrentControlSet\Software',

        [Parameter(ParameterSetName = 'NewKey',Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String]$ChildKey = 'TestKey',
    
        [Parameter(ParameterSetName = 'NewValue',Position=4, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [Alias('Type')]
        [ValidateSet('String', 'Binary', 'DWord', 'QWord', 'MultiString', 'ExpandString')]
        [String]$ValueType = 'DWORD',

        [Parameter(ParameterSetName = 'NewValue',Position=5, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String]$ValueName = 'ValueName',

        [Parameter(ParameterSetName = 'NewValue',Position=6, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [String]$ValueData = 'ValueData'
    )
    Begin
    {
        function Test-TCPing
        {
            Param
            (
                # Укажи имя или IP адрес компьютера
                [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $True)] 
                [Alias('IP Address')]
                [string]$IPAddress,
                # Укажи порт для проверки
                [Parameter(Mandatory = $false, Position=1, ValueFromPipelineByPropertyName = $True)] 
                [string]$Port = "135"
            )
            
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
        $RegistryRoot= "[{0}]::{1}" -f 'Microsoft.Win32.RegistryHive', $RegistryHive
        try
        {
            $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        }
        catch
        {
            Write-Host "Incorrect Registry Hive mentioned, $RegistryHive does not exist" 
        }
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
                    Write-Host "Check access on computer name $Computer, cannot connect registry" -ForegroundColor Red
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
                            $Data = $key.GetValue($ValueName)
                            $Obj = New-Object psobject
                            $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                            $Obj | Add-Member -Name RegistryPath -MemberType NoteProperty -Value "$RegistryKeyPath"
                            $Obj | Add-Member -Name RegistryValueName -MemberType NoteProperty -Value $ValueName
                            $Obj | Add-Member -Name RegistryValueData -MemberType NoteProperty -Value $ValueData
                            $Obj
                            break
                        }
                        catch
                        {
                            Write-Host "Not able to create $ValueName on remote computer name $Computer" -ForegroundColor Red
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
                            Write-Host "Not able to create $ChildKey on remote computer name $Computer" -ForegroundColor Red
                            Continue
                        }
                        break
                    }
                }
            }
            else
            {
                Write-Host "Computer Name $Computer not reachable" -ForegroundColor Red
            }
        }
    }
    End
    {
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    }
}