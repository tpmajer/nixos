# The s2idle hang (open)

The laptop sometimes dies in the s2idle path: black screen on wake, hard reset
needed. Unexplained so far. What the configuration does about it, and why each
piece is still there.

## Kernel parameters (`modules/hardware.nix`)

- `amdgpu.gpu_recovery=1` is a diagnostic net. It lets amdgpu attempt a GPU
  reset instead of wedging, so that a display-engine failure can end as a
  recovered hang with something in the journal. On 2026-08-06 19:16 the machine
  died in the s2idle path anyway: the journal ends at "PM: suspend entry",
  pstore is empty, no amdgpu reset is logged. That is a data point of its own:
  the failure sits below the level where amdgpu can react. Do not remove it
  until the hang is explained (debug-session-2026-08-06.2.md).
- `amdgpu.cwsr_enable=0` is belt and braces against the MES ring buffer wedge
  on gfx1150 (gitlab drm/amd#4749). The fix (e9f58ff991dd "drm/amdgpu: rework
  how we handle TLB fences") landed in 6.18.32 and is in mainline, so the
  parameter is likely redundant for that bug. Kept because broken CWSR is
  reported to saturate the MES ring on its own, and it costs nothing here: no
  compute wave save/restore workloads on this machine.
- `amdgpu.dcdebugmask=0x10` comes from
  `hardware.amdgpu.dcDebugMask.disablePsr`. nixos-hardware's Framework module
  sets the same with mkDefault, against hangs with panel self-refresh (gitlab
  drm/amd#3647, FrameworkComputer/SoftwareFirmwareIssueTracker#110, open for
  this model as of 2026-10-04); it is stated in this repo so that it stays if
  the module drops it. It is not free: debugfs on 2026-10-04 showed the panel
  supporting PSR (sink 0x03) with driver support off and no Panel Replay to
  fall back on, so the panel never self-refreshes. The cost in watts is
  unmeasured, and with VRR on the driver may not enter PSR anyway. Do not turn
  it off while the hang is open: it would be a new variable in the display
  engine. To try later: set it to false, reboot, read
  `/sys/kernel/debug/dri/*/eDP-1/psr_state`, compare the battery draw against
  11.4 W idle.

## Modules unloaded around a suspend (`scripts/sleep-pre.sh`, `sleep-post.sh`)

- `amdxdna`: since 2026-05-25 (ab60e32), against a PSP hang on wake.
  Blacklisting it outright (7ca267a) as a suspect for the boot-time sync floods
  was disproved on 2026-09-22: the 10th boot with it blacklisted died the same
  way, with no amdxdna in the journal (debug-session-2026-09-17.md).
- `mt7925e`: added 2026-06-26 (131e1f7) after a suspend froze with the journal
  ending at "PM: suspend entry (s2idle)" right after the WiFi teardown, and
  reverted the same day (7aef90e) to see whether 7.1.1 handled it. The hang
  recurred on 2026-08-06 19:16 with that signature, so it is back, as a test
  and not a known fix. The WiFi teardown precedes every suspend, the 51 that
  resumed fine included, so its presence in the failing one proves nothing by
  itself. Drop it again if a hang recurs with it active
  (debug-session-2026-08-06.2.md).

On resume `mt7925e` is loaded first and neither module failing keeps the other
from being tried: the script runs under `set -e`, and without WiFi the laptop
is the worse off.

## fprintd after a resume

fprintd 1.94.5: a Release during PrepareForSleep drops its session but leaves
the device open, and every Claim fails until the daemon restarts. `sleep-post`
stops it and D-Bus starts a new one. Safe now that the lock goes through
pam_fprintd, which claims anew each time; hyprlock did not
(debug-session-2026-06-10.md, debug-session-2026-10-03.md).
