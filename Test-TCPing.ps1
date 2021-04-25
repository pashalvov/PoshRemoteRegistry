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