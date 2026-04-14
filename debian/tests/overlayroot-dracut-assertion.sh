#!/bin/sh
set -eu

# required binaries: cat grep

check_compat_symlink() {
    if ! [ -L /media/root-ro ]; then
        echo "missing compatibility symlink: /media/root-ro" >> /run/failed
    fi
    if ! [ -e /media/root-ro/usr/lib/os-release ]; then
        echo "/media/root-ro/usr/lib/os-release does not exist. Broken /media/root-ro symlink?" >> /run/failed
    fi
}

if grep -q 'test.expect=none' /proc/cmdline; then
    if grep -q " overlay " /proc/mounts; then
        echo "overlay filesystem found in /proc/mounts" >> /run/failed
    fi
else
    if ! grep -q " overlay " /proc/mounts; then
        echo "overlay filesystem not found in /proc/mounts" >> /run/failed
    fi

    if ! echo > /test-overlay-write; then
        echo "overlay is not writable" >> /run/failed
    fi

    if grep -q overlayroot /proc/cmdline; then
        check_compat_symlink
    fi
fi

if grep -q 'test.expect=device' /proc/cmdline; then
    if ! grep -q "/run/overlayfs-backing" /proc/mounts; then
        echo "persistent overlay device not mounted at /run/overlayfs-backing" >> /run/failed
    fi
else
    if grep -q "/run/overlayfs-backing" /proc/mounts; then
        echo "persistent overlay device is mounted at /run/overlayfs-backing" >> /run/failed
    fi
fi

# Dump /proc/mounts at the end if there were any failures for easier debugging
if [ -s /run/failed ]; then
    {
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> /proc/mounts >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        cat /proc/mounts
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< /proc/mounts <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    } >> /run/failed
fi
