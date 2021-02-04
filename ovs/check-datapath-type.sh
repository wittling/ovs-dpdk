#!/bin/bash

ovs-vsctl list bridge | grep -e name -e datapath_type
