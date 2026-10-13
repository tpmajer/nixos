# Desktop notes

## Session services

Quickshell, hypridle, the wallpaper daemon and the rest are bound to
niri.service, not to graphical-session.target. Those that run other programs
(Quickshell's scripts and click commands, Ghostty, Signal opening links) get
`path = [ ]`, which keeps the session's PATH from niri instead of a Nix-built
one, so nmcli, wpctl, `niri msg` and the like resolve as in the shell.

Those defined in `session.nix` with `withNiri` are bound with `BindsTo`, so
they are stopped when niri goes. Without it Quickshell and awww-daemon were
restarted with no display and dumped core on every try, Quickshell every 2 s.
`PartOf` would not do: it follows a stop job, and niri exits by itself.
awww-daemon still dumps core once as niri goes: it panics on the broken
connection before systemd stops it.

Ghostty is bound the same way, and so are Thunderbird and Signal in
`background-apps.nix`: unbound, Ghostty was started every 2 s with no display
after a logout, and Signal failed as niri went (2026-10-10). hypridle is not:
its module makes it part of graphical-session.target, which stops it.

Quickshell restarts `always`, not `on-failure`: it is the session lock too. If
it goes while the session is locked, even cleanly (`qs kill`, SIGTERM), niri
keeps the session locked with nothing to unlock it; the next process locks
again by its marker. `systemctl stop` still stops it.

Quickshell 0.3.2 went that way at any reload of its configuration while
locked, a saved QML file being enough (2026-10-13): `ext_session_lock_v1:
error 3: Output is already locked`, then two seconds of niri's red screen
until the next process locked again. `WlSessionLock::realizeLockTarget` makes
the lock surfaces ahead of the lock without the old instance, so a reload's
are new windows and not the old ones taken over: a second surface for an
output. `patches/quickshell/session-lock-reload.patch` passes the old
instance there; upstream's master had the same line then. With it a reload
keeps the process and the lock, and still logs "Session lock object was
destroyed without unlocking" for the old instance, which no longer holds it.

## OpenLogi

- Its udev rules (uaccess for Logitech HID++ hidraw/event nodes) are in
  `lib/udev/rules.d`, which `environment.systemPackages` does not install:
  hence `services.udev.packages`. Without them the mouse's hidraw node stays
  root:root 0600 and every HID++ open fails with EACCES ("No Logitech HID++
  devices found").
- Its user unit ships in `$out/share/systemd/user`, but `systemd.packages`
  only scans `etc/systemd/user` and `lib/systemd/user`
  (nixos/lib/systemd-lib.nix), so the unit is defined in `session.nix`. The
  agent takes `~/.config/openlogi/agent.lock` and exits 0 if another instance
  holds it, so `Restart=on-failure` does not fight the GUI.

## Firefox and Local Network Access

Firefox 153 enables Local Network Access by default. unifi.ui.com is
controlled by a service worker, and LNA loses the address-space classification
for requests forwarded through it, so every call to the console at
`*.id.ui.direct` dies with no response and the Network app never loads. The
LNA gate itself logs "auto_allow"; the request is killed anyway
(https://bugzilla.mozilla.org/show_bug.cgi?id=2056851). The policy exempts the
target domain; the source-domain side of SkipDomains is broken
(https://bugzilla.mozilla.org/show_bug.cgi?id=2058449).

## Firefox's first start

Firefox has no way to stay running without a window on Linux, and a
`--headless` instance opens its windows headless too, so it is not kept in the
background as Ghostty is. `firefox-preload` reads its files into the page cache
as the session starts instead: the libraries (about 390 MiB) and, of the
profile last used, the files at its top, the extensions and the startup cache.

Measured on 2026-10-11, from the spawn to the window in niri, with 38
extensions: 1.3–2.3 s with those files dropped from the cache, 0.9–1.1 s after
the preload, which took 0.5 s. A new window of a running Firefox takes 0.2 s;
the rest of a start is the CPU's, not the disk's.

## Proton for Steam

`proton-cachyos_x86_64_v3` from chaotic replaces builds installed by hand into
`~/.steam/root/compatibilitytools.d` (protonup-qt). chaotic pins the tool's
title to "Proton-CachyOS x86-64-v3", so the name Steam sees is stable across
updates and the per-game CompatToolMapping entries in config.vdf survive a
rebuild. The v3 variant: Zen 5 (HX 370) has x86-64-v3.

## Firewall ports

Open on trusted networks only: elsewhere the kill switch lets nothing in
(wg-auto.md). 7236 and 7250 are Miracast's (gnome-network-displays), 57621 is
Spotify's sync of local files with mobile devices; mDNS (5353) is opened by
`services.avahi.openFirewall`. For `uxplay -p`: UDP 7011, 6001, 6000 and TCP
7100, 7000, 7001. LLMNR is off against poisoning on untrusted networks:
nothing here resolves bare hostnames (no samba/cifs client, no wsdd) and mDNS
covers the LAN.

mDNS is Avahi's alone: systemd-resolved's is off. With both on port 5353
Avahi warned at every start that a second stack makes mDNS unreliable
(2026-10-10). Names in `.local` resolve through nss-mdns, which nsswitch asks
before resolved; a program that asks resolved itself, past the system's
resolver, no longer gets them.
