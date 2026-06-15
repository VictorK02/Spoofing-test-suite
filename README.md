#Reproducible laboratory environment for email
spoofing analysis

## Vagrant Environment

This project uses Vagrant to provision and run a local virtual machine.

## Requirements

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads)
- A supported provider (typically VirtualBox)

## Quick start

1. Open a terminal in this folder.
2. Start the VM:

	```bash
	vagrant up
	```

3. Connect to the VM:

	```bash
	vagrant ssh
	```

    Alternativt koppla via user, fixar sen

4. Stop the VM when done:

	```bash
	vagrant halt
	```

## Changing config

1. Run the config script (from project root):

	```bash
	setconfig (default/strict/rspamd)
	```


## UI-setup with thunderbird

```bash
sudo apt install thunderbird -y
```


## Useful commands

```bash
vagrant status
vagrant reload
vagrant destroy -f
```

## Runnig attacks

to see the live log on the receiving server, run:
```bash
sudo tail -f /var/log/mail.log | ccze -A
sudo tail -f /var/log/rspamd/rspamd.log | ccze -A
```

to run the attacks on the sending server, run:
```bash
python3 /configs/send_spoof.py
```

## Versions used
- Vagrant 2.4.9
- OpenDMARC Filter v1.4.2
- OpenDKIM Filter v2.11.0
- Rspamd 2.7
- Dovecot 2.3.16
- BIND 9.18.39-0ubuntu0.22.04.3-Ubuntu 
- postfix: mail_version = 3.6.4
- thunderbird: 140.9.1esr
- ubuntu: 
	- PRETTY_NAME="Ubuntu 22.04.5 LTS"
	- NAME="Ubuntu"
	- VERSION_ID="22.04"
	- VERSION="22.04.5 LTS (Jammy Jellyfish)"
- kali:
	- PRETTY_NAME="Kali GNU/Linux Rolling"
	- NAME="Kali GNU/Linux"
	- VERSION_ID="2026.1"
	- VERSION="2026.1"
	- VERSION_CODENAME=kali-rolling

