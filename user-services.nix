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

  };

}
