#!/bin/bash

echo "Checking packages..."
for pkg in numactl-devel automake gcc gcc-c++ elfutils-libelf-devel kernel-devel
do
   rpm qa | grep $pkg
   if [ $? -eq 0 ]; then
      echo "Package $pkg found!"
   else
      echo "Package $pkg not found!"
   fi
done

######################################################
# He builds the DPDK package here
# BUT...there is a yum-available dpdk package.
# And sure enough, it is already installed on 
# this machinen box. Probably from when I was
# doing vpp a year or two ago.
# dpdk-18.11.2-1.el7.x86_64
# SO...WE DO NOT NEED TO BUILD THIS FROM SCRATCH!!!
######################################################
echo "Building DPDK"
# The table versions are dot elevens and we want latest patches on that.
DPDK_VER="18.11.7"
# They make a gz and a xz. We will take the xz format.
DPDK_ARCHIVE=dpdk-${DPDK_VER}.tar.xz
pushd /usr/src
wget http://fast.dpdk.org/rel/${DPDK_ARCHIVE}
# Stop here for now.

# tar xf ${DPDK_ARCHIVE}
# we might check and make sure it is there before exporting an env on it?
#export DPDK_DIR=/usr/src/dpdk-stable-${DPDK_VER}
#pushd ${DPDK_DIR}
#export DPDK_TARGET=x86_64-native-linuxapp-gcc
#export DPDK_BUILD=${DPDK_DIR}/${DPDK_TARGET}
#make install T=${DPDK_TARGET} DESTDIR=install

echo "Installing OpenVSwitch environment and dependencies"
#yum install wget openssl-devel python-sphinx gcc make python-devel openssl-devel libpcap-devel kernel-devel graphviz kernel-debug-devel autoconf automake rpm-build redhat-rpm-config libtool python-twisted-core python-zope-interface PyQt4 desktop-file-utils libcap-ng-devel groff checkpolicy selinux-policy-devel -y

echo "Building OpenVSwitch with DPDK"
#popd
# we should be in /usr/src!!!
#wget https://www.openvswitch.org/releases/openvswitch-2.10.1.tar.gz
#tar -zxvf openvswitch-2.10.1.tar.gz
#export OVS_DIR=/usr/src/openvswitch-2.10.1

#pushd $OVS_DIR
#./boot.sh
#./configure --with-dpdk=$DPDK_BUILD
#make
#make install

# Enable Huge Pages and IOMMU
# He does not do any aforechecking here, he just goes to town.
# NOTE: he will blow away any EXISTING command line parameters, doing this!!! SAY NO TO THIS!!!
# How does this nano and variable set get written into the file? Does it?
#nano /etc/default/grub
#GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=4"

# Here is sets huge pages to 4 in sysctl in hugepages.conf. As this file does not exist, it would be created.
# Is this the only thing you would expect to see in the hugepages.conf file? I am skeptical of this.
#echo 'vm.nr_hugepages=4' > /etc/sysctl.d/hugepages.conf 
#grep HugePages_ /proc/meminfo
#mount -t hugetlbfs none /dev/hugepages``
# After he changes grub, presumably, he does this mkconfig and reboots (which means rest of script would not run).
#grub2-mkconfig -o /boot/grub2/grub.cfg
#reboot

# THE OTHER SCRIPT DOES THIS WITH SYSCTL
# I TRIED DOING THIS AND GOT MEMORY ERRORS IN RESTARTING OPENVSWITCH!!!
# UPDATE:
# I WILL CHANGE THIS TO USE 4 x 1G HUGEPAGES 
echo "Allocating hugepages"
# allocate 1024 2M hugepages
# sysctl -w vm.nr_hugepages=1024
# TRY 4 x 1G hugepages!!
sysctl -w vm.nr_hugepages=4

# make hugepage setting persistent
echo "vm.nr_hugepages=1024" > /etc/sysctl.d/hugepages.conf
# mount hugepages
mount -t hugetlbfs none /dev/hugepages




# this check on huge pages is probably the right and best way. He checks dmesg first, then the kernel cmdline
# Check Huge Pages and IOMMU
echo "Checking Huge Pages and IOMMU"
dmesg | grep -e DMAR -e IOMMU
cat /proc/cmdline | grep iommu=pt
cat /proc/cmdline | grep intel_iommu=on

# Enable DPDK Driver
# Latest release is 18.11.7 - 11 tends to be stable release of DPDK.
# If we were to enable this, this would need to be changed.
#export DPDK_DIR=/usr/src/dpdk-stable-17.11.4

# okay here he loads modules. in looking at openvswitch.org/support/dist-docs-2.5/INSTALL.DPDK.md.html we can
# see that UIO and VFIO are apparently supposed to be mutually exclusive. 
# for dpdk 1.7+ the docs seem to recommend vfio.
# update:
# the versions of dpdk do indeed start off at 1.8 on website but jump up to current 18.11.7 release.
# update: 
# when i run lsmod, i only see the vfio kernel modules loaded. not the uio kernel modules.
# which means yes, you should see one but not the other. you should not see both vfio and uio kernel modules loaded.
#modprobe vfio-pci
#modprobe uio_pci_generic
#cd $DPDK_DIR/x86_64-native-linuxapp-gcc
#sudo modprobe uio
#sudo insmod kmod/igb_uio.ko
# at first i did not see why they did this. i finally realized that this step was taken from
# docs.openvswitch.org/en/latest/intro/install/dpdk/ -- so i will do that manually
#/usr/bin/chmod a+x /dev/vfio
#/usr/bin/chmod 0666 /dev/vfio/*

# THIS is interesting! 
# I wonder if he used an older install dpdk website instead of the one at 
# docs.openvswitch.org/en/latest/intro/install/dpdk/
# because in that documentation, the steps are different than what he does below.
# in fact, he mentions using uio below which might explain this difference perhaps
# because uio is not favored anymore.
# 
# here is the original code from this script. note he does the status FIRST, and then runs a setup script.
#Add interface into DPDK (igb_uio):
#$DPDK_DIR/usertools/dpdk-devbind.py --status
#$DPDK_DIR/usertools/dpdk-setup.sh
#
# then in newer documentation it is reversed. they bind first and then to the status which makes more sense.
# here is what is in CURRENT documentation based on url above:
# $DPDK_DIR/usertools/dpdk-devbind.py --bind=vfio-pci eth1
# $DPDK_DIR/usertools/dpdk-devbind.py --status
#
# We will leave this commented out since we are not using uio.
# In fact, I do not even see the dpdk-devbind.py on the system.
# TODO: look into why i don't have this directory or set of scripts. maybe the dpdk package
# from yum does not install that. i will bet, that if i untar that DPDK tar zip i took from 
# the site, these scripts are in there. let me look.
# UPDATE:
# Yes, if you unpack the dpdk tgz file the directory and scripts are there indeed.
# I just figured out, that i can download dpdk-tools package from yum and it will probably
# give me these tools. 
# UPDATE: I did a yum install on dpdk-tools and now these files indeed are on the system.
# 
# Now, the other script does NOT use the DPDK tools to bind the NICs.
# Instead, it uses a utility called driverctl to do this. Interesting. Never used this tool.

# NOW...excerpt from the other script
#
# in the other script i have, the dude uses driverctl to do this kind of binding.
# nics=$(driverctl -v list-devices | grep -i net | gawk '{print $1}')
#if [-z $nics]; then
#    echo "Can't get NICs to bind"
#    exit
#fi
# when you run this driverctl command, here is what you get back:
# 
# [root@maschinen dpdk]# driverctl -v list-devices |grep -i net | gawk '{print $1}'
# 0000:00:19.0
# 0000:01:00.0
# 0000:01:00.1
# 0000:03:00.0
# 0000:03:00.1
#
# so you get back a bunch of PCI addresses - not NICs like eth0, eth1, eth2, etc.
# he then goes in and uses driverctl to set an override to vfio-pci to that pci nic.
# another way of skinning a cat, looks like.
# i might like this better since i do not need to rely on dpdk scripts.
#
#for nic in $nics; do
#    echo "Binding NIC ${nic}"
#    driverctl set-override ${nic} vfio-pci
#done

# we can do this by hand to test it out.
#    driverctl set-override 0000:03:00.0 vfio-pci
#    driverctl set-override 0000:03:00.1 vfio-pci

# learned a hard lesson. do not ASSUME this kind of thing:
# 0000:00:19.0 em1
# 0000:01:00.0 p1p1
# 0000:01:00.1 p1p2
# 0000:03:00.0 p2p1
# 0000:03:00.1 p2p2
# that is a BAD thing to do, as I lost connectivity and had to haul a monitor to my desk.
# as it turns out, there is a utility called lshw (yum install lshw) that will show you the
# PCI to interface assignments. 
# [root@maschinen ~]# lshw -c network -businfo
# Bus info          Device       Class          Description
# =========================================================
# pci@0000:01:00.0  p2p1         network        82571EB/82571GB Gigabit Ethernet Controller D0/D1 (copper applications)
# pci@0000:01:00.1  p2p2         network        82571EB/82571GB Gigabit Ethernet Controller D0/D1 (copper applications)
# pci@0000:00:19.0  em1          network        Ethernet Connection I217-LM
# pci@0000:03:00.0  p1p1         network        82571EB/82571GB Gigabit Ethernet Controller D0/D1 (copper applications)
# pci@0000:03:00.1  p1p2         network        82571EB/82571GB Gigabit Ethernet Controller D0/D1 (copper applications)
# So there we go. Backwards from what one would probably expect.
# This is what we NEED to do:
    driverctl set-override 0000:01:00.0 vfio-pci
    driverctl set-override 0000:01:00.1 vfio-pci
# 
#
# If we had the bus slot format on interfaces (enp0s1) maybe
# I could have avoided this problem, maybe. But, what is p1p1? Port Position or something?
# Anyway, I guessed wrong in trying to use the NICs that were up and I was connected to.
# I was trying to use p2p1 and p2p2 which are in an unconnected down state so I could use
# those two nics to test without impacting the NICs currently in use and also used with
# OpenStack.

#Start OpenVSwitch:

#sudo pkill -9 ovs
#sudo rm -rf /usr/local/var/run/openvswitch
#sudo rm -rf /usr/local/etc/openvswitch/
#sudo rm -f /usr/local/etc/openvswitch/conf.db
#mkdir -p /usr/local/etc/openvswitch
#mkdir -p /usr/local/var/run/openvswitch

# I did not run this!!! I don't see what value this brings me.
# Remember, I am using SystemD to start the OpenVSwitch!!! I did not build and run it by hand.
#ovsdb-tool create /usr/local/etc/openvswitch/conf.db /usr/local/share/openvswitch/vswitch.ovsschema
#ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
#                     --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
#                     --private-key=db:Open_vSwitch,SSL,private_key \
#                     --certificate=db:Open_vSwitch,SSL,certificate \
#                     --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
#                     --pidfile --detach

# I see this stuff below in a lot of documentation, including the "install dpdk" link that
# can be found at docs.openvswitch.org/en/latest/intro/install.dpdk
# But - what I did, whether it be right or not, was to put the --dpdk into the arguments in 
# /etc/sysconfig/openvswitch.conf file. I did restart with that option and openvswitch did not
# bark or abend with that parameter passed in.

# Yet, after restarting openvswitch with --dpdk passed in, I still see that 
# when I do the check below on dpdp_initialized, i get false back.
# when I check the version, i can see that openvswitch IS indeed linked with DPDK. So that's good.

# I decided to try and create a bridge with netdev. It hangs!!!
# ovs-vsctl add-br br-testdpdk -- set bridge br-testdpdk datapath_type=netdev

#export PATH=$PATH:/usr/local/share/openvswitch/scripts
#export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
# THIS IS FAILING!!!!!! ALWAYS SHOWS enabled false...we need to fix that.
# Check the sysconfig parm which could be the issue!!!
#ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
#ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start

# In sysctl I added --user root --dpdk to the arguments.
# Memory error starting openVSwitch. not enough memory for core 1.
# I am told this will fix this.
# ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
# Doing the above does not fix it because each parm is a numa node. 
# If we did this at all it should be
# ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
# ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-limit="1024"


# Dump all openvswitch parms
# ovs-vsctl list Open_vSwitch

#Check OpenVSwitch have DPDK enable:
#ovs-vsctl get Open_vSwitch . dpdk_initialized
#ovs-vswitchd --version
#ovs-vsctl get Open_vSwitch . dpdk_version

#Create sample bridge with interface from DPDK

#ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev
#ovs-vsctl add-port br0 myportnameone -- set Interface myportnameone type=dpdk options:dpdk-devargs=0000:00:04.0
