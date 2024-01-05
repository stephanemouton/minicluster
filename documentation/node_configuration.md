# Cluster nodes configuration

Linux used is Rocky Linux 9
Public SSH key of user `capitaine` is copied on each node so that commands can be launched in parallel on each node with [pdsh](https://github.com/chaos/pdsh). 

## Disk partitioning

    Device           Start      End  Sectors  Size Type             Mount
    /dev/mmcblk1p1    2048  1230847  1228800  600M EFI System       /boot/efi
    /dev/mmcblk1p2 1230848  3327999  2097152    1G Linux filesystem /boot
    /dev/mmcblk1p3 3328000 60618751 57290752 27.3G Linux LVM        /

## Network configuration

All nodes are in the same local 192.168.1.X network with cluster gatewat acting as ... network gateway. 
