# THIS IS FOR GUIDANCE
# NOT INTENDED TO BE RUN


https://mail.openvswitch.org/pipermail/ovs-dev/2017-January/327611.html


Hi all,

This might not be the correct place to dump this, but it might help 
people reading this dev list trying to setup something similar on Fedora.

Enjoy,

Eelco


# Install Fedora 25 Server edition


# Update and install needed packages
dnf -y update
dnf -y install wget emacs libvirt qemu-kvm libguestfs libguestfs-tools-c \
   kernel-devel gcc rpm-build autoconf automake libtool systemd-units \
   openssl openssl-devel python python-twisted-core python-zope-interface \
   python-six desktop-file-utils groff graphviz procps-ng checkpolicy \
   selinux-policy-devel libcap-ng libcap-ng-devel


# Setting up kernel for DPDK

sed -i -e 
's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="default_hugepagesz=1G 
hugepagesz=1G hugepages=16 iommu=pt intel_iommu=on /' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

reboot


# Get and build DPDK
cd /usr/src
wget http://fast.dpdk.org/rel/dpdk-16.11.tar.xz
tar xf dpdk-16.11.tar.xz

echo 'export DPDK_DIR=/usr/src/dpdk-16.11' >> ~/.bashrc
echo 'export DPDK_TARGET=x86_64-native-linuxapp-gcc' >> ~/.bashrc
echo 'export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET' >> ~/.bashrc
source ~/.bashrc
cd $DPDK_DIR
make -j 20 install T=$DPDK_TARGET DESTDIR=install


# Get, build and setup OVS

cd /usr/src
wget http://openvswitch.org/releases/openvswitch-2.6.1.tar.gz
tar xzf openvswitch-2.6.1.tar.gz
cd openvswitch-2.6.1/
./boot.sh
./configure --enable-Werror --with-dpdk=$DPDK_BUILD
make -j20
make check TESTSUITEFLAGS=-j20
make install

mkdir -p /usr/local/etc/openvswitch
mkdir -p /usr/local/var/run/openvswitch
ovsdb-tool create /usr/local/etc/openvswitch/conf.db \
   vswitchd/vswitch.ovsschema


# Start OVS

ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
   --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
   --pidfile --detach

ovs-vsctl --no-wait init

ovs-vswitchd --pidfile --detach --log-file


# Configure OVS

ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true
ovs-vsctl set Open_vSwitch . other_config:dpdk-lcore-mask=0x2
ovs-vsctl set Open_vSwitch . other_config:dpdk-socket-mem=2048
ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=2

killall ovs-vswitchd
ovs-vswitchd --pidfile --detach --log-file

ovs-vsctl add-br br0
ovs-vsctl set Bridge br0 datapath_type=netdev
ovs-vsctl add-port br0 vhost0
ovs-vsctl set Interface vhost0 type=dpdkvhostuserclient
ovs-vsctl set Interface vhost0 options:vhost-server-path="/tmp/sock0"
ovs-vsctl add-port br0 vhost1
ovs-vsctl set Interface vhost1 type=dpdkvhostuserclient
ovs-vsctl set Interface vhost1 options:vhost-server-path="/tmp/sock1"


# Get VM image, and make a copy

cd
export LIBGUESTFS_BACKEND=direct
virt-builder fedora-25 --root-password password:fedora -o f25vm1.qcow2 
--format qcow2
cp f25vm1.qcow2 f25vm2.qcow2


# Start the VMs

qemu-kvm -cpu host -enable-kvm -m 4096M \
   -object 
memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
   -numa node,memdev=mem -mem-prealloc \
   -drive file=./f25vm1.qcow2 \
   -chardev socket,id=char0,path=/tmp/sock0,server \
   -netdev type=vhost-user,id=mynet1,chardev=char0,vhostforce \
   -device 
virtio-net-pci,mac=00:00:00:00:00:01,netdev=mynet1,mrg_rxbuf=off \
   -nographic

qemu-kvm -cpu host -enable-kvm -m 4096M \
   -object 
memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
   -numa node,memdev=mem -mem-prealloc \
   -drive file=./f25vm2.qcow2 \
   -chardev socket,id=char0,path=/tmp/sock1,server \
   -netdev type=vhost-user,id=mynet1,chardev=char0,vhostforce \
   -device 
virtio-net-pci,mac=00:00:00:00:00:02,netdev=mynet1,mrg_rxbuf=off \
   -nographic


# Configure networking on the VMs and make sure you can communicate


#
# Now kill qemu, and reconfigure OVS for server mode,start VMs
#

killall qemu-system-x86_64

ovs-vsctl set Interface vhost0 type=dpdkvhostuser
ovs-vsctl set Interface vhost1 type=dpdkvhostuser

qemu-kvm -cpu host -enable-kvm -m 4096M \
   -object 
memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
   -numa node,memdev=mem -mem-prealloc \
   -drive file=./f25vm1.qcow2 \
   -chardev socket,id=char0,path=/usr/local/var/run/openvswitch/vhost0 \
   -netdev type=vhost-user,id=mynet1,chardev=char0,vhostforce \
   -device 
virtio-net-pci,mac=00:00:00:00:00:01,netdev=mynet1,mrg_rxbuf=off \
   -nographic

qemu-kvm -cpu host -enable-kvm -m 4096M \
   -object 
memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
   -numa node,memdev=mem -mem-prealloc \
   -drive file=./f25vm2.qcow2 \
   -chardev socket,id=char0,path=/usr/local/var/run/openvswitch/vhost1 \
   -netdev type=vhost-user,id=mynet1,chardev=char0,vhostforce \
   -device 
virtio-net-pci,mac=00:00:00:00:00:02,netdev=mynet1,mrg_rxbuf=off \
   -nographic
