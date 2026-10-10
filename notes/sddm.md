# SDDM's login screen

A trial on the branch `sddm` (2026-10-10): SDDM in place of greetd's login
screen (notes/greeter.md), for the one thing greetd cannot do, a hand-over to
the session without a black screen. `modules/sddm.nix`, `sddm/Main.qml`;
`modules/greeter.nix` stays in the tree, not imported.

## The hand-over

greetd ends its greeter before it starts the session on the same VT, and the
VT shows in between (notes/greeter.md). SDDM starts the session on a new VT,
as GDM does. Measured from the password taken to the session's niri having
the output, one login each:

| Greeter | Time | Black between |
|---|---|---|
| greetd | about 1.1 s | yes |
| SDDM, Wayland greeter as shipped | 0.75 s | yes |
| SDDM, greeter under Xorg | 0.33 s | no |
| SDDM, Wayland greeter held, weston | 0.46 s | no |
| SDDM, Wayland greeter held, niri | 0.17 s | no |

- SDDM 0.21's Wayland greeter closes its window at a login, and the helper
  that runs it ends the compositor with it: the VT is back in text mode
  before the session is up, the same half second as under greetd.
- Under Xorg the X server is SDDM's own process and stays, as root, for as
  long as the session runs (94 MB). Not kept for that.
- SDDM waits 5 s for the compositor to end. `sddm-compositor` wraps it and
  holds it for 3 after the signal: the greeter's VT stays in graphics mode
  until the session has the screen, and goes back to text in the
  background, which does not show.
- A greeter at another refresh rate than the session hands over with a
  modeset of its own, which shows. The panel names 60 Hz as preferred next
  to 120 Hz; niri takes 120 Hz in both places.
- A logout still ends the session's compositor on the VT in front: that
  way round the half second stays.

## The compositor

niri, not SDDM's weston: the session's mode, its scale of 1.6 and its
keyboard without a second set of settings, and its config is checked with
`niri validate` at build. SDDM does not provide for it: its greeter is a
plain window that asks for fullscreen, hence the window rule. No binds, no
X11, no animations; the power key is left alone, as it is the reader too.

swayidle in it turns the outputs off after a minute and suspends after ten,
as greetd's screen did.

## The theme

`sddm/Main.qml` is the lock's view (`~/.dotfiles`, `lock/LockView.qml`) once
more, in plain QML with SDDM's objects (`sddm`, `sessionModel`, `keyboard`,
`config`): the clock, the date, the battery, the password field with its
marks, red ones and "wrong password" for a password refused, the Caps Lock
warning. The session to start is named in one corner, a click or Tab makes
it the next, and it is niri at every login: the theme chooses it, and SDDM
is told to keep neither the last session nor the last user. Reboot and
power off are in the other corner.

- The user's name, the wallpapers' directory and the battery's file reach
  the theme through its `theme.conf`, written by the module.
- The wallpaper is the copy `greeter-wallpaper` makes in `/var/cache/greeter`
  (notes/greeter.md): SDDM's user cannot read the home either.
- A theme reads no file but an image or settings, and SDDM passes it no
  environment to change that. The compositor's wrapper writes the battery
  to `~sddm/battery.ini` whenever it changes, and the theme reads it with
  `Settings` twice a minute: by `value()`, as its bound properties are not
  read again, and would be written back.
- The reader's icon has its place kept and is never shown.

## Trying the theme without a rebuild

`sddm-greeter-qt6 --test-mode --theme <directory>`, in a nested niri with the
fullscreen rule, with a `theme.conf` next to a copy of `sddm/`. It shows the
real sessions. A login does nothing there: no answer comes back.

## Not seen yet

Tried in test mode alone, and so not on a login: a password refused and one
taken, the power buttons, swayidle's two steps, the theme on a second
output.

## Open

- The reader. SDDM begins its one PAM conversation when the form is sent,
  so a reader that waits from the start, as on greetd's screen, needs more
  than a theme. The password alone until then; the lock in the session has
  its reader as before.
- Whether to stay with it: greetd's screen is on `main`, GDM on the branch
  `gdm`.
