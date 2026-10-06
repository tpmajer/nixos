# What runs with the niri session: the bar, the idle daemon, the wallpaper.
# All are bound to niri.service.

{ pkgs, lib, ... }:

let
  # A service of the session. path = [ ] keeps the session's PATH instead of a
  # Nix-built one, for programs that run others (the bar's scripts, links).
  withNiri = {
    after = [ "niri.service" ];
    wantedBy = [ "niri.service" ];
  };
  sessionPath.path = lib.mkForce [ ];
in

{
  services.hypridle.enable = true;

  systemd.user.services = {
    quickshell =
      withNiri
      // sessionPath
      // {
        description = "Quickshell bar";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.quickshell}/bin/quickshell";
          # always: it is the session lock too, and niri stays locked without it.
          Restart = "always";
          RestartSec = "2s";
        };
      };

    hypridle = sessionPath // {
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
    };

    awww-daemon = withNiri // {
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      path = [ pkgs.awww ];
    };

    gammastep = withNiri // {
      description = "Gammastep Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Defined here: NixOS does not pick the packaged unit up (notes/desktop.md).
    openlogi-agent = withNiri // {
      description = "OpenLogi background agent (Logitech HID++ device control)";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.openlogi}/bin/openlogi-agent";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    "app-com.mitchell.ghostty" = sessionPath // {
      after = [
        "graphical-session.target"
        "niri.service"
      ];
      wantedBy = [ "niri.service" ];
      description = "Ghostty Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.ghostty}/bin/ghostty --gtk-single-instance=true --initial-window=false";
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };
  };
}
