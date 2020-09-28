#!/bin/bash

numactl --hardware
echo ""
numastat -cm | egrep 'Node|Huge'
