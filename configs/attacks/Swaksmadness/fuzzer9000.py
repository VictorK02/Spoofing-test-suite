import json
import subprocess
import time

# --- CONFIG ---
ID_FILE = "ids" # The IDs you found in Thunderbird
JSON_FILE = "../ESpoofing/config/fuzz.json"
TARGET_EMAIL = "vagrant@myreceiver.com"
SENDER_ENVELOPE = "vagrant@mysender.com"
SERVER_IP = "127.0.0.1"

def retest_winners():
    # Load IDs
    with open(ID_FILE, 'r') as f:
        ids = [int(line.strip()) for line in f if line.strip()]
        # ids = list(range(101))

    # Load Full Fuzz Data
    with open(JSON_FILE, 'r') as f:
        data = json.load(f)
    payloads = data.get("mime_from", [])

    print(f"[*] Re-testing {len(ids)} verified Visual Spoofs...")

    for i in ids:
        content = payloads[i]
        print(f"    [>] Sending ID {i}...")
        
        cmd = [
            "swaks", "--to", TARGET_EMAIL, "--from", SENDER_ENVELOPE,
            "--server", SERVER_IP, "--header", content.strip(),
            "--h-Subject", f"HARDENING TEST ID {i}"
        ]
        subprocess.run(cmd, capture_output=True)
        time.sleep(2)

if __name__ == "__main__":
    retest_winners()
