# What runs with the niri session: the bar, the idle daemon, the wallpaper.
# All start with niri.service and stop when it goes.

{ pkgs, lib, ... }:

let
  script = import ./script.nix { inherit pkgs; };

  # A service of the session, stopped when niri goes (notes/desktop.md).
  withNiri = {
    bindsTo = [ "niri.service" ];
    after = [ "niri.service" ];
    wantedBy = [ "niri.service" ];
  };
  # The session's PATH instead of a Nix-built one, for programs that run others
  # (the bar's scripts, links).
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

    # Quickshell is polkit's agent too (Auth.qml), in place of niri-flake's.
    niri-flake-polkit.enable = false;

    hypridle = sessionPath // {
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
    };

    awww-daemon = withNiri // {
      description = "awww wallpaper daemon";
      serviceConfig = {
        Type = "simple";
        # After a login the desktop fades in from under Quickshell's curtain.
        ExecStartPre = lib.getExe (script "awww-wait-for-curtain" { inputs = [ pkgs.coreutils ]; });
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      path = [ pkgs.awww ];
    };

    gammastep = withNiri // {
      description = "Gammastep blue-light filter";
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

    "app-com.mitchell.ghostty" =
      withNiri
      // sessionPath
      // {
        after = [
          "graphical-session.target"
          "niri.service"
        ];
        description = "Ghostty in the background, for new windows without a start-up";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.ghostty}/bin/ghostty --gtk-single-instance=true --initial-window=false";
          Restart = "on-failure";
          RestartSec = "2s";
        };
      };
  };
}
