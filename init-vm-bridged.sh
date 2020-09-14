# Start the VMs

#qemu-kvm -cpu host -enable-kvm -m 4096M \
#kvm -cpu host -enable-kvm -m 4096M \
#   -object
#memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
#   -numa node,memdev=mem -mem-prealloc \
#   -drive file=/opt/images/${VMNAME} \
#   -chardev socket,id=char0,path=/tmp/sock0,server \
#   -netdev type=vhost-user,id=dpdkvhostuserclient0,chardev=char0,vhostforce \
#   -device
#virtio-net-pci,mac=00:00:00:00:00:01,netdev=mynet1,mrg_rxbuf=off \
#   -nographic

echo "VM Name: "
read VM_NAME
export VM_NAME

echo "Mem (i.e. 2048M - M is required): "
read GUEST_MEM
export GUEST_MEM

IMGNAME=400-SVR1-Cent7-merged-v1.qcow2
#export QCOW2_IMAGE=/root/CentOS7_x86_64.qcow2
export QCOW2_IMAGE=/opt/images/${IMGNAME}

echo "enter mac last digit"
read MAC
brctl show
echo "enter Bridge: "
read BRG

# create a tap interface
ip l del tap${MAC}
ip tuntap add name tap${MAC} mode tap
echo "Bridge: ovs | linux"
read MGR
if [ ${MGR} == "ovs" ];then
   ovs-vsctl add-port ${BRG} tap${MAC}
elif [ ${MGR} == "linux" ];then
   brctl addif ${BRG} tap${MAC}
else
   echo "ovs or linux expected. exiting."
   exit 1
fi

# It will report as down until someone starts writing to it.
ip l set tap${MAC} up

echo "Starting VM..."
/usr/libexec/qemu-kvm -name $VM_NAME -cpu host -enable-kvm \
  -m $GUEST_MEM -drive file=$QCOW2_IMAGE --nographic -snapshot \
  -numa node,memdev=mem -mem-prealloc -smp sockets=1,cores=2 \
  -object memory-backend-file,id=mem,size=$GUEST_MEM,mem-path=/dev/hugepages,share=on \
  -netdev tap,id=hostnet0,ifname=tap${MAC},script=no,downscript=no \
  -device virtio-net-pci,netdev=hostnet0,id=net0,mac=00:00:00:00:00:0${MAC} -chardev pty,id=serial1

# -net bridge,id=br0,br=${BRG} \
#-chardev socket,id=char${MAC},path=${VHOST_SOCK_DIR}/${VHOST_PORT} \
#-device virtio-net-pci,mac=00:00:00:00:00:0${MAC},netdev=default,mrg_rxbuf=off,mq=on,vectors=6
