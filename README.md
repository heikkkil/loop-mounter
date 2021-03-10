# Loop mounter - mountos.sh
The script file provides functions for easier mounting and unmounting of a disk image partition as a loop device with automatic file offset calculation.

The function creates a mount directory for the selected partition at `/mnt` and it also creates a symbolic link to the mountpoint. The mountpoint gets prefixed with a magic `mountos_` to make it distinguishable for the umountos function to prevent accidental unmounting of other mountpoints.

## Prerequisites
- Have root access rights on the system
- Bash version >= 4
- fdisk

## Install
Downdload and source the script file mountos.sh to enable the functions and their configurations.

## Uninstall
Remove the script file mountos.sh and it's sourcing. Restart Bash.

## Usage
### Mount:
`mountos disk-image [fs-type]`
- disk-image	Disk image file that can be red by fdisk
- fs-type	Optional filesystem type the partition shall be mounted on

In case the disk image has multiple physical partitions to choose of the mount function mountos prompts user to select the partition to be mounted.

An optional argument for the file system type can also be specified. The default filesystem type is ext4.

### Unmount:
`umountos mountpoint`
- mountpoint	Path to mountpoint created by mountos function

## Configuration
The functions can be configured to print operation steps to stdout (be verbose) or to perform dry run (test) without making any changes on your filesystem. Also the mountpoint magic prefix can be configured to your liking.
