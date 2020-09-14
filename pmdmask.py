#!/usr/bin/env python3

import sys

print("PMD Mask calculator")
print("*******************\n\n")
numcores = input("How many cores in the system?")
if int(numcores) % 4 != 0:
    print(
        "No Support for core totals not being divisble by 4. Number of cores = {}".format(
            numcores))
    sys.exit(1)
pmdlist = ' '
while ' ' in pmdlist:
    pmdlist = input(
        "Which cores for PMDS? (use command separated list; ex: 5,7,9,11):")
    if ' ' in pmdlist:
        print("No spaces please")

pmdlist = pmdlist.split(',')
binstr = str()
for x in range(int(numcores)):
    if str(x) in pmdlist:
        binstr = '1' + binstr
    else:
        binstr = '0' + binstr

print("Binary string for PMD mask = {}".format(binstr))

print("Converting to PMD mask")

pmdmask = str()
pointer = 4
starter = 0
while pointer <= len(binstr):
    pmdmask += str(hex(int(binstr[starter:pointer][::-1], 2))).replace('0x', '')
    starter += 4
    pointer += 4

print("Use PMD Mask of {}".format(pmdmask))
