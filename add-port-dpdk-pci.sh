#!/bin/bash

ovs-vsctl show
echo "which bridge?: "
read BRDG

echo "port type: (dpdkvhostuser | dpdkvhostuserclient | dpdk):"
read PRT_TYP

echo "name of port?: "
read PRT_NAME 
ovs-vsctl del-port $PRT_NAME

echo "port number?: "
read PRT_NUM

if [ ${PRT_TYP} == "dpdk" ]; then
   sudo lshw -class network -businfo
   echo "Which PCI Address?: "
   read PCI
   ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} options:dpdk-devargs=${PCI} ofport_request=${PRT_NUM}
# ovs-vsctl add-port br-testdpdk dpdk0 -- set Interface dpdk0 type=dpdk options:dpdk-devargs=0000:01:00.0 ofport_request=1
else
   ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} ofport_request=${PRT_NUM}
fi
