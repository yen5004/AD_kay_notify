# Used on windows machine to communicate with kali AD box

$KaliIP = "10.10.146.81"
$Port = "4444"

while ($true) {
    $DefenderStatus = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
    if ($DefenderStatus -eq $false) {
        echo "ALERT: Defender is enabled on $(hostname)" | ncat $KaliIP $Port
    }

    $DNS = Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses
    $LastDNS = "StoredDNS.txt"
    if ($DNS -ne (Get-Content $LastDNS)) {
        Set-Content -Path $LastDNS -Value $DNS
        echo "ALERT: DNS changed on $(hostname)" | ncat  $KaliIP $Port
    }

    Start-Sleep -Seconds 30
}
