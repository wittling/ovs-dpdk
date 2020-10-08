#!/bin/bash

lshw -class network -businfo | grep pci

while :
do
   echo "Linux Interface to override (e.g. p1p1, p1p2, p1p3, p1p4):"
   read iface
   lshw -class network -businfo | grep pci | grep ${iface}
   if [ $? -eq 0 ]; then
      pci=`lshw -class network -businfo | grep pci | grep ${iface} | awk '{printf $1}' | cut -f2 -d"@"`
      echo "We will override PCI address: ${pci}"
      break 
   fi
done

#driverctl unset-override 0000:01:00.0
#driverctl set-override 0000:01:00.0 vfio-pci
#driverctl set-override 0000:01:00.0 uio_pci_generic
echo "driverctl set-override ${pci} uio_pci_generic"
driverctl set-override ${pci} uio_pci_generic

dpdk-devbind --status 
