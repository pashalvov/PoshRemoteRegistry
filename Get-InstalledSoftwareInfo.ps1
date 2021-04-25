function Get-InstalledSoftwareInfo {
[CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com')]
    Param ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('C')]
        [String[]]$ComputerName = '.'
    )
    Begin
    {
        function Test-TCPing
        {
            Param
            (
                # ˜˜˜˜˜ ˜˜˜ ˜˜˜ IP ˜˜˜˜˜ ˜˜˜˜˜˜˜˜˜˜
                [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $True)] 
                [Alias('IP Address')]
                [string]$IPAddress,
                # ˜˜˜˜˜ ˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜
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
    }
    Process
    {
        Foreach ($Computer in $ComputerName) {
            if (Test-TCPing -IPAddress $Computer)
            {
                $RegistryHive = 'LocalMachine'
                $RegistryKeyPath = $('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
                $RegistryRoot= "[{0}]::{1}" -f 'Microsoft.Win32.RegistryHive', $RegistryHive
                $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
                foreach ($regpath in $RegistryKeyPath) {
                    try {
                        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                        $key = $reg.OpenSubKey($regpath, $true)
                    }
                    catch {
                        Write-Host "Check permissions on computer name $Computer, cannot connect registry" -BackgroundColor DarkRed
                        Continue
                    }
                    foreach ($subkey in $key.GetSubKeyNames()) {
                        $Childsubkey = $key.OpenSubKey($subkey)
                        $SoftwareInfo = $Childsubkey.GetValueNames()
                        $Displayname = $Childsubkey.GetValue('DisplayName')
                        [Int]$rawsize = $Childsubkey.GetValue('EstimatedSize')
                        $ConvertedSize = $rawsize / 1MB
                        $SoftwareSize = "{0:N2}MB" -f $ConvertedSize
                        if ($null -ne $Displayname) {
                            $SoftInfo = [PSCustomObject]@{
                                ComputerName = $Computer
                                DisplayName = $Childsubkey.GetValue('DisplayName')
                                DisplayVersion = $Childsubkey.GetValue('DisplayVersion')
                                Publisher = $Childsubkey.GetValue('Publisher')
                                InstallDate = $Childsubkey.GetValue('InstallDate')
                                EstimatedSize = $SoftwareSize
                                InstallLocation = $Childsubkey.GetValue('InstallLocation')
                                InstallSource = $Childsubkey.GetValue('InstallSource')
                                UninstallString = $Childsubkey.GetValue('UninstallString')
                                RegistryLocation = $Childsubkey.Name
                            }
                        }
                        $SoftInfo 
                        #break
                    }
                }
            }
            else {
                Write-Host "Computer Name $Computer not reachable" -ForegroundColor Red
            }
        }
    }
    End 
    {
        
    }
}