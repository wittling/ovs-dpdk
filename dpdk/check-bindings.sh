#!/bin/bash

dpdk-devbind --status

# driverctl unset-override 0000:01:00.0
#driverctl set-override 0000:01:00.0 vfio
#driverctl set-override 0000:01:00.0 uio_pci_generic
