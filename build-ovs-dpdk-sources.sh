# This will build DPDK and OVS but in specific locations
# This DOES NOT build RPMS!!!!

# DPDK pre-req's
sudo yum install make coreutils.x86_64 gcc glibc-devel.x86_64 kernel-devel.x86_64 kernel-headers.x86_64

# Ubuntu
#sudo apt-get install make coreutils libc6-dev linux-headers-$(uname -r) build-essential libnuma-dev python


# DPDK build

#export DPDK_DIR=/opt/git/dpdk
DPDKRELEASE="stable-17.11.10"
export DPDK_DIR=/usr/src/dpdk-${DPDKRELEASE}
pushd $DPDK_DIR
#cd /usr/src/dpdk-16.11/
#export DPDK_DIR=/usr/src/dpdk-16.11
export DPDK_TARGET=x86_64-native-linuxapp-gcc
export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET

echo "Building DPDK ${DPDKRELEASE}"
sudo make install T=$DPDK_TARGET DESTDIR=install

sleep 5

# When getting this error
#make: *** /lib/modules/3.10.0-514.6.2.el7.x86_64/build: No such file or directory.  Stop.
# there was a newer kernel version available:
#$ uname -a
#Linux localhost.localdomain 3.10.0-514.6.2.el7.x86_64 
# Ran a "sudo yum upate" and installed kernel-3.10.0-514.10.2.el7.x86_64

# OVS pre-req's

# sudo yum install openssl-devel.x86_64 libcap-ng-devel.x86_64 libcap-ng.x86_64 python python-six.noarch autoconf.noarch automake.noarch libtool.x86_64
yum -y install libpcap

# OVS build
export OVSRELEASE=openvswitch-2.10.2
#cd /usr/src/openvswitch-2.7.0
pushd /usr/src/${OVSRELEASE}
./configure --with-dpdk=$DPDK_BUILD
echo "Building OpenVSwitch ${OVSRELEASE}"
make
sudo make install
