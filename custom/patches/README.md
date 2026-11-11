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

## mame2003_plus: keep Onion's original core (hd12)

The hd3 update to current mame2003-plus (13da075) was reverted in hd12.
Current mame2003-plus decrypts CPS2 with `<set>.key` files and has changed
other romsets; the device's arcade set is an older XOR-style set built for
Onion's original core. An audit of the 342 arcade zips found 46 that the new
core could not load (all CPS2 games, Tekken 1-3, Pole Position, Pengo, Out
Run bootleg and others). Do not update this core unless the arcade romset is
rebuilt for it at the same time.
