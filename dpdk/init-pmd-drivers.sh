#!/bin/bash

echo "which drivers do you which to use: (vfio | igb_uio | uio_pci_generic)"
read driver
if [ ${driver} == "igb_uio" ]; then
   if [ -f /root/rpmbuild/BUILD/dpdk-stable-18.11.8/x86_64-default-linuxapp-gcc/kmod/igb_uio.ko ]; then
      echo "loading kernel module:  /root/rpmbuild/BUILD/dpdk-stable-18.11.8/x86_64-default-linuxapp-gcc/kmod/igb_uio.ko"
      insmod /root/rpmbuild/BUILD/dpdk-stable-18.11.8/x86_64-default-linuxapp-gcc/kmod/igb_uio.ko
   else
      echo "File Not Found: /root/rpmbuild/BUILD/dpdk-stable-18.11.8/x86_64-default-linuxapp-gcc/kmod/igb_uio.ko"
   fi
elif [ ${driver} == "uio_pci_generic" ]; then
   modprobe uio_pci_generic
else
   modprobe vfio
fi
