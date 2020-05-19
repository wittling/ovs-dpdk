# Install ovs-dpdk
# Copyright Dotslash.Lu <dotslash.lu@gmail.com>
#
# NOTE:
#   Please add `iommu=pt intel_iommu=on` to grub bootline and
#   reboot
#
#   Installation will cause NETWORK LOST, so it's better to
#   execute this script within an admin console
#

# check IOMMU
echo "Checking boot command line"
if ! cat /proc/cmdline | grep intel_iommu; then
    echo "Failed, please add \`iommu=pt intel_iommu=on\` to" \
            "boot command line and reboot"
    exit
else
    echo "PASS: intel_iommu found on boot"
fi

# cleaning
echo "Installing pciutils and kernel-devel packages..."
yum install -y pciutils kernel-devel
echo "Erasing openvswitch, openvswitch-devel, openvswitch-kmod, openvswitch-debuginfo, and openvswitch-mod-debuginfo packages..."
yum erase -y openvswitch openvswitch-devel openvswitch-kmod \
		openvswitch-debuginfo openvswitch-kmod-debuginfo
echo "Removing directories /etc/openvswitch, /var/run/openvswitch, and /usr/share/openvswitch"
echo "Hit Ctl-C if you do NOT want to do this!"
sleep 8
rm -rf /etc/openvswitch /var/run/openvswitch /usr/share/openvswitch

# install rpms
echo
echo "Here are the rpms that will be installed"
tar -tvzf ovs-dpdk_rpms.tgz
sleep 8
echo "Installing ovs-dpdk_rpms.tgz"
tar -xzf ovs-dpdk_rpms.tgz
yum localinstall -y *.rpm

# insert kmod
echo
echo "Inserting kmods vfio-pci and openvswitch"
modprobe vfio-pci
modprobe openvswitch
echo "vfio-pci" > /etc/modules-load.d/vfio-pci.conf
echo "openvswitch" > /etc/modules-load.d/openvswitch.conf

# bind NIC to vfio-pci
echo
echo "Binding NICs to vfio-pci"
chmod a+x /dev/vfio
chmod 0666 /dev/vfio/*
nics=$(driverctl -v list-devices | grep -i net | gawk '{print $1}')
if [-z $nics]; then
    echo "Can't get NICs to bind"
    exit
fi

for nic in $nics; do
    echo "Binding NIC ${nic}"
    driverctl set-override ${nic} vfio-pci
done

echo
echo "Allocating hugepages"
# allocate 1024 2M hugepages
sysctl -w vm.nr_hugepages=1024
# make hugepage setting persistent
echo "vm.nr_hugepages=1024" > /etc/sysctl.d/hugepages.conf
# mount hugepages
mount -t hugetlbfs none /dev/hugepages

echo
echo "Configuring ovs"
systemctl start openvswitch
# enable dpdk
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
# pin pmd threads to cores 1, 2
ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=6
sleep 2
systemctl restart openvswitch

echo
echo "Adding ports"
ovs-vsctl add-br ovsbr0 -- set bridge ovsbr0 datapath_type=netdev
#ovs-vsctl add-bond ovsbr0 dpdkbond dpdk0 dpdk1 \
#     -- set Interface dpdk0 type=dpdk \
#     -- set Interface dpdk1 type=dpdk

ovs-vsctl add-br ovsbr1 -- set bridge ovsbr1 datapath_type=netdev
#ovs-vsctl add-bond ovsbr1 dpdkbond1 dpdk2 dpdk3 \
#     -- set Interface dpdk2 type=dpdk \
#     -- set Interface dpdk3 type=dpdk

echo
ovs-vsctl show
