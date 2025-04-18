# kay_notfiy
A monitoring and alerting system for your virtual lab to track Defender status, DNS changes, and VM connectivity

im running a VM lab similiar to the one from TCM, where i have an Active directory environment, consisting of 1 DC (hydra), and window machines (The Punisher, Spiderman). thier IP address are 192.168.30.133,134,135 respectively. i am using the lab for pentesting and honing Active Directoy skills, all of the VMs have MS defender turned off. i also have a Kali Linux VM running on the network as well (192.168.30.136). i run into problems where defender turns itself back on, on its own, dns changes on the windows machines, and VMs going off line. what i would like to do is set up some type of server or similar, that would notifiy me via a pop up like QTPY5 if any of the VMs turn defender on (check every 30 seconds), dns has changed on any of the windows machines (check every 2 minutes) and if any of the VMs go offline, check every 50 seconds. my host machine and kali have python, but the windows machines do not. i would be open to bash, pyhon, PS, and the use of ntfy.sh or similar program, would be happier with native tools if posibble. what do you think?

Your idea is solid! You essentially need a monitoring and alerting system for your virtual lab to track Defender status, DNS changes, and VM connectivity.

Here's how you could approach it:

### **1. Choosing the Notification Method**
Since you're open to `ntfy.sh`, that would be a great lightweight option for sending notifications. If you want something more flexible with GUI pop-ups, you could also use `Zenity` or `notify-send` on Linux.

### **2. Monitoring Microsoft Defender Status**
Since your Windows machines don’t have Python, using **PowerShell** would be ideal for checking Defender’s status every 30 seconds:
```powershell
$Status = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
if ($Status -eq $false) { 
    Invoke-RestMethod -Uri "https://ntfy.sh/your-topic" -Method POST -Body "Defender re-enabled on $(hostname)"
}
Start-Sleep -Seconds 30
```
You could run this script as a scheduled task in Windows.

### **3. Monitoring DNS Changes**
Use PowerShell to check the DNS settings every 2 minutes:
```powershell
$DNS = Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses
$LastDNS = "StoredDNS.txt"

if ($DNS -ne (Get-Content $LastDNS)) {
    Set-Content -Path $LastDNS -Value $DNS
    Invoke-RestMethod -Uri "https://ntfy.sh/your-topic" -Method POST -Body "DNS changed on $(hostname)"
}
Start-Sleep -Seconds 120
```
Run this as a scheduled task as well.

### **4. Monitoring VM Online Status**
From **Kali**, you can run a **Bash script** to check if the VMs are responding to `ping` every 50 seconds:
```bash
#!/bin/bash
IPS=("192.168.30.133" "192.168.30.134" "192.168.30.135" "192.168.30.136")
for IP in "${IPS[@]}"; do
    if ! ping -c 2 "$IP" &>/dev/null; then
        curl -d "VM with IP $IP is offline!" ntfy.sh/your-topic
    fi
done
sleep 50
```
You could schedule this using `cron`:
```bash
*/1 * * * * /path/to/vm_check.sh
```

### **5. Automating the Setup**
- PowerShell scripts can be set as scheduled tasks in Windows.
- The Bash script can run as a cron job on Kali.

Would this setup work for you? You can always tweak it based on what suits your workflow. 🚀


how would i schedule powershell sckrpts as scheduled tasks in windows, and can a script be used to do this? is there one script i can run on all 3 machines to handle the task for me?


Yes! You can automate the scheduling of PowerShell scripts using another PowerShell script. This will set up the scheduled tasks on all three Windows machines at once.

### **PowerShell Script to Create Scheduled Tasks**
This script will:
- Add scheduled tasks for Defender status checks, DNS monitoring, and VM online status.
- Run each script at the specified intervals.
- Apply the setup on all three Windows machines.

```powershell
$TaskNameDefender = "MonitorDefender"
$TaskNameDNS = "MonitorDNS"
$User = "SYSTEM"  # Run as SYSTEM to ensure it executes without login requirements

$ScriptDefender = "C:\Scripts\CheckDefender.ps1"
$ScriptDNS = "C:\Scripts\CheckDNS.ps1"

# Ensure scripts exist
If (!(Test-Path $ScriptDefender) -or !(Test-Path $ScriptDNS)) {
    Write-Host "Scripts are missing. Ensure they exist at C:\Scripts\"
    exit
}

# Create Defender Monitoring Task (Runs every 30 sec)
schtasks /Create /TN $TaskNameDefender /SC MINUTE /MO 1 /TR "powershell -ExecutionPolicy Bypass -File $ScriptDefender" /RU $User /F

# Create DNS Monitoring Task (Runs every 2 min)
schtasks /Create /TN $TaskNameDNS /SC MINUTE /MO 2 /TR "powershell -ExecutionPolicy Bypass -File $ScriptDNS" /RU $User /F

Write-Host "Scheduled tasks created successfully!"
```

### **Deployment Across All Machines**
You can remotely execute this script on all three machines using `Invoke-Command` from your host or Kali (via SSH/PsExec).

Example from another Windows machine:
```powershell
$Machines = @("192.168.30.133", "192.168.30.134", "192.168.30.135")
foreach ($Machine in $Machines) {
    Invoke-Command -ComputerName $Machine -ScriptBlock { 
        & "C:\Scripts\SetupTasks.ps1"
    }
}
```

For **Kali**, if using `PsExec`:
```bash
for IP in 192.168.30.{133..135}; do
    psexec \\$IP -u Admin -p Password powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\SetupTasks.ps1
done
```

### **Additional Notes**
- Ensure Windows Remote Management (`WinRM`) is enabled if using `Invoke-Command`.
- Scripts should be in a folder (`C:\Scripts\`) on each target machine.
- If a VM goes offline, its scheduled task will resume upon boot.

Would this work for your setup? 🚀



If you don’t have `ntfy.sh` installed on your Kali machine, you still have plenty of ways to send notifications! Here are some alternatives:

### **1. Using Local Pop-up Notifications (`notify-send`)**
On **Kali Linux**, you can use `notify-send` to create a desktop pop-up alert when an issue is detected:
```bash
notify-send "VM ALERT" "Defender was re-enabled on Hydra!"
```
This requires your Kali session to have a GUI, and `libnotify` must be installed.

### **2. Email Notifications**
You can send an email whenever an alert condition is met using Python:
```python
import smtplib

def send_email(subject, message):
    sender = "your-email@gmail.com"
    password = "your-email-password"
    recipient = "recipient-email@gmail.com"

    server = smtplib.SMTP("smtp.gmail.com", 587)
    server.starttls()
    server.login(sender, password)

    email_message = f"Subject: {subject}\n\n{message}"
    server.sendmail(sender, recipient, email_message)
    server.quit()

send_email("ALERT!", "Defender was re-enabled on Hydra!")
```
You’d need to enable **"Less Secure Apps"** on Gmail or use an app-specific password.

### **3. Discord Webhook Alerts**
If you have a **Discord server**, you can use webhooks to send alerts:
1. Create a webhook in a Discord channel.
2. Use `curl` to send messages:
```bash
curl -H "Content-Type: application/json" -d '{"content": "ALERT: Defender re-enabled on Hydra!"}' https://discord.com/api/webhooks/YOUR-WEBHOOK-URL
```
This lets you view alerts in a private or team channel.

### **4. Telegram Bot Alerts**
You can also send messages via Telegram:
1. Create a bot with `BotFather` on Telegram.
2. Get your bot token and chat ID.
3. Send messages using a simple API call:
```bash
curl -s -X POST "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage" -d "chat_id=YOUR_CHAT_ID&text=Defender was re-enabled on Hydra!"
```
This works well if you frequently use Telegram.

### **5. System Logging (`syslog` or `logwatch`)**
You can set up logging for alerts and review them periodically:
```bash
logger "Defender re-enabled on Hydra!"
```
Or use `logwatch` to generate daily reports.

### **6. Web Dashboard Alerts**
If you want a visual dashboard, you can integrate **Grafana & Prometheus** to monitor Defender status, DNS changes, and VM uptime.

---

Would one of these options work for your setup? Let me know what you think! 🚀




Got it! Since your environment is completely **offline**, and you want a **lightweight solution** with **pop-up notifications**, here are some solid alternatives that don’t rely on internet connectivity.

### **1. Native Windows Pop-Up Alerts (PowerShell)**
Since Windows has **native popup capabilities**, you can use `msg.exe` or PowerShell toast notifications.

#### **Option 1: Using `msg.exe` (Simple Popup)**
```powershell
msg * "ALERT: Defender was re-enabled on $(hostname)!"
```
This sends a **basic Windows pop-up message** to all logged-in users. Quick and easy.

#### **Option 2: Using PowerShell Balloon Notifications**
If you want a more modern **toast notification**, you can use this PowerShell snippet:
```powershell
$notification = New-Object -ComObject WScript.Shell
$notification.Popup("Defender re-enabled on $(hostname)!", 5, "ALERT", 64)
```
This pops up a **message box** with an alert icon that stays visible for 5 seconds.

---

### **2. Bash Pop-Up Alerts (Kali)**
On your Kali Linux machine, you can use **Zenity** to display a pop-up box:
```bash
zenity --warning --text="ALERT: Defender was re-enabled on Hydra!"
```
If Zenity isn’t installed, install it via:
```bash
sudo apt install zenity -y
```
This makes alerts more **visual and interactive**.

---

### **3. Offline Logging with Auto-Popups**
If you want a fully **automated system**, you can create a **PowerShell loop** that:
- **Checks Defender status**
- **Logs changes**
- **Triggers a pop-up**
```powershell
while ($true) {
    $Status = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
    if ($Status -eq $false) {
        msg * "ALERT: Defender was turned ON again!"
    }
    Start-Sleep -Seconds 30
}
```
This continuously **monitors Defender every 30 seconds** and pops up an alert if it's re-enabled.

---

### **4. VM Offline Detection (Bash on Kali)**
If a VM goes **offline**, you can trigger an **immediate pop-up** on Kali:
```bash
IPS=("192.168.30.133" "192.168.30.134" "192.168.30.135")
for IP in "${IPS[@]}"; do
    if ! ping -c 2 "$IP" &>/dev/null; then
        zenity --error --text="VM with IP $IP is OFFLINE!"
    fi
done
sleep 50
```
This runs a **ping check every 50 seconds**, displaying a pop-up **only when a VM is unreachable**.

---

### **Final Thoughts**
- **Windows machines** → Use `msg.exe` or PowerShell notifications.
- **Kali Linux** → Use `zenity` for pop-ups.
- **Automated detection** → Run scripts at intervals to **check Defender, DNS changes, and VM status**.

Would this setup give you the visibility you need? 🚀





Got it—you want **all notifications centralized on Kali**, where you'll be spending most of your time. You also want this to run **in the background** without disrupting your workflow. Here’s how we can make that happen.

---

### **Approach: Use Zenity for Pop-ups & Automate with Background Processes**
Since your environment is offline, the best lightweight option is **Zenity** for pop-up notifications on Kali. We can set up background monitoring scripts that:
1. **Check Defender status** every **30 seconds**.
2. **Check DNS changes** every **2 minutes**.
3. **Check VM online status** every **50 seconds**.

These scripts will run in the background **without manual intervention**.

---

### **Step 1: Set Up Windows Machines to Send Alerts to Kali**
Since your Windows machines don’t have Python, we’ll use **PowerShell to send alerts** to Kali over a simple **netcat listener**.

#### **PowerShell Script for Windows Machines (Send Alerts)**
Each machine will run this script, checking Defender status, DNS changes, and VM uptime, then **send notifications to Kali** if changes occur.

```powershell
$KaliIP = "192.168.30.136"
$Port = "4444"

while ($true) {
    $DefenderStatus = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
    if ($DefenderStatus -eq $false) {
        echo "ALERT: Defender is enabled on $(hostname)" | nc $KaliIP $Port
    }

    $DNS = Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses
    $LastDNS = "StoredDNS.txt"
    if ($DNS -ne (Get-Content $LastDNS)) {
        Set-Content -Path $LastDNS -Value $DNS
        echo "ALERT: DNS changed on $(hostname)" | nc $KaliIP $Port
    }

    Start-Sleep -Seconds 30
}
```
Run this script on **all three Windows machines** and have it execute on startup.

---

### **Step 2: Set Up Kali Listener & Pop-ups**
On **Kali Linux**, set up a listener that receives alerts and displays a **Zenity pop-up**.

#### **Bash Script for Kali (Listen & Alert)**
```bash
#!/bin/bash
PORT=4444

while true; do
    MESSAGE=$(nc -l -p $PORT)
    if [[ ! -z "$MESSAGE" ]]; then
        zenity --warning --text="$MESSAGE"
    fi
done
```
Run this script **in the background** using:
```bash
nohup ./kali_listener.sh &
```
This keeps it running even after you close the terminal.

---

### **Step 3: Monitor VM Online Status on Kali**
Since Kali will be your **monitoring hub**, create a script that **pings Windows machines** every 50 seconds and alerts you via pop-ups.

#### **Bash Script to Detect Offline VMs**
```bash
#!/bin/bash
IPS=("192.168.30.133" "192.168.30.134" "192.168.30.135")

while true; do
    for IP in "${IPS[@]}"; do
        if ! ping -c 2 "$IP" &>/dev/null; then
            zenity --error --text="VM $IP is OFFLINE!"
        fi
    done
    sleep 50
done
```
Run this **in the background** using:
```bash
nohup ./vm_monitor.sh &
```

---

### **Final Setup Summary**
✅ **Windows machines:** PowerShell script sends alerts to Kali when Defender turns back on, DNS changes, or other alerts.  
✅ **Kali Linux:** Bash script listens for alerts and pops up notifications.  
✅ **Kali Linux:** Another script checks VM connectivity and alerts if any go offline.  
✅ **All scripts run in the background**, allowing you to focus on pentesting.

Would this solution fit your needs? 🚀


