# /etc/nixos/user-services.nix

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  systemd.user.services = {

    waybar = {
      path = lib.mkForce [ ];
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
    };

    hypridle = {
      path = lib.mkForce [ ];
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
    };

    awww-daemon = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      path = [ pkgs.awww ];
    };

    gammastep = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "Gammastep Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # The packaged unit ships in $out/share/systemd/user, but NixOS's
    # systemd.packages only scans etc/systemd/user and lib/systemd/user
    # (nixos/lib/systemd-lib.nix:441), so adding the package there would be a
    # no-op — define the unit here instead. Bound to niri.service like the rest
    # of the session services, not to the upstream graphical-session.target.
    # The agent takes ~/.config/openlogi/agent.lock and exits 0 if another
    # instance already holds it, so Restart=on-failure won't fight the GUI.
    openlogi-agent = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "OpenLogi background agent (Logitech HID++ device control)";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.openlogi}/bin/openlogi-agent";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    "app-com.mitchell.ghostty" = {
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
      path = lib.mkForce [ ];
    };

  };

}
