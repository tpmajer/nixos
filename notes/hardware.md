# Hardware notes

Framework 13, AMD Ryzen AI 300 (Strix Point). See also s2idle.md, mt7925.md and
rtl8156.md.

## `ucsi_acpi` is blacklisted

Broken on this hardware: once loaded it spams "ucsi_acpi USBC000:00: unknown
error 256". A re-enable test on 2026-06-28 did not fix the dead USB-C port of
the time (charging is EC-driven, independent of UCSI) and only brought the
spam back. The dead port was an EC wedge and cleared on a reboot, so it was
never a UCSI problem: no reason to revisit the blacklist over it.

## LUKS and TRIM

dm-crypt drops discards unless told otherwise, which silently makes fstrim a
no-op on everything under LUKS; /boot, outside the crypt layer, is then the
only thing trimmed. Without TRIM the controller goes on preserving and
relocating blocks the filesystem freed long ago, paying in write throughput
and erase cycles. The cost of `allowDiscards`: freed extents read back as
zeros rather than ciphertext noise, so the map of free space is no longer
secret. Contents, names and keys stay unreadable.

## Scheduler

`scx_lavd`, a sched_ext scheduler in userspace (CONFIG_SCHED_CLASS_EXT=y in
the mainline kernel, no patched kernel needed). It is latency/burst oriented
and power-aware, the closest thing to CachyOS's BORE without leaving
`linuxPackages_latest`.

## The battery's charge limit

Only root can write it. 80 is what it is kept at, 100 charges it full, e.g.
before a day away from a socket. The switch in Quickshell's battery popup
starts `battery-charge-limit@80` or `@100`; a polkit rule lets it do so
without a password. Nothing sets it at boot: the firmware is back at 80 after
a restart (seen on 2026-10-04), which is wanted, so 100 lasts until the next
boot or the next click.

## Xbox controllers

`hardware.xone`: the driver for Xbox controllers over USB and the official
Xbox Wireless Adapter; full GIP protocol, e.g. the Elite 2's paddles by cable.
