#!/bin/bash

numactl --hardware
echo ""
numastat -cm | egrep 'Node|Huge'
echo ""
grep huge /proc/*/numa_maps
