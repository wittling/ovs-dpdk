#!/bin/bash

echo "Checking kernel cmdline..."
cat /proc/cmdline | grep -i Huge

echo "Checking /dev/hugepages"
if [ -d /dev/hugepages ]; then
   echo "Exists"
else
   echo "Not Exists"
fi

echo "Checking to see if it is mounted..."
mount | grep -i hugepages
if [ $? -eq 0 ]; then
   echo "Mounted"
else
   echo "Not Mounted"
fi

echo "Checking meminfo..."
cat /proc/meminfo | grep -i HugePage
