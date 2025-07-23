# forensic-tools

This repository contains a collection of tools and scripts designed to assist in forensic analysis, incident response, and system data collection.

## ERUNT

**ERUNT** (Emergency Recovery Utility NT) is a tool for extracting and backing up Windows registry keys while the system is running. It is useful for preserving critical system configurations during forensic investigations.

## fsum

**fsum.exe** is a command-line tool for generating file hashes. It supports multiple algorithms, including MD5, SHA1, and SHA256.  
- Use this tool to verify file integrity or detect changes in files.  
- If the official website [https://www.slavasoft.com/fsum/](https://www.slavasoft.com/fsum/) is unavailable, you can download `fsum_v2.52.zip` from this repository.

## generate_hashes

**generate_hashes.ps1** is a PowerShell script that:
- Calculates the SHA256 hash of all files in a specified folder (including subfolders).
- Saves the results to a `hashes.txt` file in the same folder.
- Includes a timestamp in the `hashes.txt` file to indicate when the hashes were generated.
- Calculates and displays the SHA256 hash of the `hashes.txt` file itself.

This script is useful for verifying file integrity and detecting unauthorized changes.

## linux_collector

**linux_collector.sh** is a shell script for extracting volatile data from Linux systems. It collects information such as:
- Running processes
- Network connections
- System uptime
- Logged-in users

This script is designed for incident response and forensic analysis on Linux systems.

## onion_analyzer

**onion_analyzer.py** is a Python script that:
- Extracts `.onion` links from a specified website.
- Opens each `.onion` link in a new tab of the Tor Browser.

### Requirements:
- The Tor Browser path must be configured in the system environment variable `TOR_BROWSER_PATH`.
- If the variable is not set, the script will prompt the user to enter the path manually.

This tool is useful for analyzing websites that host `.onion` links on the dark web.

## windows_collector

**windows_collector.bat** is a batch script for extracting volatile data from Windows systems. It collects information such as:
- Running processes
- Network connections
- System uptime
- Logged-in users

**windows_collector.ps1** is a PowerShell script designed for similar purposes but offers enhanced capabilities, such as:
- Collecting detailed event logs
- Gathering installed software information
- Extracting user account details

Both scripts are designed for incident response and forensic analysis on Windows systems. Choose the appropriate script based on the level of detail required and the system's capabilities.

## How to install requirements and run the scripts

1. **Clone the repository:**
   ```sh
   git clone https://github.com/nilsonsangy/forensic-tools.git
   cd forensic-tools
   ```

2. **Linux:**
   - Give execution permission to the script:
     ```sh
     chmod +x linux_collector.sh
     ```
   - Run the script:
     ```sh
     sudo ./linux_collector.sh
     ```

3. **Windows:**
   - Run `windows_collector.bat` or `windows_collector.ps1` as administrator.
   - For PowerShell, use:
     ```powershell
     .\windows_collector.ps1
     ```

4. **Python (onion_analyzer):**
   - Install Python 3.x.
   - Install the dependencies:
     ```sh
     pip install -r requirements.txt
     ```
   - Run the script:
     ```sh
     python onion_analyzer.py
     ```

> **Note:** Some scripts require administrator/root privileges and specific system dependencies (e.g., dmidecode, lsof, netstat, etc.).