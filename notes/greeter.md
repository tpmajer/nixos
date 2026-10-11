# The login screen

greetd, with Quickshell drawing the screen in a niri of its own
(`modules/greeter.nix`, `greeter/shell.qml`), in place of GDM (2026-10-10).

## Where it lives

The greeter runs as the `greeter` user, which cannot read `~/.dotfiles`. The
screen is built into the store, with the lock's look (`lock/LockView.qml`)
copied, not shared: a change to it needs a rebuild, and an edit to the bar
cannot break it. The weather and the notifications of the lock's row are the
session's, so only the battery is there.

Its niri has no binds. The VT keys are niri's own, so a TTY is still there if
the screen fails; greetd starts the greeter again when it exits. niri starts
with its default config, binds included, on one it cannot parse, so the
greeter's is checked with `niri validate` at build.

The greeter's home is /var/empty, so its cache is `/var/cache/greeter-shell`,
set before niri starts: without one Mesa keeps no shaders, and they are
compiled at every start. Its niri has X11 off, or it would take display :0
ahead of the session's. Its user manager starts no keyring and no SSH agent
(`ConditionUser=!greeter` in `desktop.nix`).

The power key is the reader too, and niri would suspend at it: its niri is
told not to handle it. Left alone for a minute the screen turns the outputs
off, for ten it suspends the machine, as hypridle does in the session. Idle
is told once per stretch without input, so the count is begun anew a minute
after each suspend: a machine woken untouched sleeps again.

## Sessions

The sessions are the desktop entries of the display manager's session data,
niri and Steam's gamescope. The one named in the corner is started; a click
or Tab makes it the next. It is niri at every start: the last one is not
kept, unlike under GDM.

Steam's gamescope session has one way out, "Switch to Desktop": in
gamescope the menu has no "Exit Steam". The entry sends Steam's own
`SteamOSManager.SwitchToDesktop`, which the client only answers as SteamOS
(`-steamos3`): under `-tenfoot`, nixpkgs' default, its "Switching to
Desktop" window came up and nothing followed, and nothing was logged
(read in `steamui/sp.js` and `steamui.so`, 2026-10-11). As SteamOS, with no
SteamOSManager on the bus, it runs `steamos-session-select plasma`. So the
session is started with `-steamos3 -gamepadui`, and Steam's environment has
three stand-ins (`packages.nix`): `steamos-session-select` asks Steam to
exit, which ends gamescope and brings the login screen back with niri as
the session to start; `steamos-update` says there is none (7);
`steamos-select-branch` names one branch. Seen to work 2026-10-11, after a
reboot: the sessions the login screen offers come with greetd's config,
which greetd reads at its start alone, so a change to them, or to the screen
itself, is not there after a switch and a logout.

greetd hands the entry's `Exec` to a shell after `/etc/profile`, so a bare
`niri-session` is found. The session is started with
`XDG_SESSION_TYPE=wayland`: greetd has a VT, and logind would call it a tty.

## Output

greetd connects what it starts, the greeter and the session alike, to the VT
and sets the VT to text mode. Between two compositors, and until a session's
compositor shows its first frame, the VT is what the screen shows, with
whatever was printed to it: under GDM the output went to the journal.
`greeter-session` wraps both: the output goes to the journal under the
session's id (`journalctl -t steam`, `-t niri`, `-t greeter`), and the VT's
cursor is hidden. It calls systemd-cat by its path and sets no PATH: it
becomes the session, which would keep it. niri gives what it spawns no
output, so the login screen's Quickshell is put through systemd-cat too,
under the same `greeter`.

The gap cannot be closed from here: greetd ends the greeter before it starts
the session on the same VT, where GDM kept its greeter on one VT until the
session's compositor was up on another. Measured 2026-10-10, some 1.1 s from
the greeter's niri going to the session's niri taking the output. So the
screen fades to one colour before the session is started, and the greeter's
niri is that colour under it. It was black; on `greetd-fork` it is the
session's backdrop colour (`#11111b`), which the session's curtain has too,
and the VT is given it as well: `greeter-session` sets the console's colour
0 (`ESC ] P 0 11111b`) and clears, at the greeter's start already, so the VT
has it at the first hand-over. Seen on a login 2026-10-11. The screen comes
out of that colour too: a veil over it is lifted in 0.6 s once the wallpaper
is read, where the clock and the field came at once and the wallpaper faded
in under them (seen in a nested niri, not on the real screen).

A curtain over the session's first moments, in the bar's Quickshell and
with awww held for it, was tried under plain greetd 2026-10-10 and dropped:
it showed no difference and only held the desktop back. The one on
`greetd-fork` is another: `session-curtain`, a Quickshell of its own that
is up before the wallpaper, with `wallpaper-first` drawing a copy at once
(tried on the branch `sddm`, notes/sddm.md there). It waited for the bar too at
first; the bar pops in by itself now (`~/.dotfiles`, `PopupHost.qml`), and
did so under the curtain, so the curtain lifts once a wallpaper is there.

Of that gap, 0.5 to 0.6 s lie between the PAM session's close and logind
removing the session, in every hand-over of that boot and the two before,
either way round (greeter to session, session to greeter). A TTY login
through the same `login` stack was removed 27 ms after its close, so it is
not a PAM module: it comes with a session that held the VT and the display.
Traced 2026-10-10 (`strace -T -tt` on systemd-logind, run with `systemd-run`
so that it outlives the logout): it is one call, `ioctl(KDSETMODE, KD_TEXT)`
on the VT, 0.59 and 0.60 s, made as logind takes the VT back from a
compositor, right after `DRM_IOCTL_DROP_MASTER`. The kernel's console takes
the display again there, at the panel's own mode, 2880x1920@120, which the
compositors use too. Nothing else in logind took 50 ms. So it is the
kernel's, on this display, at every end of a compositor on a VT; neither
greetd nor logind has a setting for it.

First seen 2026-10-10: a flash of text at login, and Steam's gamescope
session looking stuck on a console of its own logs until Ctrl+Alt+F3. Whether
gamescope was only waiting for Steam's first frame, some 20 s as under GDM,
or needed the VT switch to show, is not known: its logs were on the VT. They
are in the journal from here on.

## PAM, the keyring and the reader

greetd's PAM service only refers to `login`, as gdm-password did, so the
keyring unlocks with the password (notes/oo7.md). GDM's module also set
`login.fprintAuth = false`, which is kept: a TTY asks for the password.

The reader is pam_fprintd in greetd's own service, ahead of `login`. greetd
holds one conversation, so the reader and the password take turns, unlike
GDM's two services:

- The reader waits 10 s, then PAM asks for the password. 10 s is
  pam_fprintd's least: it raises a lower timeout.
- With nothing typed by then the screen drops the conversation and starts
  another, so the reader waits for as long as someone is there. With the
  outputs off the conversation rests at the password.
- A password entered while the reader waits is sent when PAM asks.
- After three fingers it does not know the reader is back in half a minute,
  so its limit holds: until then the conversation rests at the password, and
  neither Esc nor an emptied field begins another. A wrong password does, as
  PAM leaves no other way. Only "Failed to match" counts; a touch it could
  not read does not.
- A login by finger leaves the keyring locked, as it did under GDM.

pam_fprintd's messages are told from other modules' by their words, which
are English under the system's locale (`LANG=en_US.UTF-8`). Under another
language the reader's icon would stay dark.

## The fork

On the branch `greetd-fork` greetd is built with the changes of
`~/Claude/greetd` (branch `handover`, from 0.10.3), kept here as patches
(`patches/greetd`, `git format-patch 0.10.3..HEAD`). What follows replaces
the turns of the reader and the password described above.

- PAM asks for the password first (pam_exec, `greetd-typed`). One given
  skips the reader and goes to login's rules at once. None is a round of
  the reader and nothing else: a finger, or failure after 10 s or three it
  does not know, with no pam_unix and so none of its delay.
- The screen answers with nothing by itself, so the reader waits from the
  start, round after round. Enter with a password typed cancels the round
  and sends the password when the next conversation asks.
- That needed three things of greetd. It read a client's requests one at a
  time, so a cancel was not read while PAM waited; the socket to its worker
  was blocking, which held the whole daemon at such a wait; and a cancelled
  worker was left to PAM's timeout, the reader with it. A cancel of a
  conversation already over was answered with an error, which the screen
  showed.
- A cancel that cuts a wait short is answered twice: the request it
  interrupts with the error "cancelled", which the screen passes over, then
  the cancel itself.

- The hand-over (`terminal.handover`): the session is started at once on
  the next free VT, in graphics mode, and switched to once its PAM session
  is open; the greeter is kept on its VT for 3 s and then ended by greetd.
  So the console never has the display between the two, and the kernel's
  half second of giving it back falls on a VT that is not in front. The
  screen no longer exits at the launch: its last frame, the backdrop
  colour, is what stays on the display. A logout still ends the session's
  compositor on the VT in front, as under SDDM.
- A session that ends with no compositor ever on its VT left that VT in
  graphics mode with no process to ask for a switch, and the kernel ignores
  every switch away from such a VT (`change_console`, `vt_ioctl.c`): the
  next greeter waited for its VT for good, on a black screen that no key
  left. Seen 2026-10-11, when `niri-session` refused to start ("A niri
  session is already running"). The worker now puts the VT back in text
  mode as the session ends, and greetd does it for the VT in front before a
  greeter is started, should a worker have been killed. Not seen since.
- `loginctl terminate-session` does not end a niri session: niri is a user
  service, and stays while another session of the user is there, a TTY
  login for one. The next login then finds it running. From a TTY the
  session is ended with `systemctl --user stop niri.service`.
- Seen on three logins 2026-10-11: no black and no console between the
  login screen and the session, the session on a VT of its own (tty2).
  A VT looked at from the login screen gets a getty, and the next session
  the VT after it.

Tried 2026-10-11 in a nested niri against a greetd built to run without
root, with stand-ins for the reader and the password in a PAM directory of
its own: a round and its timeout, a wrong password (refused 0.13 s after
Enter, in the middle of a round), Esc, the right password and a finger both
through to the session's start. On the real reader, three conversations
cancelled in a row: answered within 1 ms, the next one asked for a finger
0.3 s later. The password and a finger were then seen on logins. Not seen: a
finger not recognised, and the reader kept away after three.

## greetd and Quickshell

Read in their sources (greetd 0.10.3, Quickshell 0.3.1), not seen on a real
login yet:

- greetd answers a client's requests in order, one answer each.
- greetd does not stop a cancelled conversation's worker. One cancelled
  while pam_fprintd waits holds the reader until its timeout, and one
  cancelled while PAM checks an answer still sends its refusal. So Esc
  cancels nothing then; the screen cancels at the password prompt alone,
  and tries again every 5 s when the reader did not ask.
- Each conversation dropped at the password makes pam_unix log two lines at
  err, "conversation failed" and "auth could not identify password", every
  10 s for as long as someone is at the screen with nothing typed. They are
  the reader's rounds, not failed logins.
- Quickshell does not wait for greetd's answer to a cancel and logs it as
  unexpected; a conversation started before it comes takes it for a success.
  Hence the screen's wait before each new one, longer after a late answer.

## The wallpaper

The screen shows the session's last wallpaper, blurred and dimmed as the lock
does. `greeter-wallpaper`, a user service, leaves what awww shows on each
output in `/var/cache/greeter/<output>.jpg`, cut to the output's size:

- as the session starts, and whenever awww writes its cache: a path unit on
  `~/.cache/awww/<version>`, as awww tells nobody;
- once for an image: a hash of its path and time is kept next to the copy;
- with no start limit, which wallpapers shuffled in a row would reach,
  stopping the path unit too.

The copies are readable by every user. No copy for an output, and the screen
is plain, as at the first login after this is deployed.

## What went with GDM

- `adwaita-icon-theme`, where GTK looks for an icon the theme in use lacks,
  whatever that theme is: in `packages.nix` now.
- `accounts-daemon`, which nothing here asks for: left off.
- The gdm-fingerprint PAM service, which the lock borrowed for its reader:
  `lock-fingerprint` in `desktop.nix` now. The old name is kept next to it
  until `~/.dotfiles` asks for the new one (its `greetd` branch): that repo
  is live and this one needs a rebuild, so either may come first. Then the
  old name goes.
- The workaround that kept pipewire from GDM's greeter, whose gnome-shell
  crashed on it.

## Trying it without a rebuild

`GREETD_SOCK` pointing at a stand-in for greetd's IPC, and
`qs --path greeter` in a nested niri, with `GREETER_USER`,
`GREETER_SESSIONS`, `GREETER_WALLPAPERS` and `GREETER_RUN` set as the module
sets them; for `GREETER_RUN` any path does, as the stand-in starts nothing.
