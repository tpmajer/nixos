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
      enable = true;
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
      };
      path = [ pkgs.awww ];
    };

    gammastep = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "Gammastep Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
      };
    };

  };

}
