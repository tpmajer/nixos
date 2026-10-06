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
    # Upstream ma Wants=network-pre.target; moduł ustawia samo Before=,
    # co bez Wants= jest ordering-only i nic nie gwarantuje.
    wants = [ "network-pre.target" ];

    # 2026-08-16: po dodaniu blocklisty OISD (267 tys. domen) demon przestał
    # kończyć start - 100% CPU, 1,3 GB RSS na próbę. Domyślny limit startu
    # (5 prób / 10 s) nigdy nie zadziała, bo jedna próba trwa dłużej niż całe
    # okno, więc systemd restartował w nieskończoność, blokując boot i
    # wyłączanie systemu. Trzy próby w oknie 10 minut kończą się usługą w
    # stanie failed zamiast pętli.
    startLimitIntervalSec = 600;
    startLimitBurst = 3;

    serviceConfig = {
      # noblepayne/littlesnitch-linux-flake#2: moduł pomija cztery capability,
      # których 1.1.0 wymaga przy starcie -> "capset failure". Usunąć, gdy
      # naprawią.
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
      # Zdrowy start to ~9 s. 120 s daje zapas na zimny cache i większy
      # zestaw reguł, a jednocześnie domyka cykl: 3 x (120 s + 5 s
      # RestartSec) = 375 s, czyli mieści się w oknie 600 s powyżej.
      TimeoutStartSec = "120s";
      # Zawieszony demon ignoruje SIGTERM - domyślne 90 s czekania na
      # SIGKILL to dokładnie to, co wydłużało zamykanie systemu.
      TimeoutStopSec = "30s";
    };
  };

  # Wersję pilnuje Nix - wyłączamy wbudowane sprawdzanie aktualizacji.
  systemd.tmpfiles.rules = [
    "d /var/lib/littlesnitch/override/config 0755 root root -"
    "f /var/lib/littlesnitch/override/config/software_update.toml 0644 root root -"
  ];
}
