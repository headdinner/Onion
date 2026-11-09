#!/bin/bash
# Build mgba, gambatte, scummvm for Miyoo Mini Plus (Cortex-A7) in the Onion toolchain container.
# usage: cores_build2.sh [mgba] [gambatte] [scummvm]
cd /root/cores
mkdir -p out patches
A7="-marm -mcpu=cortex-a7 -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections"

# Onion's ScummVM shortcuts end in .target (content = game/target id); upstream only accepts .scummvm
python3 - <<'PY'
p = '/root/cores/scummvm/backends/platform/libretro/src/libretro-core.cpp'
s = open(p).read()
old = "\t\tif (!(target_file_ext_pos < 0) && strstr(game->path + target_file_ext_pos, target_file_ext) != NULL) {"
new = ("\t\t// Onion OS: .target shortcut files hold a target id, same as .scummvm\n"
       "\t\tint onion_target_ext_pos = strlen(game->path) - strlen(\".target\");\n"
       "\t\tbool onion_target_file = onion_target_ext_pos >= 0 && strcmp(game->path + onion_target_ext_pos, \".target\") == 0;\n"
       "\t\tif ((!(target_file_ext_pos < 0) && strstr(game->path + target_file_ext_pos, target_file_ext) != NULL) || onion_target_file) {")
if 'onion_target_file' not in s:
    assert s.count(old) == 1, 'anchor not found'
    open(p, 'w').write(s.replace(old, new))
print('scummvm .target patch applied')
PY
git -C scummvm diff > patches/scummvm-onion-target-ext.patch

for r in "$@"; do
  echo "== building $r"
  case $r in
    mgba)
      docker run --rm -v /root/cores:/w -w /w/mgba aemiii91/miyoomini-toolchain:latest bash -c "
        source /root/.bashrc
        rm -rf build-a7 && mkdir build-a7 && cd build-a7
        cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=arm \
          -DCMAKE_C_COMPILER=\${CROSS_COMPILE}gcc -DCMAKE_CXX_COMPILER=\${CROSS_COMPILE}g++ \
          -DCMAKE_C_FLAGS='$A7' -DCMAKE_CXX_FLAGS='$A7' -DCMAKE_SHARED_LINKER_FLAGS='-Wl,--gc-sections' \
          -DBUILD_LIBRETRO=ON -DSKIP_LIBRARY=ON -DBUILD_QT=OFF -DBUILD_SDL=OFF -DBUILD_GL=OFF -DBUILD_GLES2=OFF -DBUILD_GLES3=OFF \
          -DBUILD_PERF=OFF -DBUILD_TEST=OFF -DBUILD_SUITE=OFF -DBUILD_CINEMA=OFF -DBUILD_EXAMPLE=OFF -DBUILD_UPDATER=OFF \
          -DUSE_FFMPEG=OFF -DUSE_PNG=OFF -DUSE_LIBZIP=OFF -DUSE_MINIZIP=OFF -DUSE_SQLITE3=OFF -DUSE_ELF=OFF -DUSE_LZMA=OFF \
          -DUSE_EDITLINE=OFF -DUSE_EPOXY=OFF -DUSE_GDB_STUB=OFF -DUSE_DISCORD_RPC=OFF -DENABLE_SCRIPTING=OFF -DUSE_LUA=OFF -DUSE_JSON_C=OFF \
          -DM_CORE_GB=ON -DM_CORE_GBA=ON > /w/out/mgba.log 2>&1 && nice -n 10 make -j16 mgba_libretro >> /w/out/mgba.log 2>&1; echo exit=\$?
        so=\$(find . -name 'mgba_libretro.so' | head -1); \${CROSS_COMPILE}strip --strip-unneeded \"\$so\" && cp \"\$so\" /w/out/
      " ;;
    gambatte)
      docker run --rm -v /root/cores:/w -w /w/gambatte-libretro aemiii91/miyoomini-toolchain:latest bash -c "
        source /root/.bashrc
        export CC=\${CROSS_COMPILE}gcc CXX=\${CROSS_COMPILE}g++ AR=\${CROSS_COMPILE}ar CFLAGS='$A7' CXXFLAGS='$A7'
        make -f Makefile.libretro clean >/dev/null 2>&1
        nice -n 10 make -f Makefile.libretro platform=unix -j16 > /w/out/gambatte.log 2>&1; echo exit=\$?
        \${CROSS_COMPILE}strip --strip-unneeded gambatte_libretro.so && cp gambatte_libretro.so /w/out/
      " ;;
    scummvm)
      docker run --rm -v /root/cores:/w -w /w/scummvm/backends/platform/libretro aemiii91/miyoomini-toolchain:latest bash -c "
        source /root/.bashrc
        T=\${CROSS_COMPILE}
        nice -n 10 make platform=miyoomini CC=\${T}gcc CXX=\${T}g++ LD=\${T}g++ AR=\"\${T}ar cru\" RANLIB=\${T}ranlib -j16 > /w/out/scummvm.log 2>&1; echo exit=\$?
        \${T}strip --strip-unneeded scummvm_libretro.so && cp scummvm_libretro.so /w/out/
      " ;;
  esac
  tail -3 "out/$r.log" | cut -c1-300
done
ls -la out/*.so
for c in mgba gambatte scummvm; do f=out/${c}_libretro.so; [ -f $f ] || continue
  echo "-- $c $(readelf -A $f | grep -E 'Tag_FP_arch|Tag_Advanced_SIMD' | tr -s ' ' | tr '\n' ';') glibc<=$(objdump -T $f | grep -oE 'GLIBC_[0-9.]+' | sort -Vu | tail -1) cxx<=$(objdump -T $f | grep -oE 'GLIBCXX_[0-9.]+' | sort -Vu | tail -1) needs: $(readelf -d $f | grep NEEDED | grep -oE '\[[^]]+\]' | tr '\n' ' ')"
done
