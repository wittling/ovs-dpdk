#!/bin/bash

#ovs-vsctl show | grep Bridge
ovs-vsctl list-br
echo "which bridge?: "
read BRDG

echo "port type: (dpdkvhostuser | dpdkvhostuserclient):"
read PRT_TYP

echo "name of port: "
read PRT_NAME 

ovs-ofctl show ${BRDG}
echo "port number: "
read PRT_NUM

if [ ${PRT_TYP} == "dpdkvhostuserclient" ]; then
   VHOST_SOCK_PATH="/var/lib/libvirt/qemu/vhost_sockets/${PRT_NAME}"
#   VHOST_SOCK_PATH="/tmp/${PRT_NAME}"
   ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} "options:vhost-server-path=${VHOST_SOCK_PATH}" ofport_request=${PRT_NUM}
else
   ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} ofport_request=${PRT_NUM}
fi
#ovs-ofctl show ${BRDG}
#ovs-vsctl show 

# This one shows numbers AND names (and other stuff)
ovs-ofctl show ${BRDG}
# This one just shows names below.
#ovs-vsctl list-ports br-tun
echo ""
echo "Enter port number for physical DPDK interface do you want to plumb your vhost port TO:"
echo ""
read DPDK_PCI_PORT
# should be validated.

RC=`ovs-ofctl dump-flows ${BRDG} | grep "in_port=${DPDK_PCI_PORT} action"`
if [ $? -eq 0 ]; then
   PORT_INUSE=`ovs-ofctl dump-flows ${BRDG} | grep "in_port=1 " | grep output | cut -f2 -d":"`
   PORT_INUSE_NAME=`ovs-ofctl show ${BRDG} | grep "${PORT_INUSE}(" | cut -f1 -d":"`
   echo "This PCI in_port is already used by another port: $PORT_INUSE_NAME"
   #ovs-ofctl dump-flows ${BRDG} | grep "in_port=${DPDK_PCI_PORT} " | grep output
else
   echo "port NOT used!"
   echo "adding flow $PRT_NUM -> $DPDK_PCI_PORT"
   ovs-ofctl add-flow ${BRDG} in_port=$PRT_NUM,action=output:$DPDK_PCI_PORT
   echo "adding flow $DPDK_PCI_PORT -> $PRT_NUM"
   ovs-ofctl add-flow ${BRDG} in_port=$DPDK_PCI_PORT,action=output:$PRT_NUM
fi
