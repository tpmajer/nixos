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

    blueman-applet = {
      after = [ "graphical-session.target" ];
      serviceConfig.ExecStart = lib.mkForce [
        ""
        "${pkgs.blueman}/bin/blueman-applet"
      ];
    };

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
      };
      path = lib.mkForce [ ];
    };

  };

}
