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

The power key is the reader too, and niri would suspend at it: its niri is
told not to handle it. Left alone for a minute the screen turns the outputs
off, for ten it suspends the machine, as hypridle does in the session.

## Sessions

The sessions are the desktop entries of the display manager's session data,
niri and Steam's gamescope. The one named in the corner is started; a click
or Tab makes it the next. It is niri at every start: the last one is not
kept, unlike under GDM.

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
cursor is hidden.

The gap cannot be closed from here: greetd ends the greeter before it starts
the session on the same VT, where GDM kept its greeter on one VT until the
session's compositor was up on another. Measured 2026-10-10, some 1.1 s from
the greeter's niri going to the session's niri taking the output. So the
screen fades to black before the session is started, and the greeter's niri
is black under it: black screen, black VT, then the desktop.

A curtain over the session's first moments, lifted once the wallpaper was
there, was tried the same day and dropped: it showed no difference and only
held the desktop back.

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
  so its limit holds. Only "Failed to match" counts; a touch it could not
  read does not.
- A login by finger leaves the keyring locked, as it did under GDM.

pam_fprintd's messages are told from other modules' by their words, which
are English under the system's locale (`LANG=en_US.UTF-8`). Under another
language the reader's icon would stay dark.

## greetd and Quickshell

Read in their sources (greetd 0.10.3, Quickshell 0.3.1), not seen on a real
login yet:

- greetd answers a client's requests in order, one answer each.
- greetd does not stop a cancelled conversation's worker. One cancelled
  while pam_fprintd waits holds the reader until its timeout, and one
  cancelled while PAM checks an answer still sends its refusal. So Esc
  cancels nothing then; the screen cancels at the password prompt alone,
  and tries again every 5 s when the reader did not ask.
- Quickshell does not wait for greetd's answer to a cancel and logs it as
  unexpected; a conversation started before it comes takes it for a success.
  Hence the screen's wait before each new one, longer after a late answer.

## The wallpaper

The screen shows the session's last wallpaper, blurred and dimmed as the lock
does. `greeter-wallpaper`, a user service, leaves what awww shows on each
output in `/var/cache/greeter/<output>.jpg`, scaled down:

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
`GREETER_SESSIONS` and `GREETER_WALLPAPERS` set as the module sets them.
