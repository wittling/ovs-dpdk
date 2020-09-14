#!/bin/bash

# top -H can also be used for this!

ps -eLo pid,psr,comm | grep pmd
