# /etc/nixos/user-services.nix

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  # 'readlink -f $(which gammastep)' for ExecStart path
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
        ExecStart = "/nix/store/d41pzshfs5al9a1s3mli5gpc58h3p69y-awww-0.11.2-master2/bin/awww-daemon";
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
        ExecStart = "/nix/store/wfarb208xx8bijjqb9l5hv1x2wzkr2dn-gammastep-2.0.11/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
      };
    };

  };

}
