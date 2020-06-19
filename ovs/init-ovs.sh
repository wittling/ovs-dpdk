ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true
#ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x2
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-limit="1024"
#ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=2


# core 0 used by OS, core 1 for lcore thread and cores 2 and 3 for pmd threads to do packet forwarding
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask="0x2"
ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask="0xC"


ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vswitchd --version
ovs-vsctl get Open_vSwitch . dpdk_version
