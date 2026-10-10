# oo7 as the Secret Service

oo7 replaces gnome-keyring (`modules/desktop.nix`).

- niri-flake hardcodes `services.gnome.gnome-keyring.enable = true`, which
  would put a second org.freedesktop.secrets provider next to oo7: hence
  `mkForce false`.
- `gcr-ssh-agent` defaults to gnome-keyring's setting and would go off with it,
  taking the SSH agent (`SSH_AUTH_SOCK=/run/user/$UID/gcr/ssh`). It is gcr_4
  and independent of the Secret Service: kept on.
- `gcr_3` ships gcr-prompter, which owns org.gnome.keyring.SystemPrompter.
  gcr-ssh-agent asks it for the passphrase of an SSH key; gcr_4 dropped it,
  and nothing else pulls it in. oo7 asked it too, before the prompt below.
- `services.oo7` turns pam_oo7 on for the login stack, which greetd's service
  substacks, so the keyring unlocks with the login password. The module
  default, left on purpose; `lib.mkForce false` goes back to no auto-unlock.
- The `hyprlock` PAM service is the Quickshell lock's password check
  (`~/.dotfiles`, Lock.qml). It keeps the name of hyprlock, which it was set up
  for and which is gone. The lock's reader has `lock-fingerprint`, pam_fprintd
  alone: a finger does not unlock the keyring.

## The unlock prompt

oo7 draws no dialogs. It asks one of two prompters over D-Bus:
org.gnome.keyring.SystemPrompter (gcr-prompter), or, when
`XDG_CURRENT_DESKTOP` is `KDE` and the name is activatable,
org.kde.secretprompter (Plasma's ksecretprompter). The choice is made at the
first prompt and kept until the daemon restarts.

Here the second is `scripts/secret-prompter.py`, with Quickshell drawing the
prompt (`~/.dotfiles`, Keyring.qml); `XDG_CURRENT_DESKTOP=KDE` is set for
oo7-daemon alone. Plasma's protocol is two methods and a callback object,
where GNOME's wants a key exchange and the password encrypted.

- oo7 calls `UnlockCollectionPrompt` or `CreateCollectionPrompt` on
  `/SecretPrompter` with the path of its request object and the keyring's
  name.
- The prompter calls the request's `Accepted(fd)`, the password to be read
  from the fd to its end. oo7 reads it with `recv`: a socket, not a pipe.
  The answer is 0, done, or 1, wrong: `Retry(reason)` is signalled before it.
- `Rejected()` cancels. `Dismissed()` ends every prompt, and oo7's `Dismiss`
  signal asks for that.

secret-prompter connects to `$XDG_RUNTIME_DIR/quickshell-keyring.sock` for
each prompt and speaks lines of JSON: `{"event": "prompt", "role",
"collection"}`, `{"event": "retry", "reason"}`, `{"event": "done"}` or, for an error
from oo7, `{"event": "failed"}` to Quickshell, `{"password"}` or `{"cancel"}` back. Without Quickshell the
prompt is rejected. A keyring with no items takes any password.

## The memlock limit

oo7-daemon calls `mlockall(MCL_CURRENT | MCL_FUTURE)` so that secrets never
reach swap. The kernel grants that only when the process's entire address
space (VmSize) fits in RLIMIT_MEMLOCK, not just the pages it would pin.

Measured here: VmSize 1662.7 MiB, of which 1596.9 MiB is untouched PROT_NONE
reservation (25 glibc malloc arenas of 63.87 MiB, one per thread), against an
RSS of about 10 MiB. Hence 2G. It is a ceiling, not a reservation: only the
resident pages get pinned. Verified: mlockall succeeds at VmSize 241.6 MiB
under a 256 MiB limit and fails at 261.6 MiB.

`cap_ipc_lock` cannot lift the limit, as the upstream unit sets
`PrivateUsers=yes` and the capability then only counts inside the daemon's own
user namespace. A user unit cannot exceed the hard limit of `user@.service`,
so that is raised to 2G, with `DefaultLimitMEMLOCK=8M` keeping every other user
service at the default and an override giving oo7-daemon the 2G.
