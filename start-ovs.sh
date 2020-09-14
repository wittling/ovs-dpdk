
# Create the database
ovsdb-tool create /usr/local/etc/openvswitch/conf.db /usr/local/share/openvswitch/vswitch.ovsschema

# Start the daemon
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                     --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                     --private-key=db:Open_vSwitch,SSL,private_key \
                     --certificate=db:Open_vSwitch,SSL,certificate \
                     --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
                     --pidfile --detach

# Check and make sure that you are running as root!!!

# Initialize DPDK with OVS
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true

export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock

ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start
if [ $? -ne 0 ]; then
   echo "Error starting ovs-ctl"
   exit 1
fi

ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
if [ $? -ne 0 ]; then
   echo "Error setting dpdk-socket-mem"
   exit 1
fi

ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-limit="1024"
if [ $? -ne 0 ]; then
   echo "Error setting dpdk-socket-limit"
   exit 1
fi

#Check OpenVSwitch have DPDK enable:
ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vswitchd --version
ovs-vsctl get Open_vSwitch . dpdk_version

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
