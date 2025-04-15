# forensic-tools

This repository contains a collection of tools and scripts designed to assist in forensic analysis, incident response, and system data collection.

## templates

This directory contains templates for:
- Reports
- Information Security Policies
- Playbooks
- Runbooks

These templates can be used as a starting point for creating standardized documentation in forensic and security operations.

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

This script is designed for incident response and forensic analysis on Windows systems.