#!/bin/bash

ovs-vsctl show
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
   VHOST_SOCK_PATH="/var/run/openvswitch/${PRT_NAME}.sock"
   ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} "options:vhost-server-path=${VHOST_SOCK_PATH}" ofport_request=${PRT_NUM}
else
   ovs-vsctl add-port ${BRDG} ${PRT_NAME} -- set Interface ${PRT_NAME} type=${PRT_TYP} ofport_request=${PRT_NUM}
fi
#ovs-ofctl show ${BRDG}
ovs-vsctl show 
