#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
homedir=`dirname "$1"`

# Onion custom: give RetroArch one canonical rom path, so the remembered disc (.ldci)
# matches whether the game was started from the list, favourites or the game switcher (#813)
romdir=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)
if [ -n "$romdir" ]; then rompath="$romdir/$(basename "$1")"; else rompath="$1"; fi

cd /mnt/SDCARD/RetroArch/
HOME=/mnt/SDCARD/RetroArch/ $progdir/../../RetroArch/retroarch -v -L $progdir/../../RetroArch/.retroarch/cores/picodrive_libretro.so "$rompath"
