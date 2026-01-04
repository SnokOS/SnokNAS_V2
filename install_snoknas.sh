#!/bin/bash

# SnokNAS Installation Script
# Automated installer for SnokNAS (Customized CasaOS)

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting SnokNAS Installation...${NC}"

# 1. Check Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root.${NC}" 
   exit 1
fi

# 2. OS Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    echo -e "${GREEN}Detected OS: $OS $VER${NC}"
else
    echo -e "${RED}Unsupported OS.${NC}"
    exit 1
fi

# 3. Install Dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
apt-get update
apt-get install -y smartmontools python3 python3-pip python3-venv curl wget git fonts-roboto

# 4. Install Python Dependencies for Microservices
echo -e "${GREEN}Setting up Microservices Environment...${NC}"
mkdir -p /opt/snoknas/services
python3 -m venv /opt/snoknas/venv
source /opt/snoknas/venv/bin/activate
pip install flask psutil

# 5. Build/Install SnokNAS Backend (Simulated Build)
# In a real scenario, we would pull a binary or build from source.
# Assuming we are running this from the repo root or have access to source.
echo -e "${GREEN}Building SnokNAS Backend...${NC}"
if [ -d "cmd/casaos" ]; then
    # We are in source
    go build -o /usr/local/bin/snoknas cmd/casaos/main.go
else
    echo "Source not found, skipping build (Manual install required for binary)"
fi

# 6. Copy Microservices
echo -e "${GREEN}Deploying Microservices...${NC}"
cp snoknas-services/monitor.py /opt/snoknas/services/
cp snoknas-services/updater.py /opt/snoknas/services/

# 7. Create Systemd Services

# Service: snoknas (Main Backend)
cat <<EOF > /etc/systemd/system/snoknas.service
[Unit]
Description=SnokNAS Backend Service
After=network.target

[Service]
ExecStart=/usr/local/bin/snoknas
Restart=always
User=root
Environment=GOMAXPROCS=4

[Install]
WantedBy=multi-user.target
EOF

# Service: snoknas-monitor (Port 5000)
cat <<EOF > /etc/systemd/system/snoknas-monitor.service
[Unit]
Description=SnokNAS Disk Monitor
After=network.target

[Service]
ExecStart=/opt/snoknas/venv/bin/python3 /opt/snoknas/services/monitor.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Service: snoknas-updater (Port 5001)
cat <<EOF > /etc/systemd/system/snoknas-updater.service
[Unit]
Description=SnokNAS Auto Updater
After=network.target

[Service]
ExecStart=/opt/snoknas/venv/bin/python3 /opt/snoknas/services/updater.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 8. Reload and Enable
echo -e "${GREEN}Enabling Services...${NC}"
systemctl daemon-reload
systemctl enable snoknas snoknas-monitor snoknas-updater
# systemctl start snoknas snoknas-monitor snoknas-updater

echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Web UI: http://<IP>:80 (Default CasaOS/SnokNAS port)"
echo -e "Disk Monitor API: http://localhost:5000/api/disks"
echo -e "Updater API: http://localhost:5001/api/check-update"
