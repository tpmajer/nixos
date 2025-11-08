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
        ExecStartPre = '''';
        ExecStartPost = '''';
        Restart = "on-failure";
      };
      path = lib.mkForce [ ];
    };

    mako = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "Mako Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''/usr/bin/mako'';
        Restart = "on-failure";
      };
      path = lib.mkForce [ ];
    };

    waybar.path = lib.mkForce [ ];

  };

}
