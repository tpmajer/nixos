# Power management, suspend and the services around the battery and the Wi-Fi
# card. Background in notes/s2idle.md, notes/mt7925.md and notes/rtl8156.md.

{
  pkgs,
  lib,
  user,
  ...
}:

let
  script = import ./script.nix { inherit pkgs; };

  sleepPre = script "sleep-pre" {
    inputs = [
      pkgs.coreutils
      pkgs.ethtool
      pkgs.kmod
    ];
  };
  sleepPost = script "sleep-post" {
    inputs = [
      pkgs.coreutils
      pkgs.kmod
      pkgs.systemd
    ];
  };
in

{
  services = {
    power-profiles-daemon.enable = false;
    # Wi-Fi power save on battery stays TLP's default: see wifi-nopowersave below.
    tlp = {
      enable = true;
      pd.enable = true;
    };
    # sched_ext scheduler; swap live with 'systemctl restart scx'.
    scx = {
      enable = true;
      scheduler = "scx_lavd";
    };
  };

  # Modules out of the s2idle path, no wakeups from the Ethernet card.
  powerManagement.powerDownCommands = ''
    ${lib.getExe sleepPre}
  '';
  powerManagement.resumeCommands = ''
    ${lib.getExe sleepPost}
  '';

  # Resets the MT7925 before its driver loads. Order: udev, this, network-pre.
  systemd.services.mt7925-init = {
    description = "PCIe FLR reset for MT7925 WiFi before driver probe";
    wantedBy = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mt7925-init" ''
        echo 1 > /sys/bus/pci/devices/0000:c0:00.0/reset
        sleep 0.5
        ${pkgs.kmod}/bin/modprobe mt7925e
      '';
    };
  };

  # 802.11 power save off while active: the geforcenow wrapper starts and stops it.
  systemd.services.wifi-nopowersave = {
    description = "Keep WiFi power save off";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iw}/bin/iw dev wlp192s0 set power_save off";
      # Back to what TLP would have set: on on battery, off on AC.
      ExecStop = pkgs.writeShellScript "wifi-powersave-restore" ''
        if [ "$(cat /sys/class/power_supply/ACAD/online)" = 0 ]; then
          ${pkgs.iw}/bin/iw dev wlp192s0 set power_save on
        fi
      '';
    };
  };
  # The launcher entry in ~/.local/share/applications points at this.
  environment.systemPackages = [ (script "geforcenow" { }) ];

  # The battery's charge limit, 80 or 100, from Quickshell's battery popup.
  # Nothing sets it at boot: the firmware is back at 80 by itself.
  systemd.services."battery-charge-limit@" = {
    description = "Set the battery's charge limit to %i%%";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "battery-charge-limit" ''
        case "$1" in
          80 | 100) echo "$1" > /sys/class/power_supply/BAT1/charge_control_end_threshold ;;
          *) echo "charge limit must be 80 or 100, not $1" >&2; exit 1 ;;
        esac
      ''} %i";
    };
  };

  # The user may start and stop the two services above without a password.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      var units = [
        "wifi-nopowersave.service",
        "battery-charge-limit@80.service",
        "battery-charge-limit@100.service"
      ];
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          units.indexOf(action.lookup("unit")) >= 0 &&
          subject.user == "${user}") {
        return polkit.Result.YES;
      }
    });
  '';
}
