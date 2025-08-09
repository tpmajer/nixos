# /etc/nixos/user-services.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{

  systemd.user.services = {
    waybar = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "Waybar Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''/usr/bin/waybar'';
      };
    };
    mako = {
      enable = true;
      after = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      description = "Mako Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''/usr/bin/mako'';
      };
    };
  };

}
