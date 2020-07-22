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

echo "Ports available: "
ovs-vsctl show | grep Interface | grep vhost

echo "enter ovs vhost port to attach vm to: "
read VHOST_PORT

echo $VHOST_PORT | grep vhostusrclt
if [ $? -eq 0 ]; then
   PORT_TYPE=vhost-user-client
else
   PORT_TYPE=vhost-user
fi
echo "PORT_TYPE: ${PORT_TYPE}"


if [ $PORT_TYPE == "vhost-user" ]; then
   export VHOST_SOCK_DIR=/var/run/openvswitch

# the vhostuser does not have the server parameter.
/usr/libexec/qemu-kvm -name $VM_NAME -cpu host -enable-kvm \
  -m $GUEST_MEM -drive file=$QCOW2_IMAGE --nographic -snapshot \
  -numa node,memdev=mem -mem-prealloc -smp sockets=1,cores=2 \
  -object memory-backend-file,id=mem,size=$GUEST_MEM,mem-path=/dev/hugepages,share=on \
  -chardev socket,id=char${MAC},path=${VHOST_SOCK_DIR}/${VHOST_PORT} \
  -netdev type=vhost-user,id=default,chardev=char${MAC},vhostforce,queues=2 \
  -device virtio-net-pci,mac=00:00:00:00:00:0${MAC},netdev=default,mrg_rxbuf=off,mq=on,vectors=6

else
# vhost-user-client
export VHOST_SOCK_DIR="/var/run/openvswitch"

   # If client mode make sure the OVS-DPDK created the server mode socket
   if [ -S "${VHOST_SOCK_DIR}/${VHOST_PORT}.sock" ]; then
      echo "OVS-DPDK vhostuser server mode socket located!"
      echo "${VHOST_SOCK_DIR}/${VHOST_PORT}.sock"
      #echo "VHOST_PORT: ${VHOST_PORT}"
  else
      echo "OVS-DPDK vhostuser server mode socket not found!"
      echo "${VHOST_SOCK_DIR}/${VHOST_PORT}.sock"
#      exit 1
  fi

echo "Starting VM..."
/usr/libexec/qemu-kvm -name $VM_NAME -cpu host -enable-kvm \
  -m $GUEST_MEM -drive file=$QCOW2_IMAGE --nographic -snapshot \
  -numa node,memdev=mem -mem-prealloc -smp sockets=1,cores=2 \
  -object memory-backend-file,id=mem,size=$GUEST_MEM,mem-path=/dev/hugepages,share=on \
  -chardev socket,id=char1,path=/var/run/openvswitch/${VHOST_PORT}.sock,server \
  -netdev type=vhost-user,id=default,chardev=char1,vhostforce,queues=2 \
  -device virtio-net-pci,mac=00:00:00:00:00:0${MAC},netdev=default,mrg_rxbuf=off,mq=on,vectors=6

#  -chardev socket,id=char1,path=/tmp/vhostusrclt1 \
fi

#qemu-system-x86_64 -name $VM_NAME -cpu host -enable-kvm \
#/usr/libexec/qemu-kvm -name $VM_NAME -cpu host -enable-kvm \
#  -m $GUEST_MEM -drive file=$QCOW2_IMAGE --nographic -snapshot \
#  -numa node,memdev=mem -mem-prealloc -smp sockets=1,cores=2 \
#  -object memory-backend-file,id=mem,size=$GUEST_MEM,mem-path=/dev/hugepages,share=on \
#  -chardev socket,id=char0,path=$VHOST_SOCK_DIR/dpdkvhostuser0 \
#  -netdev type=vhost-user,id=default,chardev=char0,vhostforce \
#  -device virtio-net-pci,mac=00:00:00:00:00:01,netdev=default,mrg_rxbuf=off \
#  -chardev socket,id=char1,path=$VHOST_SOCK_DIR/dpdkvhostuser1 \
#  -netdev type=vhost-user,id=routed-22,chardev=char1,vhostforce \
#  -device virtio-net-pci,mac=00:00:00:00:00:01,netdev=routed-22,mrg_rxbuf=off
