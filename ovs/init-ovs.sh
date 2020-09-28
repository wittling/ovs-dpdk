#!/bin/bash
## This script is an initialization script for OVS, designed to be run after the OVS service has started.
## Keep in mind, that when the service is started, flags passed into OVS are defined in /etc/sysconfig/openvswitch.
## For example, OVS is run as root when DPDK is used, per the DPDK Getting Started Guide.
##
## One important thing to remember is that just because you initialize OVS with DPDK, this does NOT mean
## that your bridges are using DPDK. Any bridge using DPDK needs to be setting the datapath to netdev and not
## system! You do not see that here in this script, because it is assumed that bridges are created and managed
## in an ad-hoc manner after the switch is up, running and initialized.

ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true

# ring buffer same as memory pool.
# shared memory means ports all use same ring buffer memory pool.
# dedicated means ports all use their own ring buffer memory pool.
# default is shared.
# ovs-vsctl --no-wait set Open_vSwitch . other_config:per-port-memory="true"


# calculating memory is MTU x PMD x RXQ 
#ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x2
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-limit="2048"

# ring buffer same as memory pool.
# shared memory means ports all use same ring buffer memory pool.
# dedicated means ports all use their own ring buffer memory pool.
#ovs-vsctl --no-wait set Open_vSwitch . other_config:per-port-memory="true"

# The lcore thread are management threads - overhead threads, if you will. You can run your lcore thread on 
# same core as the OS, or you can dedicate a CPU core to it, or even put it on same cores as where the PMD
# cores are running. There are a couple of scripts that can calculate your masks for you since the mask 
# calculation is a bit mathematical (cryptic) and therefore, prone to error if done by hand.

# core 0 used by OS, core 1 for lcore thread and cores 2 and 3 for pmd threads to do packet forwarding
#ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask="0x4"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x2
#ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask="0x8"
ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask="0xC"
#ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=2

# In some OVS versions the lcore mask must be set before OVS is initialized with DPDK.
# The pmd mask can be changed on the fly hot - no restart required.
ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true

# Notice these are GET commands - designed to show you that the settings above worked.
ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vswitchd --version
ovs-vsctl get Open_vSwitch . dpdk_version

# suppresses tons of OVS errors about not being able to connect to a controller
ovs-vsctl set-fail-mode br-tun standalone

# set datapath on specific bridges
for br in `ovs-vsctl list-br`
do
   echo -c "Datapath for $br [system|netdev]: "
   read dp
   if [ $dp != "system" -o $dp != "netdev" ]; then
      ovs-vsctl set bridge $br datapath_type=$dp
   else
      echo "unrecognized dp: using system"
   fi
done
