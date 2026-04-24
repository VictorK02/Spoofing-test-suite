# Vagrant Environment

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

2. 

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

