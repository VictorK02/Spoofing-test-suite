#!/bin/bash

cd ~

echo "[*] Downloading installer..."
wget https://autoinstall.plesk.com/plesk-installer
chmod +x plesk-installer

echo "[!] Launching interactive installer. Select 'Typical' when prompted."
sudo ./plesk-installer

