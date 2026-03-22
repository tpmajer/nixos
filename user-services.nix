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
		ExecStart = "${inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww}/bin/awww-daemon";
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
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
      };
    };

  };

}
