# Little Snitch

From noblepayne/littlesnitch-linux-flake (`modules/littlesnitch.nix`).

- The package comes through the flake's overlay, so that it is built with this
  configuration's pkgs and `nixpkgs.config.allowUnfree` applies; otherwise a
  rebuild needs `--impure`.
- Upstream's unit has `Wants=network-pre.target`; the module only sets
  `Before=`, which without `Wants=` is ordering only and guarantees nothing.
- 2026-08-16: after the OISD blocklist was added (267 thousand domains) the
  daemon stopped finishing its start: 100% CPU and 1.3 GB RSS per attempt. The
  default start limit (5 tries in 10 s) never tripped, as one try outlasted the
  whole window, so systemd restarted it without end, holding up boot and
  shutdown. Three tries in 10 minutes end with the unit failed instead.
- `TimeoutStartSec=120s`: a healthy start takes about 9 s; 120 s leaves room
  for a cold cache and more rules, and 3 x (120 s + 5 s RestartSec) = 375 s
  still fits in the 600 s window.
- `TimeoutStopSec=30s`: a hung daemon ignores SIGTERM, and the default 90 s
  wait for SIGKILL is what made shutdown slow.
- `CapabilityBoundingSet`: the module leaves out four capabilities that 1.1.0
  needs at start ("capset failure", noblepayne/littlesnitch-linux-flake#2).
  Remove the override once that is fixed.
- The built-in update check is off (an empty `software_update.toml` override):
  Nix keeps the version.
