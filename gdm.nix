# /etc/nixos/gdm.nix

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{

  systemd.tmpfiles.rules =
    let
      monitors.xml = pkgs.writeText "monitors.xml" ''
        <monitors version="2">
          <configuration>
            <layoutmode>physical</layoutmode>
            <logicalmonitor>
              <x>0</x>
              <y>0</y>
              <scale>2</scale>
              <primary>yes</primary>
              <monitor>
                <monitorspec>
                  <connector>eDP-1</connector>
                  <vendor>BOE</vendor>
                  <product>NE135A1M-NY1</product>
                  <serial>0x00000000</serial>
                </monitorspec>
                <mode>
                  <width>2880</width>
                  <height>1920</height>
                  <rate>120.000</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
        </monitors>
      '';
    in
    [
      "L /etc/xdg/monitors.xml - - - - ${monitors.xml}"
    ];

  #programs.dconf.profiles.user = {
  #  databases = [
  #    {
  #      lockAll = true;
  #      settings = {
  #        "org/gnome/mutter" = {
  #          edge-tiling = true;
  #          dynamic-workspaces = true;
  #          experimental-features = [
  #            "variable-refresh-rate"
  #            "scale-monitor-framebuffer"
  #          ];
  #        };
  #      };
  #    }
  #  ];
  #};

}
