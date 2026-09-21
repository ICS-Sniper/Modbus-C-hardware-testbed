# ICS-Sniper Modbus-C Hardware Testbed

**SWaT hardware testbed (Connected Modbus version)**

This repository contains the hardware Modbus/TCP testbed used by ICS-Sniper. Six Allen-Bradley Micro820 PLCs connect through a Windows VPN gateway to a cloud SCADA host.

Replace every value in angle brackets, such as `<router-public-ip>`, with a value from your environment. Generate new VPN credentials for every deployment.

## Architecture

```text
Micro820 PLC network             Windows gateway                 OpenVPN router       SCADA
192.168.137.0/24  <----------->  Ethernet: 192.168.137.1  <----> 10.8.0.1/24 <------> 10.8.0.3/24
Six Micro820 PLCs                OpenVPN: 10.8.0.2                                     TCP 502
```

The router advertises `192.168.137.0/24` through the Windows gateway. Each Micro820 PLC must use `192.168.137.1` as its default gateway.

## Requirements

| Component | Quantity | Requirements |
| --- | ---: | --- |
| OpenVPN router | 1 | Ubuntu 22.04; publicly reachable TCP 1194; SSH access; IP forwarding; public IP or DNS name |
| SCADA | 1 | Ubuntu 22.04; 4 vCPUs, 16 GiB RAM, 32 GiB storage; SSH access; outbound TCP access to the router; TCP 502 available locally |
| Allen-Bradley Micro820 PLC | 6 | Ethernet connectivity, Modbus/TCP client program, and default gateway `192.168.137.1` |
| Windows gateway | 1 | Windows 11; Wi-Fi or other uplink; 1 Gbps USB Ethernet connection to the PLC LAN; OpenVPN Wintun interface |
| Plant simulator | 1 | Python environment for the included six-stage physical-process simulator |
| Engineering workstation | 1 | Connected Components Workbench for deploying the included Micro820 projects |

The local administrator needs SSH access to the Linux instances and physical access to the Windows gateway and Micro820 PLCs.

## Clone the Repository

Clone the public repository on the SCADA host and Windows gateway.

Linux:

```bash
cd /home/ubuntu
git clone https://github.com/ICS-Sniper/Modbus-C-hardware-testbed.git
cd Modbus-C-hardware-testbed
```

Windows PowerShell:

```powershell
cd "<parent-directory>"
git clone https://github.com/ICS-Sniper/Modbus-C-hardware-testbed.git
cd Modbus-C-hardware-testbed
```

## One-Time Setup

### 1. Configure the OpenVPN router

Install OpenVPN and Easy-RSA:

```bash
sudo apt update
sudo apt install -y easy-rsa openvpn
mkdir -p ~/openvpn-ca
cd ~/openvpn-ca
```

Create the certificate authority and server material:

```bash
/usr/share/easy-rsa/easyrsa init-pki
/usr/share/easy-rsa/easyrsa build-ca
/usr/share/easy-rsa/easyrsa gen-req server nopass
/usr/share/easy-rsa/easyrsa sign-req server server
/usr/share/easy-rsa/easyrsa gen-dh
openvpn --genkey tls-crypt-v2-server ta.key
```

Create separate credentials for the Windows gateway and SCADA clients:

```bash
/usr/share/easy-rsa/easyrsa gen-req plc-gateway nopass
/usr/share/easy-rsa/easyrsa sign-req client plc-gateway
openvpn --tls-crypt-v2 ./ta.key \
  --genkey tls-crypt-v2-client ./pki/private/plc-gateway-tc.key

/usr/share/easy-rsa/easyrsa gen-req scada nopass
/usr/share/easy-rsa/easyrsa sign-req client scada
openvpn --tls-crypt-v2 ./ta.key \
  --genkey tls-crypt-v2-client ./pki/private/scada-tc.key
```

Install the server material:

```bash
sudo install -d -m 0755 /etc/openvpn/ccd
sudo install -m 0644 ~/openvpn-ca/pki/ca.crt /etc/openvpn/ca.crt
sudo install -m 0644 ~/openvpn-ca/pki/dh.pem /etc/openvpn/dh.pem
sudo install -m 0644 ~/openvpn-ca/pki/issued/server.crt /etc/openvpn/server.crt
sudo install -m 0600 ~/openvpn-ca/pki/private/server.key /etc/openvpn/server.key
sudo install -m 0600 ~/openvpn-ca/ta.key /etc/openvpn/ta.key
```

Create `/etc/openvpn/server.conf`:

```conf
port 1194
proto tcp
dev tun

ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-crypt-v2 /etc/openvpn/ta.key

server 10.8.0.0 255.255.255.0
topology subnet
client-config-dir /etc/openvpn/ccd
ifconfig-pool-persist ipp.txt

route 192.168.137.0 255.255.255.0
push "route 10.8.0.0 255.255.255.0"
push "route 192.168.137.0 255.255.255.0"

keepalive 10 120
persist-key
persist-tun
cipher AES-256-GCM
auth SHA256
auth-nocache
user nobody
group nogroup
status openvpn-status.log
verb 3
```

Assign stable VPN addresses and declare the PLC subnet behind the Windows gateway:

```bash
sudo tee /etc/openvpn/ccd/plc-gateway >/dev/null <<'EOF'
ifconfig-push 10.8.0.2 255.255.255.0
iroute 192.168.137.0 255.255.255.0
EOF

echo "ifconfig-push 10.8.0.3 255.255.255.0" | \
  sudo tee /etc/openvpn/ccd/scada >/dev/null
```

To run the testbed only on demand, disable automatic startup:

```bash
sudo systemctl disable openvpn
sudo systemctl disable openvpn@server
```

### 2. Configure the SCADA VPN client

On the SCADA host:

```bash
sudo apt update
sudo apt install -y openvpn
mkdir -p ~/openvpn-ca
chmod 700 ~/openvpn-ca
```

Securely copy these files from the router to `~/openvpn-ca/`:

| Router source | SCADA destination |
| --- | --- |
| `pki/ca.crt` | `ca.crt` |
| `pki/issued/scada.crt` | `scada.crt` |
| `pki/private/scada.key` | `scada.key` |
| `pki/private/scada-tc.key` | `scada-tc.key` |

Protect the key after copying it:

```bash
chmod 600 ~/openvpn-ca/*.key
```

Create `~/openvpn-ca/client.conf`:

```conf
client
dev tun
proto tcp
remote <router-public-ip-or-dns> 1194
resolv-retry infinite
nobind
persist-key
persist-tun

ca ca.crt
cert scada.crt
key scada.key
remote-cert-tls server
tls-crypt-v2 scada-tc.key

pull
cipher AES-256-GCM
auth SHA256
auth-nocache
verb 3
```

### 3. Configure the Windows gateway

Install the OpenVPN Community client. Open PowerShell as Administrator and create a profile directory:

```powershell
cd "$env:USERPROFILE\OpenVPN\config"
New-Item -ItemType Directory -Force plc-gateway
cd plc-gateway
notepad plc-gateway.ovpn
```

Use this profile, replacing the router address:

```conf
client
dev tun
proto tcp
remote <router-public-ip-or-dns> 1194
resolv-retry infinite
nobind
persist-key
persist-tun

ca ca.crt
cert plc-gateway.crt
key plc-gateway.key
remote-cert-tls server
tls-crypt-v2 plc-gateway-tc.key
disable-dco
windows-driver wintun

pull
cipher AES-256-GCM
auth SHA256
auth-nocache
verb 3
```

Securely copy `ca.crt`, `plc-gateway.crt`, `plc-gateway.key`, and `plc-gateway-tc.key` from the router into this profile directory. Do not reuse the SCADA client key.

Enable system-wide packet forwarding:

```powershell
reg add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /v IPEnableRouter /t REG_DWORD /d 1 /f
```

List adapter names and GUIDs:

```powershell
Get-NetAdapter | Select-Object ifIndex, Name, InterfaceGuid
```

Enable forwarding for the PLC-facing Ethernet and Wintun interfaces:

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{ETHERNET-GUID}" /v EnableRouter /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{WINTUN-GUID}" /v EnableRouter /t REG_DWORD /d 1 /f
```

Set the PLC-facing Ethernet adapter to a static address:

```powershell
netsh interface ip set address "Ethernet" static 192.168.137.1 255.255.255.0
ipconfig
```

If the adapter has a different name, substitute its actual name. Do not use Windows Internet Connection Sharing for this topology. Restart Windows after changing the registry.

Configure every Micro820 PLC with an address in `192.168.137.0/24` and set its default gateway to `192.168.137.1`.

### 4. Install the SCADA software

On the SCADA host:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv
cd /home/ubuntu/Modbus-C-hardware-testbed
python3 -m venv .venv
.venv/bin/pip install \
  pymodbus==2.5.3 \
  pyserial-asyncio \
  cpppo==4.3.0 \
  numpy
```

PyModbus is installed from PyPI. The testbed-specific client and server entry
points remain in `modbus_helpers/` and are launched automatically by
`protocols.py`; do not copy them into the virtual environment.

Create the SCADA log directory:

```bash
mkdir -p ~/test-setup/scadalogs
```

### 5. Prepare the hardware controller and plant simulator

Use Connected Components Workbench to import the included project archives and deploy the supplied Structured Text programs to the six Micro820 PLCs. Confirm the configured IP address and default gateway on every PLC before starting an experiment.

On the Windows gateway, create the plant-simulator environment:

```powershell
cd "<path-to-Modbus-C-hardware-testbed>"
py -3 -m venv .venv
& ".\.venv\Scripts\python.exe" -m pip install pymodbus==2.5.3
```

## Start the Testbed

Start the components in this order. Starting the PLC side before SCADA prints `SCADA main loop starts here` can cause initialization errors.

### 1. Start the router

```bash
ssh -i <ssh-key> ubuntu@<router-public-ip>
cd /etc/openvpn
sudo openvpn --config /etc/openvpn/server.conf --daemon
sudo sysctl -w net.ipv4.ip_forward=1
sudo ss -ltnp | grep 1194
```

### 2. Start SCADA

```bash
ssh -i <ssh-key> ubuntu@<scada-host>
cd ~/openvpn-ca
sudo openvpn --config client.conf --daemon
sudo sysctl -w net.ipv4.ip_forward=1
ping -c 3 10.8.0.1
ping -c 3 10.8.0.2
cd /home/ubuntu/Modbus-C-hardware-testbed
sudo .venv/bin/python SCADA_1_warmRestart.py
```

Wait for:

```text
SCADA main loop starts here
```

### 3. Start the hardware PLC side

On the Windows gateway:

1. Start OpenVPN GUI as Administrator.
2. Connect the `plc-gateway` profile.
3. Run `ipconfig` and confirm that Wintun owns `10.8.0.2` and the PLC-facing Ethernet adapter owns `192.168.137.1`.
4. From the SCADA host, ping each configured PLC address to verify the end-to-end route.
5. Start the included plant simulator:

   ```powershell
   cd "<path-to-Modbus-C-hardware-testbed>"
   & ".\.venv\Scripts\python.exe" ".\plant_main.py"
   ```

## Optional Packet Capture

Install TShark on the router and create a trace directory:

```bash
sudo apt install -y tshark
mkdir -p ~/traces
```

Capture public-side and tunnel-side traffic in separate sessions:

```bash
sudo tshark -i <public-interface> -w ~/traces/public-side.pcap
```

```bash
sudo tshark -i tun0 -w ~/traces/tunnel-side.pcap
```

Use `ip link` to identify the public interface. Packet captures can contain sensitive traffic and should not be committed.

## Stop the Testbed

1. Stop `plant_main.py` with `Ctrl+C`.
2. Stop `SCADA_1_warmRestart.py` with `Ctrl+C`.
3. Disconnect `plc-gateway` in OpenVPN GUI.
4. Stop the SCADA VPN client with `sudo pkill openvpn`.
5. Stop the router OpenVPN process with `sudo pkill openvpn`.
6. Copy required logs or packet captures before terminating ephemeral instances.

## Troubleshooting

| Symptom | Likely cause | Check or fix |
| --- | --- | --- |
| VPN client reports `Connection refused` | Router OpenVPN process or TCP 1194 firewall rule is missing | Start the router service and check `sudo ss -ltnp \| grep 1194` |
| SCADA cannot bind TCP 502 | The process lacks permission or another server is running | Run with `sudo`; inspect `sudo ss -ltnp \| grep ':502'` |
| Router reaches the Windows gateway but not a PLC | Windows forwarding is disabled or a PLC has no return route | Recheck both registry entries and set the PLC gateway to `192.168.137.1` |
| SCADA cannot reach `192.168.137.0/24` | The router is missing the client-specific route | Check `/etc/openvpn/ccd/plc-gateway` for `iroute 192.168.137.0 255.255.255.0` |
| Windows sends ARP with source `0.0.0.0` | Internet Connection Sharing is enabled | Disable Internet Connection Sharing and use registry-based forwarding |
| OpenVPN assigns unexpected client addresses | Certificate common name does not match the CCD filename | Use the `plc-gateway` and `scada` certificate names shown above |

## Repository Layout

| Path | Purpose |
| --- | --- |
| `SCADA_1_warmRestart.py` | Hardware-testbed SCADA process |
| `plant_main.py`, `physical1.py` ... `physical6.py` | Six-stage plant simulator |
| `*.st`, `ccwarc/` | Micro820 Structured Text programs and CCW archives |
| `modbus_helpers/` | Testbed-specific Modbus helpers used by SCADA |
