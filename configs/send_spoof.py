import subprocess

# Configuration
SERVER = "localhost"
RECIPIENT = "vagrant@myreceiver.com"
ENVELOPE_FROM = "vagrant@mysender.com"

# Payloads
test_payloads = [
    'From: admin@company.com>\nTo: vagrant@myreceiver.com\nSubject: Test 1',
    'From: ,<admin@company.com>\nTo: vagrant@myreceiver.com\nSubject: Test 2',
    'From: admin@company.com, admin@department.company.com\nTo: vagrant@myreceiver.com\nSubject: Test 3',
    'From: admin@company.com \\\nTo: vagrant@myreceiver.com\nSubject: Test 4',
    'From: admin@company.com )\nTo: vagrant@myreceiver.com\nSubject: Test 5',
    'From:vagrant@mysender.com:From:<admin@company.com>\nTo: vagrant@myreceiver.com\nSubject: Test 6',
    'From:vagrant@mysender.com\nTo: vagrant@myreceiver.com\nSubject: Normal email for test'
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
            # We run it and wait, but don't obsess over the return code
            subprocess.run(cmd, capture_output=True, text=True)
            print(f"Test {i} sent. Check logs/mailbox for results.")
        except Exception as e:
            print(f"Test {i} failed to send: {e}")

if __name__ == "__main__":
    print(f"Starting spoof tests to {RECIPIENT}...")
    run_swaks()
    print("Done.")