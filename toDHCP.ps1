$OS = Get-WmiObject -Class Win32_OperatingSystem ` | Select-Object -Property @("Version", "OSArchitecture")   

#Only run on Windows 8 or newer
If ((($OS.version).StartsWith("10")) -or (($OS.version).StartsWith("8"))){
    $run = $true
} else {
    exit
}
if($run){
    Write-Host "Begin move to DHCP"
    $connect = Test-NetConnection   
    Get-NetAdapter | ? {$_.Name -eq $connect.InterfaceAlias} 
    $adapter = Get-NetAdapter | ? {$_.Name -eq $connect.InterfaceAlias}
    $interface = $adapter | Get-NetIPInterface -AddressFamily "IPv4"
    $OldInfo = $interface | Get-NetIPConfiguration

    If ($interface.Dhcp -eq "Disabled") {
        Write-Host "DHCP is disabled"
        # Remove existing gateway
        If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
        $interface | Remove-NetRoute -Confirm:$false
        }
    # Enable DHCP
    $interface | Set-NetIPInterface -DHCP Enabled
    # Configure the DNS Servers automatically
    $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
    else{
        exit
    }

}
Write-Host "release and renew"
ipconfig /release
ipconfig /renew
Write-Host "awaiting connection"

start-sleep -Seconds 60
if((Test-NetConnection).PingSucceeded -eq "True"){
    Write-Host "Operation SUCCESSFUL"
    exit
}
Write-Host "Operation FAILED. resetting . . ."
$interface | Set-NetIPInterface -DHCP Disabled
$OldIPv4 = $OldInfo.IPv4Address
$Oldgate = $OldInfo.IPv4DefaultGateway
New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $OldIPv4.IPAddress -PrefixLength $OldIPv4.PrefixLength -DefaultGateway $Oldgate.NextHop
Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ($OldInfo.DNSServer).ServerAddresses