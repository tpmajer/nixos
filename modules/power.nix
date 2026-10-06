# Power management, suspend and the services around the battery and the Wi-Fi
# card. Background in notes/s2idle.md, notes/mt7925.md and notes/rtl8156.md.

{ pkgs, ... }:

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
    ${pkgs.kmod}/bin/rmmod amdxdna 2>/dev/null || true
    ${pkgs.kmod}/bin/rmmod mt7925e 2>/dev/null || true
    # The Framework 2.5G Ethernet card (Realtek RTL8156, 0bda:8156 on the xHCI at
    # 0000:c3:00.4) resumes the machine ~1 s into s2idle, but only with a cable attached:
    # the port loses power, the PHY sees the link change and signals a USB remote wakeup,
    # which surfaces as a PCIe PME on 0000:00:08.3 (IRQ 40). With the lid shut logind adds
    # its 30 s HoldoffTimeoutSec on top and the two turn into a suspend/resume loop — 928
    # cycles over the night of 2026-09-21. With power/wakeup set to disabled by hand a
    # suspend held (2026-09-22, debug-session-2026-09-22.md).
    # r8152 sets that flag itself, though — at probe from the chip's WoL bits, and to
    # "enabled" on every runtime suspend whatever WoL says — so a udev rule cannot hold it;
    # the one that was here until 2026-10-06 was undone within a second of boot. Hence here,
    # right before the suspend. TLP's WOL_DISABLE only covers PCI NICs. See
    # debug-session-2026-10-06.2.md.
    # - The card is found by its USB ID, not by its driver: as cdc_ncm (its other USB
    #   configuration) it has no WoL to turn off, but the flag is cleared all the same.
    # - Only with a link. Without one there is no link change to wake on, and the card is
    #   left alone, autosuspended: no USB resume on this xHCI (the one of the s2idle hang
    #   that is still open) on the way to every sleep. A link that comes up during the
    #   sleep can then wake the laptop, once: the next suspend finds the link and gets here.
    # - power/control=on keeps the card from autosuspending between here and the suspend,
    #   which would set the flag again; resumeCommands puts it back to auto. That used to
    #   rest on the 20 s autosuspend delay, which is nixos-hardware's and not this repo's.
    # - What fails is said in the journal (sleep-actions.service), as is a flag that is not
    #   "disabled" in the end: the udev rule was dead for two weeks with nothing to show it.
    # Cost: the laptop can no longer be woken over Ethernet, which is not a feature in use.
    for dev in /sys/bus/usb/devices/*; do
      [ "$(cat "$dev/idVendor" 2>/dev/null):$(cat "$dev/idProduct" 2>/dev/null)" = 0bda:8156 ] || continue
      for net in "$dev"/*/net/*; do
        [ "$(cat "$net/carrier" 2>/dev/null)" = 1 ] || continue
        echo on > "$dev/power/control" || echo "rtl8156: cannot keep ''${dev##*/} from autosuspending" >&2
        driver=$(basename "$(readlink -f "$net/device/driver")")
        if [ "$driver" = r8152 ]; then
          ${pkgs.ethtool}/bin/ethtool -s "''${net##*/}" wol d || echo "rtl8156: cannot turn WoL off on ''${net##*/}" >&2
        else
          echo "rtl8156: ''${net##*/} is driven by $driver, not r8152: no WoL to turn off" >&2
        fi
        echo disabled > "$dev/power/wakeup" || true
        wakeup=$(cat "$dev/power/wakeup" 2>/dev/null || true)
        [ "$wakeup" = disabled ] || echo "rtl8156: power/wakeup of ''${dev##*/} is '$wakeup': it can wake the laptop" >&2
      done
    done
  '';

  powerManagement.resumeCommands = ''
    # The RTL8156 may autosuspend again, see powerDownCommands.
    for dev in /sys/bus/usb/devices/*; do
      [ "$(cat "$dev/idVendor" 2>/dev/null):$(cat "$dev/idProduct" 2>/dev/null)" = 0bda:8156 ] || continue
      echo auto > "$dev/power/control" || true
    done
    # fprintd 1.94.5: a Release during PrepareForSleep drops its session but leaves the
    # device open, and every Claim fails until the daemon restarts. D-Bus starts a new one.
    # Safe now that the lock goes through pam_fprintd, which claims anew each time; hyprlock
    # did not (debug-session-2026-06-10.md). See debug-session-2026-10-03.md.
    ${pkgs.systemd}/bin/systemctl stop fprintd.service || true
    # The script runs under set -e: neither module failing to load may keep the other
    # from being tried. WiFi first, it is the one that is missed.
    ${pkgs.kmod}/bin/modprobe mt7925e || echo "resume: cannot load mt7925e" >&2
    ${pkgs.kmod}/bin/modprobe amdxdna || echo "resume: cannot load amdxdna" >&2
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
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "geforcenow" ''
      systemctl start wifi-nopowersave.service
      trap 'systemctl stop wifi-nopowersave.service' EXIT
      flatpak run --branch=master --arch=x86_64 --command=GeForceNOW com.nvidia.geforcenow "$@"
    '')
  ];

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
          subject.user == "tpmajer") {
        return polkit.Result.YES;
      }
    });
  '';
}
