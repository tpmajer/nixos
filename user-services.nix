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

    xwayland-satellite = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "xwayland-satellite Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''/usr/bin/xwayland-satellite :1'';
        Restart = "on-failure";
      };
      path = [ pkgs.xwayland-satellite ];
    };

    awww-daemon = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''/usr/bin/awww-daemon'';
        Restart = "on-failure";
      };
	  path = [ inputs.awww.packages.${pkgs.system}.awww ];
    };

    waybar.path = lib.mkForce [ ];

  };

}
