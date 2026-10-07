# MiniDLNA serving ~/Videos and ~/Music. Not imported by default.

{
  pkgs,
  lib,
  config,
  user,
  ...
}:

let
  inherit (config.users.users.${user}) home;
in

{
  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "DLNA MEDIA";
      media_dir = [
        "PV,${home}/Videos"
        "A,${home}/Music"
      ];
      log_level = "error";
      # Changes in the media directories show up in the server's listing.
      inotify = "yes";
      notify_interval = 60;
    };
  };
  systemd.services.minidlna.serviceConfig.ProtectHome = lib.mkForce "read-only";
  environment.systemPackages = [ pkgs.inotify-tools ];

  # So that minidlna can read the files, and get to them in the home directory.
  users.users.minidlna.extraGroups = [ "users" ];
  users.users.${user}.homeMode = "755";
}
