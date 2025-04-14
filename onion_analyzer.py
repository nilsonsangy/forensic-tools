import os
import re
import requests
import subprocess

def extract_onion_links(url):
    """
    Extract all .onion links from a web page.
    """
    try:
        response = requests.get(url)
        response.raise_for_status()
        # Regex to capture .onion links
        onion_links = re.findall(r'(https?://[a-zA-Z0-9]{16,56}\.onion)', response.text)
        return list(set(onion_links))  # Remove duplicates
    except requests.RequestException as e:
        print(f"Error accessing the URL: {e}")
        return []

def open_links_in_tor(onion_links, tor_path): 
    """
    Open all .onion links in a new Tor Browser window, each in a new tab.
    """
    try:
        if onion_links:
            subprocess.Popen([tor_path, "-url"] + onion_links)
            print(f"Opening {len(onion_links)} links in a new Tor Browser window.")
        else:
            print("No links to open.")
    except Exception as e:
        print(f"Error opening the links: {e}")

if __name__ == "__main__":
    # Get the Tor Browser path from the environment variable
    tor_executable_path = os.getenv("TOR_BROWSER_PATH")

    if not tor_executable_path:
        print("Error: TOR_BROWSER_PATH environment variable is not set.")
        # Prompt the user to enter the path manually
        tor_executable_path = input("Please enter the full path to the Tor Browser executable: ").strip()

    if not tor_executable_path or not os.path.isfile(tor_executable_path):
        print("Invalid path provided. Exiting.")
        exit(1)

    # URL of the web page to scrape for .onion links
    target_url = input("Enter the URL of the web page: ").strip()

    # Extract .onion links
    onion_links = extract_onion_links(target_url)

    if onion_links:
        print(f"Found .onion links: {onion_links}")
        # Open all .onion links in a new Tor Browser window
        open_links_in_tor(onion_links, tor_executable_path)
    else:
        print("No .onion links found.")