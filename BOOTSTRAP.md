# Bootstrap

Instruction how to set ant-hill from scratch (tested when OS SSD crashed 😢).

Assumptions:
* Disks are available
  * "data" disk has data
  * "media" disk is available
  * "backup" disk is available
* the machine has 2 network interfaces:
  * "enp9s0" main iface for ant-hill networking
  * "enp1s0f0" iface for bridge of VMs

1. Install OS
   Use balenaEtcher on MacOS to prepare USB stick with Ubuntu Desktop 22.04.
   Install Ubuntu. Use username "jakub" and machine name "ant-hill".
   Use minimal installation (without games, office etc.).

2. Pre-prepare "data" partition.
   Reboot from USB stick. Resize OS partition from 1TB to 500GB.

3. Setup SSH
   Reboot to OS.
   ```bash
   $ sudo apt update
   $ sudo apt install openssh-server
   ```
   Run on Macbook
   ```bash
   $ ssh-copy-id jakub@192.168.1.50
   ```
   Make sure DHCP on the router is configured so this machine gets `192.168.1.50`.
   You don't need screen anymore.

4. Encrypt "data" partition
   ```bash
   $ sudo apt install cryptsetup
   $ cryptsetup luksFormat /dev/nvme0n1p3 # Use password using "ansible-vault view vars/secrets.yaml"
   ```

5. Provision all machines
   Make sure all disks in `ant-hill.yaml` are available.
   See README.md what to run.

