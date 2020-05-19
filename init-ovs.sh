ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x2
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-limit="1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=2

ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vswitchd --version
ovs-vsctl get Open_vSwitch . dpdk_version
