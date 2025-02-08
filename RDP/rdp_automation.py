import pyautogui
import time
import subprocess
import configparser
import os

# Load configuration
config = configparser.ConfigParser()
config.read("config.ini")

# Get common credentials
username = config["SETTINGS"]["username"]
password = os.getenv("PASSWORD")  # Fetch password securely from environment variable
logout_hotkey = config["SETTINGS"]["logout_hotkey"]

# Get server list
servers = config["SERVER_LIST"]["servers"].split(",")

def connect_to_rdp(ip):
    """Open RDP session and log in."""
    print(f"Connecting to {ip.strip()}...")

    # Open RDP client
    subprocess.Popen(["mstsc", "/v:" + ip.strip()])
    time.sleep(5)  # Wait for RDP window to open

    # Automate Username Entry
    pyautogui.typewrite(username)
    pyautogui.press("tab")

    # Automate Password Entry
    pyautogui.typewrite(password)
    pyautogui.press("enter")

    print(f"Logged into {ip.strip()}")
    time.sleep(10)  # Adjust based on login time

def logout_rdp():
    """Log out from RDP session."""
    print("Logging out session...")
    pyautogui.hotkey(*logout_hotkey.split("+"))  # Press ALT+F4
    time.sleep(2)
    pyautogui.press("enter")  # Confirm logout if required
    time.sleep(2)

if __name__ == "__main__":
    for ip in servers:
        connect_to_rdp(ip)
        time.sleep(20)  # Time spent in session (adjust as needed)
        logout_rdp()

    print("All RDP sessions completed.")
