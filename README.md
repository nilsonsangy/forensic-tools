<div align="center">

# 🔍 Forensic Tools

**A comprehensive toolkit for Digital Forensics, Incident Response, and System Data Collection**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.x](https://img.shields.io/badge/python-3.x-blue.svg)](https://www.python.org/downloads/)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey)](https://github.com/nilsonsangy/forensic-tools)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)

*Empowering investigators, security professionals, and researchers with automated forensic analysis tools*

</div>

---

## 📋 Table of Contents

- [🛠️ Tools Overview](#️-tools-overview)
- [🚀 Quick Start](#-quick-start)
- [🔧 Installation](#-installation)
- [📖 Usage](#-usage)
  - [Windows Data Collection](#windows-data-collection)
  - [Linux Data Collection](#linux-data-collection)
  - [Steganography Analysis](#steganography-analysis)
  - [Onion Link Analyzer](#onion-link-analyzer)
  - [Hash Generation](#hash-generation)
  - [BitLocker Management](#bitlocker-management)
- [⚙️ Requirements](#️-requirements)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [💝 Donations](#-donations)
- [⚠️ Disclaimer](#️-disclaimer)
- [📞 Contact](#-contact)

---

## 🛠️ Tools Overview

| Tool                      | Description                                      | Platform            | Output                | Use Case                |
|---------------------------|--------------------------------------------------|---------------------|-----------------------|-------------------------|
| **Windows Collector**     | Extract volatile data, processes, network info   | Windows             | Text reports          | Incident response       |
| **Linux Collector**       | Collect system data, processes, network info     | Linux               | Text reports          | Incident response       |
| **Steganography Tool**    | Hide/extract files in images using LSB           | Cross-platform      | Modified images/files | Evidence analysis       |
| **Onion Analyzer**        | Extract and analyze .onion links from websites   | Cross-platform      | Tor Browser tabs      | Dark web investigation  |
| **Hash Generator**        | Generate SHA256 hashes for file integrity        | Windows             | Hash files            | Evidence verification   |
| **BitLocker Disabler**    | Manage BitLocker encryption settings             | Windows             | System changes        | Forensic preparation    |
| **ERUNT**                 | Windows registry backup utility                   | Windows             | Registry backups      | System preservation     |
| **fsum**                  | File hash generation tool                         | Windows             | Hash files            | Integrity verification  |

---

## 🚀 Python Environment Configuration

**Windows:**
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

**Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

---

## 📖 Usage

### Windows Data Collection

Collect comprehensive system information for forensic analysis.

```powershell
# PowerShell version (recommended)
.\windows_collector.ps1

# Batch version
.\windows_collector.bat
```

**Features:**
- Running processes and services
- Network connections and routing
- System information and uptime
- User accounts and sessions
- Event logs and installed software
- Registry information

### Linux Data Collection

Extract volatile data from Linux systems for incident response.

```bash
# Give execution permission
chmod +x linux_collector.sh

# Run as root (required for system data)
sudo ./linux_collector.sh
```

**Features:**
- Process information and memory
- Network connections and interfaces
- System logs and user sessions
- File system information
- Hardware and kernel data

### Steganography Analysis

Hide files in images or extract hidden data using LSB steganography.

```bash
# Hide a file in an image
python steg.py embed cover_image.png secret_file.txt output_image.png

# Extract hidden data from an image
python steg.py extract stego_image.png extracted_file.txt
```

**Use Cases:**
- Evidence concealment analysis
- Malware detection in images
- Covert communication investigation

### Onion Link Analyzer

Extract and analyze .onion links from websites using Tor Browser.

```bash
python onion_analyzer.py
```

**Setup Requirements:**
- Tor Browser installed
- `TOR_BROWSER_PATH` environment variable set
- Or provide path when prompted

**Features:**
- Automatically extracts .onion links from web pages
- Opens links in Tor Browser for analysis
- Supports both Windows and Linux

Set the Tor Browser path:

```bash
# Windows
set TOR_BROWSER_PATH=C:\Users\Username\Desktop\Tor Browser\Browser\firefox.exe

# Linux
export TOR_BROWSER_PATH=/usr/bin/tor-browser
```

### Hash Generation

Generate SHA256 hashes for file integrity verification.

```powershell
# PowerShell script
.\generate_hashes.ps1

# Or use fsum.exe directly
.\fsum.exe -sha256 -r "C:\path\to\files"
```

**Output:**
- `hashes.txt` file with all file hashes
- Timestamp of generation
- SHA256 hash of the hash file itself

### BitLocker Management

Manage BitLocker encryption settings for forensic preparation.

```powershell
.\bitlocker_disabler.ps1
```

**Features:**
- Suspend BitLocker protection
- Resume BitLocker protection
- Check BitLocker status

---

## 💝 Donations

If you find this project helpful and would like to support its development, consider making a donation. Your contribution helps keep this toolkit updated and motivates further improvements!

| ☕ Support this project (EN) | ☕ Apoie este projeto (PT-BR) |
|-----------------------------|------------------------------|
| If this project helps you or you think it's cool, consider supporting:<br>💳 [PayPal](https://www.paypal.com/donate/?business=7CC3CMJVYYHAC&no_recurring=0&currency_code=BRL)<br>![PayPal QR code](https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=https://www.paypal.com/donate/?business=7CC3CMJVYYHAC&no_recurring=0&currency_code=BRL) | Se este projeto te ajuda ou você acha legal, considere apoiar:<br>🇧🇷 Pix: `df92ab3c-11e2-4437-a66b-39308f794173`<br>![Pix QR code](https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=df92ab3c-11e2-4437-a66b-39308f794173) |

---

## ⚠️ Disclaimer

This project is licensed under the MIT License.

This toolkit is for **educational, research, and authorized forensic investigations only**. Use responsibly and ensure compliance with all applicable laws and regulations.

<div align="center">

**⭐ If you found this project useful, please give it a star!**

Made with ❤️ for the Digital Forensics community

</div>