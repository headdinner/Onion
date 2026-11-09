# Core patches

## scummvm-onion-target-ext.patch

Applies to ScummVM v2026.4.0 (`backends/platform/libretro/src/libretro-core.cpp`).

Onion's `Emu/SCUMMVM/launch.sh` passes `.target` shortcut files to the core. Upstream only reads a
target id from files ending in `.scummvm`; anything else falls back to auto-detecting the game in the
file's folder, which fails for Onion's `Roms/SCUMMVM/Shortcuts`. The patch treats `.target` the same
as `.scummvm`.

Note: the commit that added this patch says it also contains an `engines.mk` include fix. It does not.
That fix is only needed when building ScummVM master (as of 2026-11), where `Makefile.common` wraps
`-include engines/engines.mk` in an `ifeq ... endif` that the libretro `shared_modules.mk` extraction
can't handle. If building master, remove that wrapper first (see `custom/build_cores2.sh` history).
