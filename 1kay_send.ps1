# Version 1.o

$KaliIP = "10.10.146.81"
$Port = "4444"
$LastDNSFile = "C:\Users\Administrator\Desktop\StoredDNS.txt"

while ($true) {
    # Check Defender status
    $DefenderStatus = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
    if ($DefenderStatus -eq $false) {
        echo "ALERT: Defender is enabled on $(hostname)" | ncat $KaliIP $Port
    }

    # Format DNS output consistently
    $DNS = (Get-DnsClientServerAddress).ServerAddresses -join ","

    # Ensure DNS file exists before comparison
    if (!(Test-Path $LastDNSFile)) {
        Set-Content -Path $LastDNSFile -Value $DNS -Encoding ASCII
    }
    elseif ((Get-Content $LastDNSFile -Encoding ASCII) -ne $DNS) {
        Set-Content -Path $LastDNSFile -Value $DNS -Encoding ASCII
        echo "ALERT: DNS changed on $(hostname)" | ncat $KaliIP $Port
    }

    # Wait before running again
    Start-Sleep -Seconds 30
}
