# After all this shit let us now attempt to create a bridge.
ovs-vsctl add-br br-testdpdk -- set bridge br-testdpdk datapath_type=netdev
if [ $? -ne 0 ]; then
   echo "error adding bridge br-testdpdk"
   exit 1
fi

# If we got here, it is time now to add our DPDK port to the bridge.
ovs-vsctl add-port br-testdpdk dpdk0 -- set Interface dpdk0 type=dpdk options:dpdk-devargs=0000:01:00.0

# Add a vhostuserclient port to the bridge now.
ovs-vsctl add-port br-testdpdk dpdkvhostclient0     -- set Interface dpdkvhostclient0 type=dpdkvhostuserclient \
 options:vhost-server-path=/tmp/dpdkvhostclient0
