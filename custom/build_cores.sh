#!/bin/bash
# Build upstream cores for Miyoo Mini Plus (Cortex-A7) in the Onion toolchain container.
# usage: cores_build.sh core...   (pcsx_rearmed picodrive mame2003-plus-libretro)
cd /root/cores
mkdir -p out
for r in "$@"; do
  case $r in
    pcsx_rearmed) mk="-f Makefile.libretro" ;;
    picodrive) mk="-f Makefile.libretro LOW_MEMORY=1" ;;  # load CD images from path, not into the 128 MB RAM
    *) mk="" ;;
  esac
  echo "== building $r"
  docker run --rm -v /root/cores:/w -w "/w/$r" aemiii91/miyoomini-toolchain:latest bash -c "
    source /root/.bashrc
    export CC=\${CROSS_COMPILE}gcc CXX=\${CROSS_COMPILE}g++ AR=\${CROSS_COMPILE}ar AS=\${CROSS_COMPILE}as STRIP=\${CROSS_COMPILE}strip
    make $mk clean >/dev/null 2>&1
    nice -n 10 make $mk platform=classic_armv7_a7 -j16 > /w/out/$r.log 2>&1; echo exit=\$?
    so=\$(ls -t *_libretro.so | head -1); \${CROSS_COMPILE}strip --strip-unneeded \"\$so\"; cp \"\$so\" /w/out/
  "
  tail -3 "out/$r.log"
done
ls -la out/*.so
for f in out/*.so; do echo "-- $f"; readelf -A "$f" | grep -E "Tag_CPU_arch:|Tag_FP_arch|Tag_Advanced_SIMD" | tr -s ' ' | tr '\n' ';'; echo; done
