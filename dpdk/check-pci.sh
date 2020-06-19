#!/bin/bash

sudo lshw -class network -businfo

dpdk-devbind --status
