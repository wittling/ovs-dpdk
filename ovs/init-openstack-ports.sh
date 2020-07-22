# compute node provider setup

#ovs-vsctl add-br br-prv -- set bridge br-prv datapath_type=netdev

ovs-vsctl add-port br-prv dpdk0 -- set Interface dpdk0 type=dpdk options:dpdk-devargs=0000:01:00.0 ofport_request=1

# I assume this gets port 2 without explicitly configuring that.
# I think OpenStack actually manages this port including setup and teardown.
#ovs-vsctl add-port br-prv phy-br-prv
#ovs-vsctl set interface phy-br-prv type=patch
#ovs-vsctl set interface phy-br-prv options:peer=int-br-prv

ovs-vsctl add-port br-prv vhostusrclt3 -- set Interface vhostusrclt3 type=dpdkvhostuser ofport_request=3
ovs-vsctl add-port br-prv vhostusrclt4 -- set Interface vhostusrclt4 type=dpdkvhostuser ofport_request=4

