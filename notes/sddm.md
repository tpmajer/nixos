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
- The reader's icon is shown during a round of the reader alone.

## The reader

SDDM begins its one PAM conversation when the form is sent, and takes no
other login while it lasts. So the reader does not wait from the start, as
on greetd's screen: Enter on an empty field begins a round of it.

- PAM, in SDDM's own service ahead of `login`: pam_exec hands the password
  to `sddm-typed`, which says whether one was typed. One typed skips
  pam_fprintd and is checked at once; an empty one waits at the reader for
  10 s, pam_fprintd's least, or three fingers it does not know.
- pam_exec is told `quiet` and `quiet_log`: an empty password would
  otherwise be an error on the screen and in the journal.
- pam_fprintd's messages reach the theme as SDDM's information messages,
  told from others by their words, English under the system's locale.
- SDDM tells a failed login with each error of a PAM module, a finger not
  recognised among them, while PAM goes on. The theme takes the refusal
  that follows such a message for the reader's, and the next one for the
  round's end.
- SDDM also tells a refusal twice at a login's end, with PAM's verdict
  ("Authentication failure") and again as the helper ends, 0.1 ms apart in
  the journal of 2026-10-11. The theme takes the first, and does not show
  the verdict: at the end of a round left alone it was a red line and
  "wrong password".
- A password typed during a round is sent when the round has ended, half a
  second later: a login sent while SDDM's helper is still there is dropped
  without an answer, and the screen would wait for good. pam_unix's delay
  after the round's failure, about 2 s, comes before it.
- A login by finger leaves the keyring locked, as under greetd and GDM.

## The wallpaper's first frame

After the hand-over the session's niri showed its backdrop until awww had
the wallpaper up: 0.2 to 1.0 s over 25 logins (niri's socket to awww's first
buffer, in the journal). awww keeps the image's path, not its pixels: at
every start it decodes the file and scales it, here a 4658x2620 PNG with
Lanczos3.

- Not SDDM's to hide: started on a VT that is not in front, niri has no
  outputs until the switch (its `tty.rs`), so nothing can be drawn ahead of
  it. A curtain in Quickshell comes after the wallpaper, unless awww is held
  for it, which was tried under greetd and dropped (notes/greeter.md).
- `wallpaper-first`, a user service started with niri, draws
  `greeter-wallpaper`'s copy, and ends half a second after awww names an
  image, or after 5 s.
- The copy is cut to the output's size in pixels for it, as awww fills an
  output (crop, centred), so it is drawn as it is and awww's image comes
  under the same picture.
- On an idle machine, in a headless sway at the panel's mode: swaybg with
  that copy has its first buffer in about 30 ms, a second awww-daemon has
  the image after 50 to 60, awww's restore of the original takes 160.
- Drawn by swaybg at first, where the wallpaper came at once. Now by a
  second awww-daemon (namespace `first`, no cache, the bottom layer), which
  fades it in from black in a quarter of a second: black is what SDDM's
  niri leaves. The bottom layer is above the session's awww, whose image
  would else cut the fade short.
- Its client writes the image's path into awww's cache, the session's
  wallpapers among them: it is given a cache of its own in the runtime
  directory.

Seen on a login 2026-10-11: the wallpaper is there as the session comes up.
The black of SDDM's niri before the session's is still there: its window is
closed at the login.

## Trying the theme without a rebuild

`sddm-greeter-qt6 --test-mode --theme <directory>`, in a nested niri with the
fullscreen rule, with a `theme.conf` next to a copy of `sddm/`. It shows the
real sessions. A login does nothing there: no answer comes back.

## Not seen yet

Tried in test mode alone, and so not on a login: a password refused and one
taken, the power buttons, swayidle's two steps, the theme on a second
output.

The reader's round is not seen at all: test mode has no PAM. `sddm-typed`
was run by hand, the rest is read in the sources (SDDM 0.21, fprintd 1.94.5,
Linux-PAM 1.7.2).

## Open

- A reader that waits from the start, as on greetd's screen: more than a
  theme and PAM can do, with one conversation begun by the form.
- Whether to stay with it: greetd's screen is on `main`, GDM on the branch
  `gdm`.
