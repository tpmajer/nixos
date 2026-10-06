# oo7 as the Secret Service

oo7 replaces gnome-keyring (`modules/desktop.nix`).

- niri-flake hardcodes `services.gnome.gnome-keyring.enable = true`, which
  would put a second org.freedesktop.secrets provider next to oo7: hence
  `mkForce false`.
- `gcr-ssh-agent` defaults to gnome-keyring's setting and would go off with it,
  taking the SSH agent (`SSH_AUTH_SOCK=/run/user/$UID/gcr/ssh`). It is gcr_4
  and independent of the Secret Service: kept on.
- `gcr_3` ships gcr-prompter, which owns org.gnome.keyring.SystemPrompter, the
  prompter oo7 calls for unlock dialogs. The oo7 module does not pull it in and
  gcr_4 dropped it; without it there is no unlock prompt at all.
- `services.oo7` turns pam_oo7 on for the login stack, which gdm-password
  substacks, so the keyring unlocks with the GDM password. The module default,
  left on purpose; `lib.mkForce false` goes back to no auto-unlock.
- The `hyprlock` PAM service is the Quickshell lock's password check
  (`~/.dotfiles`, Lock.qml). It keeps the name of hyprlock, which it was set up
  for and which is gone.

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
