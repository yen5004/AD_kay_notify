Here’s a short **GitHub README** write-up for your script:

---

# **Windows Defender & DNS Change Monitor**
A **PowerShell monitoring script** that detects **Microsoft Defender re-enabling** and **DNS changes**, then sends alerts to a **Kali Linux machine** via `ncat`.

## **How It Works**
- Runs **continuously** (`while $true` loop) in the background.
- Checks **Microsoft Defender real-time protection** every **30 seconds**.
- Monitors **DNS server changes** and logs previous settings.
- Sends alerts to a Kali Linux listener via **Netcat (`ncat`)**.

## **Usage**
### **1. Configure Kali Linux to Receive Alerts**
Run the following command on your **Kali Linux machine** to listen for alerts:
```bash
ncat -lvp 4444
```
This keeps `ncat` **listening** on port `4444` for incoming alerts.

### **2. Run the PowerShell Script on Windows**
Save the PowerShell script and execute it on the **Windows machines**:
```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\kay_send.ps1
```

### **3. Automate with Task Scheduler**
To run the script at boot:
```powershell
schtasks /Create /TN "DefenderMonitor" /SC ONSTART /TR "powershell -ExecutionPolicy Bypass -File C:\Scripts\kay_send.ps1" /RU SYSTEM
```

## **Requirements**
- Windows machines must have **PowerShell** enabled.
- **Kali Linux** must have **`ncat` installed** (`sudo apt install nmap -y`).
```
sudo apt install ncat -y
```

- **Kali Linux** must have **`zenity` installed** (`sudo apt install senity -y`).
```
sudo apt install zenity -y
```
- **Scripts must be saved in an accessible directory** (e.g., `C:\Scripts\`).
- **Window Machine** must have ncat installed on it (https://nmap.org/ncat/) 

## **Potential Enhancements**
- Add **timestamp logging** for alerts.
- Extend monitoring to **Windows Firewall settings**.
- Use **encrypted communication (`ncat --ssl`)** for better security.

---


