echo "Checking boot command line"
if ! cat /proc/cmdline | grep intel_iommu; then
    echo "FAIL: please add \`iommu=pt intel_iommu=on\` to" \
            "boot command line and reboot"
    echo "Checking DMESG as a double check..."
    if dmesg | grep "IOMMU enabled"; then
       echo "PASS: DMESG shows IOMMU as enabled"
       exit 0
    else
       echo "FAIL: DMESG does not show IOMMU enabled"
       exit 1
    fi
else
    echo "PASS: intel_iommu found on boot"
    exit 0
fi
