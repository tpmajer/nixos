# Desktop notes

## No pipewire for the GDM greeter

GDM 50: the greeter's gnome-shell (libgvc) segfaults in
`_pa_context_get_card_info_by_index_cb` when the greeter's own pipewire-pulse
exposes an HDA card whose profile enumeration is not finished yet ("card 52
port N profiles inconsistent (0 < 3)"). The greeter has no use for audio, so
pipewire, pipewire-pulse and wireplumber are not started for the gdm-greeter
users.

## Session services

Quickshell, hypridle, the wallpaper daemon and the rest are bound to
niri.service, not to graphical-session.target. Those that run other programs
(Quickshell's scripts and click commands, Ghostty, Signal opening links) get
`path = [ ]`, which keeps the session's PATH from niri instead of a Nix-built
one, so nmcli, wpctl, `niri msg` and the like resolve as in the shell.

Quickshell restarts `always`, not `on-failure`: it is the session lock too. If
it goes while the session is locked, even cleanly (`qs kill`, SIGTERM), niri
keeps the session locked with nothing to unlock it; the next process locks
again by its marker. `systemctl stop` still stops it.

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
