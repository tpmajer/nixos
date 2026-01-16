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

    waybar.path = lib.mkForce [ ];
    hypridle.path = lib.mkForce [ ];

    awww-daemon = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "/nix/store/kr7w964dm4kbjz5h71bx70x7vpmbsa3r-awww-0.11.2-master2/bin/awww-daemon";
        Restart = "on-failure";
      };
      path = [ inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww ];
    };

    gammastep = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "Gammastep Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "/nix/store/iggczrfkalgj6m57k3555dxbxwm4x2is-gammastep-2.0.11/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
      };
    };

  };

}
