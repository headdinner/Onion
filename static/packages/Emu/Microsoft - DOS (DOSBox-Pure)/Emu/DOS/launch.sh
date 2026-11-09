#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
homedir=`dirname "$1"`

core=dosbox_pure_libretro.so
# Onion custom: Betrayal at Krondor needs the 0.9.7 core (its gamepad mapper puts the mouse on the D-pad)
case "$(basename "$1")" in
    "Betryal At Krondor.zip") core=dosbox_pure_0.9.7_libretro.so ;;
esac

cd /mnt/SDCARD/RetroArch/
HOME=/mnt/SDCARD/RetroArch/ $progdir/../../RetroArch/retroarch -v -L $progdir/../../RetroArch/.retroarch/cores/$core "$1"
