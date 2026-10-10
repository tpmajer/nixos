# Desktop notes

## The login screen

greetd, with Quickshell drawing the screen in a niri of its own
(`modules/greeter.nix`, `greeter/shell.qml`), in place of GDM (2026-10-10).

- The greeter runs as the `greeter` user, which cannot read `~/.dotfiles`:
  the screen is built into the store, with the lock's look copied, not shared.
  A change to it needs a rebuild, and an edit to the bar cannot break it.
- For the same reason the wallpaper is a copy: `greeter-wallpaper`, a user
  service, leaves what awww shows on each output in `/var/cache/greeter`,
  scaled down, as the session starts and whenever awww writes its cache
  (a path unit on `~/.cache/awww/<version>`; awww tells nobody). The copies
  are readable by every user. No copy for an output, and the screen is plain.
- Its niri has no binds. The VT keys are niri's own, so a TTY is still there
  if the screen fails; greetd starts the greeter again when it exits.
- greetd's PAM service only refers to `login`, as gdm-password did, so the
  keyring unlocks with the password (notes/oo7.md). GDM's module also set
  `login.fprintAuth = false`, which is kept: a TTY asks for the password.
- The reader is pam_fprintd in greetd's own service, ahead of `login`. greetd
  holds one conversation, so the reader and the password take turns, unlike
  GDM's two services: the reader waits 10 s, pam_fprintd's least (it raises
  a lower timeout), then PAM asks for the password.
  With nothing typed by then the screen drops the conversation and starts
  another, so the reader waits for as long as someone is there; a password
  entered meanwhile is sent when PAM asks. A login by finger leaves the
  keyring locked, as it did under GDM.
- greetd does not stop a cancelled conversation's worker: one cancelled while
  pam_fprintd waits holds the reader until its timeout. The screen cancels at
  the password, and tries again every 5 s when the reader did not ask. Esc
  while the reader waits or an answer is checked cancels nothing.
- Quickshell does not wait for greetd's answer to a cancel and logs it as
  unexpected; a conversation started before it comes takes it for a success.
  Hence the screen's wait before each new one.
- Its niri is told not to handle the power key, which would suspend: the key
  is the reader too. Left alone for ten minutes the screen suspends the
  machine itself, as GDM's greeter did.
- niri starts with its default config, binds included, on one it cannot
  parse, so the greeter's is checked with `niri validate` at build.
- What GDM's module brought and is gone with it: `adwaita-icon-theme`, which
  candy-icons inherits and is now in `packages.nix`; `accounts-daemon`, which
  nothing here asks for, left off; and the gdm-fingerprint PAM service, which
  the lock borrowed for its reader: `lock-fingerprint` in `desktop.nix` now.
  The old name is kept next to it until `~/.dotfiles` asks for the new one
  (its `greetd` branch): that repo is live and this one needs a rebuild, so
  either may come first. Then the old name goes.
- The sessions are the desktop entries of the display manager's session
  data, niri and Steam's gamescope: the one in the corner is started, and a
  click or Tab makes it the next. It is niri at every start: the last one
  is not kept, unlike under GDM. It is started with
  `XDG_SESSION_TYPE=wayland`: greetd has a VT, and logind would call the
  session a tty.
- Tried without a rebuild: `GREETD_SOCK` pointing at a stand-in for greetd's
  IPC, and `qs --path greeter` in a nested niri.

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

mDNS is Avahi's alone: systemd-resolved's is off. With both on port 5353
Avahi warned at every start that a second stack makes mDNS unreliable
(2026-10-10). Names in `.local` resolve through nss-mdns, which nsswitch asks
before resolved; a program that asks resolved itself, past the system's
resolver, no longer gets them.
