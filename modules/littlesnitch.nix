# Little Snitch, the application firewall. See notes/littlesnitch.md.

{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.littlesnitch.enable = true;

  # Through the overlay, so that it is built with this pkgs and allowUnfree.
  nixpkgs.overlays = [ inputs.littlesnitch.overlays.default ];
  services.littlesnitch.package = lib.mkForce pkgs.littlesnitch;

  systemd.services.littlesnitch = {
    wants = [ "network-pre.target" ]; # the module only orders it before

    # Three tries in 10 minutes, then failed: no restart loop holding up boot.
    startLimitIntervalSec = 600;
    startLimitBurst = 3;

    serviceConfig = {
      # The module leaves out four that 1.1.0 needs (flake issue #2).
      CapabilityBoundingSet = lib.mkForce [
        "CAP_BPF"
        "CAP_DAC_READ_SEARCH"
        "CAP_NET_BIND_SERVICE"
        "CAP_PERFMON"
        "CAP_SETPCAP"
        "CAP_SYS_ADMIN"
        "CAP_SYS_RESOURCE"
        "CAP_SETUID"
        "CAP_SETGID"
      ];
      TimeoutStartSec = "120s"; # a healthy start takes about 9 s
      TimeoutStopSec = "30s"; # a hung daemon ignores SIGTERM
    };
  };

  # No update checks of its own: Nix keeps the version.
  systemd.tmpfiles.rules = [
    "d /var/lib/littlesnitch/override/config 0755 root root -"
    "f /var/lib/littlesnitch/override/config/software_update.toml 0644 root root -"
  ];
}
