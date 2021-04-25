function Get-RegValueData {
    [CmdletBinding(SupportsShouldProcess=$True,
        ConfirmImpact='Medium',
        HelpURI='http://vcloud-lab.com')]
    Param
    ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName = '.',
        [Parameter(Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)] 
        [alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive = 'LocalMachine',
        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('KeyPath')]
        [String]$RegistryKeyPath = 'SYSTEM\CurrentControlSet\Services\USBSTOR',
        [parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [alias('Value')]
        [String]$ValueName = 'Start'
    )
    Begin
    {
        function Test-TCPing
        {
            Param (
            [Parameter(Mandatory=$true)] 
                [Alias('IP Address')]
                [string]$IPAddress,
            [Parameter(Mandatory=$false)] 
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
            if (Test-TCPing -IPAddress $Computer -Port 445)
            {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                $key = $reg.OpenSubKey($RegistryKeyPath)
                $Data = $key.GetValue($ValueName)
                $Obj = New-Object psobject
                $Obj | Add-Member -Name Computer -MemberType NoteProperty -Value $Computer
                $Obj | Add-Member -Name RegistryValueName -MemberType NoteProperty -Value "$RegistryKeyPath\$ValueName"
                $Obj | Add-Member -Name RegistryValueData -MemberType NoteProperty -Value $Data
                $Obj
            }
            else
            {
                Write-Host "$Computer not reachable" -ForegroundColor Red
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

#Get-RegValueData -ComputerName LEVIK888 -RegistryHive LocalMachine -RegistryKeyPath SOFTWARE\WOW6432Node\GMCS\POS -ValueName 'GM_Scheduler'