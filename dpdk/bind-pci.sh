#!/bin/bash

# driverctl unset-override 0000:01:00.0
#driverctl set-override 0000:01:00.0 vfio
driverctl set-override 0000:01:00.0 uio_pci_generic
driverctl set-override 0000:01:00.1 uio_pci_generic

dpdk-devbind --status 
