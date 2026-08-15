{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  services.littlesnitch.enable = true;

  # Pakiet przez overlay, żeby budował się w naszym pkgs i respektował
  # nixpkgs.config.allowUnfree - inaczej rebuild wymaga --impure.
  nixpkgs.overlays = [ inputs.littlesnitch.overlays.default ];
  services.littlesnitch.package = lib.mkForce pkgs.littlesnitch;

  systemd.services.littlesnitch = {
    # noblepayne/littlesnitch-linux-flake#2: moduł pomija cztery capability,
    # których 1.1.0 wymaga przy starcie -> "capset failure". Usunąć, gdy naprawią.
    serviceConfig.CapabilityBoundingSet = lib.mkForce [
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
    # Upstream ma Wants=network-pre.target; moduł ustawia samo Before=,
    # co bez Wants= jest ordering-only i nic nie gwarantuje.
    wants = [ "network-pre.target" ];
  };

  # Wersję pilnuje Nix - wyłączamy wbudowane sprawdzanie aktualizacji.
  systemd.tmpfiles.rules = [
    "d /var/lib/littlesnitch/override/config 0755 root root -"
    "f /var/lib/littlesnitch/override/config/software_update.toml 0644 root root -"
  ];
}
