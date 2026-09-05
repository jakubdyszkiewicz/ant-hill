# Bootstrap

Instruction how to set ant-hill from scratch (tested when OS SSD crashed 😢).

Assumptions:
* Disks are available
  * "data" disk has data
  * "media" disk is available
  * "backup" disk is available
* the machine uses one physical network interface:
  * "enp9s0" is attached to bridge `vmbridge0`
  * `ant-hill` uses `192.168.1.100` on `vmbridge0`
  * VMs are attached to the same bridge and keep their static IPs

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
   Connect using the temporary address assigned during installation. The final static address for `ant-hill` is `192.168.1.100` on `vmbridge0`.
   You don't need screen anymore.

4. Encrypt "data" partition
   ```bash
   $ sudo apt install cryptsetup
   $ cryptsetup luksFormat /dev/nvme0n1p3 # Use password using "ansible-vault view vars/secrets.yaml"
   ```

5. Provision all machines
   Make sure all disks in `ant-hill.yaml` are available.
   See README.md what to run.
