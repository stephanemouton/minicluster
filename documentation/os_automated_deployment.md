# Automated and headless Linux deployment

_How to install and setup Linux on cluster nodes unattended_

After an attempt to use various flavors of CentOS, including the _Stream_ version, I felt back on Rocky Linux. Two reasons motivated the choice. On one hand the future of CentOs under RedHat rules is foggy. On the other hand Rocky Linux emerged as a solid alternative.

Automated installation is usually a two steps process:
 1. **Setup a PXE server enabling unattended install**.
 2. **Write a kickstart file to perform automated deployment**.

Because Radxa Rockpi-X Single Board Computers are not able to boot in PXE mode, a new step had to be added between 1 and 2: **using iPXE to add PXE capability to Rockpi-X**. The steps are detailed below.

## 1. Preparing a PXE server

The following pages were used to perform setup of PXE server
* [PXE on CentOS8](https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install/#configuring-a-tftp-server-for-bios-based-clients_preparing-for-a-network-install)
* [Installing PXE server on CentOS9](https://www.server-world.info/en/note?os=CentOS_Stream_9&p=pxe&f=1)
* [Install Multiple Linux Distributions Using PXE Network Boot on RHEL/CentOS 8](https://www.tecmint.com/install-pxe-network-boot-server-in-centos-8/)

### Install a TFTP server

The TFTP protocol is used to bootstrap installation by launching an installation kernel

On Rocky 9 / CentOS Stream it is done with:

    # dnf -y install tftp-server
    # systemctl enable tftp
    # systemctl start tftp

If firewall is used, then enable TFTP

    # firewall-cmd --zone=public --add-service=tftp --permanent
    # firewall-cmd --reload

Path of PXE script is `/var/lib/tftpboot/`

### Configure DHCP server

Refer to [Network configuration](./gateway_configuration.md) in Gateway configuration for basic DHCP and DNS configuration.
It is necessary to allow PXE boot in DHCP configuration and specifiy which PXE script is launched. 
See [dhcpd.conf](../configs/dhcpd.conf) for details.

    # PXE configuration
    option space pxelinux;
    option pxelinux.magic code 208 = string;
    option pxelinux.configfile code 209 = text;
    option pxelinux.pathprefix code 210 = text;
    option pxelinux.reboottime code 211 = unsigned integer 32;
    option architecture-type code 93 = unsigned integer 16;

    class "pxeclients" {
            match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
            next-server 192.168.1.1;
            filename "pxelinux/install.ipxe";
    }

More details on launch script `/var/lib/tftpboot/pxelinux/install.ipxe` is given in next section.

**Inspirational references:**
* [Deploying nodes in Openstack with DHCP and iPXE/PXE](https://docs.openstack.org/ironic/latest/install/configure-pxe.html) 
* Documentation of a full deployment cycle, [from DHCP/DNSMasq configuration to iPXE scrip for HTTP install](https://forum.level1techs.com/t/gnu-linux-installation-server-ipxe-menu-sanboot/186919)

### Configure HTTP server for OS deployment

Once network installation is launched through TFTP + iPXE using a minimal linux system, a full OS must be downloadable. In order to keep defaut HTTP port, web site for installation uses port 8000.
The [HTTP configuration file](../configs/pxeboot.conf) is available. 

## 2. Enabling network installation on Rockpi-X with iPXE

It is confirmed that Rockpi-X are not PXE ready. Forums on Radxa (RockPi-X manufacturer) [suggest to use iPXE](https://forum.radxa.com/t/pxe-boot-issue-please-help/5519) to circumvent this limitation. 

The approach is to boot **using iPXE as UEFI launcher** in order to emulate PXE. The iPXE launcher [is compiled and installed on a USB key](https://gist.github.com/AdrianKoshka/5b6f8b6803092d8b108cda2f8034539a) and Rockpi-X BIOS is setup to boot on **an UEFI USB Key** (see also [feedback](https://forum.ipxe.org/showthread.php?tid=8306) and [additional information](https://bbs.archlinux.org/viewtopic.php?id=248154) on the topic).

Prebuilt iPXE [executables are available](https://ipxe.org/download). In the case of Rockpi-X, the appropriate UEFI executable is `rtl8168.efi`. It has to be renamed and installed on the boot partition of the USB Key in the following directory:

    /efi/boot/bootx64.efi

Launch scripts, based on [iPXE commands](https://ipxe.org/cmd), enable sophisticated boot sequences.

    #!ipxe

    set repo-url 192.168.1.1:8000
    #set base ftp://192.168.1.1/pub/BaseOS/x86_64/os

    echo "            ------------------------ Rocky Linux 9 -------------------------------"
    kernel http://${repo-url}/images/pxeboot/vmlinuz inst.repo=http://${repo-url} inst.text inst.ks=http://${repo-url}/kickstart.ks
    initrd http://${repo-url}/images/pxeboot/initrd.img
    echo "            ------------------------- end Config.  -------------------------------"
    echo     Starting boot in 10 seconds
    sleep 10
    #prompt Press any key to continue
    boot || imgfree
    # Fallback
    shell

Full launch script [/var/lib/tftpboot/pxelinux/install.ipxe](../configs/install.ipxe) is available.

**Articles and gists for iPXE**
* What is [PXE and iPXE](https://wiki.fogproject.org/wiki/index.php/IPXE) ?
* Example of [sophisticated iPXE configuration](https://github.com/mbirth/ipxe-config).
* Another example of [interesting iPXE configuration](https://gist.github.com/robinsmidsrod/2234639).
* Impressive example of [tree of iPXE scripts for multiples OS installation](https://github.com/AdrianKoshka/ipxe-scripts)
* Trick to [perform a IF in iPXE script](https://forum.ipxe.org/showthread.php?tid=6941).
* Troubleshooting [iPXE boot with USB stick](https://forum.ipxe.org/showthread.php?tid=8306).

## 3. Unattended install with kickstart file

Storage device names are different across RockPI-X device: how to cope with it? Device name should be in sync with network name in DHCP: How do we set those names? These values should be defined before installation.

In the opposite, in order to have nodes fully usable remotely, ssh keys should be sent to every nodes after installation. How to perform such init tasks?

The kickstart mechanism provides the tools to address these needs. Out of the regular installation process, kickstart can contain a script to be executed on target computer *before* installation and another one to be run *after* installation.

The PRE-install script will prepare information required for installation in a temporary file that will be included in the installation. That way, installation process can use dynamically created settings. Here is an extract of the PRE install section on preparation of storage and network information.

    %pre
    #!/bin/sh
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

    # Disk partitioning information
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

    # Network configuration
    echo "# Network configuration"        > /tmp/net-include
    echo "# HOSTNAME=$HOSTNAME"                                             >> /tmp/net-include
    echo "network  --bootproto=dhcp --device=enp1s0 --ipv6=auto --activate" >> /tmp/net-include
    echo "network  --hostname=${HOSTNAME}.fleet"                            >> /tmp/net-include
    %end

Installation process then use information by including the temporary files produced in PRE installation script.

    %include /tmp/net-include 
    %include /tmp/part-include 

Finally the POST install script allows to add the final touch to the installation. In our case, it will be ssh keys deployment, retrieved from HTTP installation directory.

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

See the full length [kickstart script](../configs/rocky9-network-kickstart.ks) for details.
The script is stored in the root of the directory containing the file of the Linux distribution. In our case it is `/var/ftp/pub`, according to HTTP configuration file [pxeboot.conf](../configs/pxeboot.conf).  

**Inspirational readings:**
* https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax
* https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/appendixes/Kickstart_Syntax_Reference/#sect-kickstart-example-pre-script
* https://pykickstart.readthedocs.io/en/latest/kickstart-docs.html#chapter-4-pre-installation-script
* https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/appendixes/Kickstart_Syntax_Reference/

## Extra: How to reinstall?

In section 2 a USB key is mentioned. It is used to boot with iPXE and requires node BIOS setup in order to boot on this device. DDoes this mean that this human-requiring process must be repeated for each new installation?
Not at all (and that's nice !).

When Linux is installed, a `/boot/efi/EFI/` is created and populated with necessary distribution-related files to boot. In addition, the BIOS *is set to use those files to boot instead of the ones on the USB key.
Such configuration has also a nice side effect: in order to trigger reinstallation one has just to **wipe content of /boot/efi/ and replace it with the one of the boot directory of the USB key** used for first install.

In detail, the boot partition of the USB contains the following directory and files :

    /efi/boot/
              bootx64.efi
              rtl8168.efi

To launch reinstallation at reboot of the node the `/boot/efi` partition should contain the following files **and nothing else elsewhere**:

    /boot/efi/EFI/BOOT/
                       bootx64.efi
                       rtl8168.efi

Et voilà ;-)
