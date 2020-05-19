# Start the VMs

VMNAME=400-SVR1-Cent7-merged-v1.qcow2

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

#qemu-system-x86_64 -cpu host -enable-kvm -m 4096M -object memory-backend-file,id=mem,size=4096M,mem-path=/mnt/hugepages,share=on -numa node,memdev=mem -mem-prealloc  -drive file=${VMNAME} -chardev socket,id=char0,path=/tmp/sock0,server -netdev type=vhost-user,id=default,chardev=char0,vhostforce -device virtio-net-pci,mac=00:00:00:00:00:01,netdev=vhost0,mrg_rxbuf=off –nographic

/usr/libexec/qemu-kvm -vvv -cpu host -enable-kvm -m 4096M -object memory-backend-file,id=mem,size=4096M,mem-path=/mnt/hugepages,share=on -numa node,memdev=mem -mem-prealloc  -drive file=/opt/images/${VMNAME} -chardev socket,id=char0,path=/tmp/sock0,server -netdev type=vhost-user,id=default,chardev=char0,vhostforce -device virtio-net-pci,mac=00:00:00:00:00:01,netdev=vhost0,mrg_rxbuf=off –nographic

