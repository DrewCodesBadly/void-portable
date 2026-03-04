# Install Guide

## Partitioning the disk and installing void

You will need a void system with xtools and necessary mkfs utils (exfat-utils likely) installed.

- Use cfdisk to create a USB drive partition, maybe swap partition, boot partition, and system partition
- Mount the root filesystem to /mnt
- Mount the boot partition to /mnt/boot/efi
- `XBPS_ARCH=x86_64 xbps-install -S -r /mnt -R "https://repo-default.voidlinux.org/current" base-system`
- `xgenfstab -U /mnt > /mnt/etc/fstab`
- copy the 'install_void_sys.sh' script to the new root somewhere.
- `xchroot /mnt /bin/bash`
- you need to manually fix the sudoers file by running `visudo` and uncommenting the line allowing wheel users to sudo without a password.
  - in order for this to work you may need to install your terminal on the new system first.
- `chmod +x /path/to/install_void_sys.sh`
- `/path/to/install_void_sys.sh`
- boot into the new system - NetworkManager is installed for wifi needs.
- in case some packages had issues you might want to run `xbps-install -Su` and `flatpak update` once you get into the new system.
