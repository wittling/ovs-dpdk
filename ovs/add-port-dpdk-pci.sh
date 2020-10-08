#!/bin/bash

ovs-vsctl show
echo "which bridge?: "
read BRDG

PRT_TYP=dpdk

echo "name of port?: "
read PRT_NAME 
ovs-vsctl del-port $PRT_NAME

echo "port number?: "
read PRT_NUM

sudo lshw -class network -businfo
echo "Which PCI Address?: "
read PCI
echo "Assumed: This PCI address is using DPDK Drivers. If this fails, please check that proper DPDK drivers are in use on this PCI Address!"
ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} options:dpdk-devargs=${PCI} ofport_request=${PRT_NUM}
# ovs-vsctl add-port br-testdpdk dpdk0 -- set Interface dpdk0 type=dpdk options:dpdk-devargs=0000:01:00.0 ofport_request=1
