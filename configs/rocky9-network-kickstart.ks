# Local network deployment
#version=RHEL9
# Use text install
text
#### PRE  ############################
%pre
#!/bin/sh
# Inspiration from:
# https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/appendixes/Kickstart_Syntax_Reference/#sect-kick
start-example-pre-script

DEVICE=/dev/mmcblk0
if [ -e $DEVICE ]; then
    STORAGE=mmcblk0
else 
    STORAGE=mmcblk1
fi

echo "#### Setting hostname"
IP=`hostname -I`
IP="${IP% }"
echo "IP=${IP}"
HOSTNAME="cargo${IP:0-1}"
echo "HOSTNAME=$HOSTNAME"

#echo "#### Getting hostname with DHCP"
#IP=`hostname -I`
#echo "IP=$IP"
#HOSTNAME=`host $IP | cut -d ' ' -f 5`
#HOSTNAME="${HOSTNAME%.}"
#echo "HOSTNAME=$HOSTNAME"

# echo "" >> /tmp/part-include

# Disk partitioning information
#ignoredisk --only-use=mmcblk0
#clearpart --list=mmcblk0p2,mmcblk0p3
#part /boot/efi --fstype="efi" --onpart=mmcblk0p1 --noformat --fsoptions="umask=0077,shortname=winnt"
#part /boot --fstype="xfs" --ondisk=mmcblk0 --size=1024
#part pv.1122 --fstype="lvmpv" --ondisk=mmcblk0 --size=27974
#volgroup rl_cargox --pesize=4096 pv.1122
#logvol swap --fstype="swap" --size=2048 --name=swap --vgname=rl_cargox
#logvol / --fstype="xfs" --size=25923 --name=root --vgname=rl_cargox

echo "# Disk partitioning information"        > /tmp/part-include
echo "# STORAGE=$STORAGE"                       >> /tmp/part-include
echo "# IP=$IP"                                 >> /tmp/part-include
echo "# HOSTNAME=$HOSTNAME"                     >> /tmp/part-include
echo "ignoredisk --only-use=$STORAGE"           >> /tmp/part-include
echo "# Partition clearing information"         >> /tmp/part-include
echo "clearpart --list=${STORAGE}p2,${STORAGE}p3"   >> /tmp/part-include
echo "part /boot/efi --fstype=\"efi\" --onpart=${STORAGE}p1 --noformat --fsoptions=\"umask=0077,shortname=winnt\"" >> /tmp/part-include
echo "part /boot --fstype=\"xfs\" --ondisk=$STORAGE --size=1024"        >> /tmp/part-include
echo "part pv.1122 --fstype=\"lvmpv\" --ondisk=$STORAGE --size=27974"   >> /tmp/part-include
echo "volgroup rl_$HOSTNAME --pesize=4096 pv.1122"                      >> /tmp/part-include
echo "logvol swap --fstype=\"swap\" --size=2048 --name=swap --vgname=rl_$HOSTNAME"  >> /tmp/part-include
echo "logvol / --fstype=\"xfs\" --size=25923 --name=root --vgname=rl_$HOSTNAME"     >> /tmp/part-include

#network  --bootproto=dhcp --device=enp1s0 --ipv6=auto --activate
#network  --hostname=cargoX.fleet

echo "# Network configuration"        > /tmp/net-include
echo "# HOSTNAME=$HOSTNAME"                                             >> /tmp/net-include
echo "network  --bootproto=dhcp --device=enp1s0 --ipv6=auto --activate" >> /tmp/net-include
echo "network  --hostname=${HOSTNAME}.fleet"                            >> /tmp/net-include
%end

#### POST ############################
%post --log=/root/kickstart_post.log
# Get and set keys for remote access
URL=http://192.168.1.1:8000/
mkdir /root/.ssh
chmod 700 /root/.ssh
wget ${URL}public_key_root -O /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys

mkdir /home/capitaine/.ssh
wget ${URL}public_key_capitaine -O /home/capitaine/.ssh/authorized_keys
chown capitaine:capitaine /home/capitaine/.ssh
chmod 700 /home/capitaine/.ssh
chown capitaine:capitaine /home/capitaine/.ssh/authorized_keys
chmod 644 /home/capitaine/.ssh/authorized_keys
%end
################################

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

# Keyboard layouts
keyboard --xlayouts='fr'
# System language
lang en_US.UTF-8

# Network information
%include /tmp/net-include 

# Use network installation media
url --url="http://192.168.1.1:8000/"

%packages
@^minimal-environment
@console-internet
@headless-management
@standard
@system-tools

%end

# Run the Setup Agent on first boot
firstboot --enable

# Partitioning
%include /tmp/part-include 

# System timezone
timezone Europe/Paris --utc

# Root password
rootpw --iscrypted --allow-ssh blahblahblahblahblahblahblahblahblahblahblahblah
user --groups=wheel --name=capitaine --password=blahblahblahblahblahblahblahblahblahblahblahblah --iscrypted --gecos="Capitaine Haddock"

reboot
# End of kickstart ...
