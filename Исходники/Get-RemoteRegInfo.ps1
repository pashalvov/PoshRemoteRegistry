function Get-RemoteRegInfo {
[CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com',
    DefaultParameterSetName='GetValue')]
    Param
    ( 
        [Parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('C')]
        [String[]]$ComputerName = '.',

        [Parameter(Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
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
                    Write-Host "Check permissions on computer name $Computer, cannot connect registry" -BackgroundColor DarkRed
                    Continue
                }
                if ($null -eq $key.GetSubKeyNames() -or $null -eq $key.GetValueNames()) {
                    Write-Host "Incorrect registry path on $computer" -BackgroundColor DarkRed
                    Continue
                }
                switch ($Type)
                {
                    'ChildKey'
                    {
                        foreach ($ck in $key.GetSubKeyNames())
                        {
                            $obj =  New-Object psobject
                            $obj | Add-Member -Name ComputerName -MemberType NoteProperty -Value $Computer
                            $obj | Add-Member -Name RegistryKeyPath -MemberType NoteProperty -Value "$RegistryHive\$RegistryKeyPath"
                            $obj | Add-Member -Name ChildKey -MemberType NoteProperty -Value $ck
                            $obj
                        }
                        break
                    }
                    'ValueData'
                    {
                        foreach ($vn in $key.GetValueNames())
                        {
                            $obj =  New-Object psobject
                            $obj | Add-Member -Name ComputerName -MemberType NoteProperty -Value $Computer
                            $obj | Add-Member -Name RegistryKeyPath -MemberType NoteProperty -Value "$RegistryHive\$RegistryKeyPath"
                            $obj | Add-Member -Name ValueName -MemberType NoteProperty -Value $vn
                            $obj | Add-Member -Name ValueData -MemberType NoteProperty -Value $key.GetValue($vn)
                            $obj | Add-Member -Name ValueKind -MemberType NoteProperty -Value $key.GetValueKind($vn)
                            $obj
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