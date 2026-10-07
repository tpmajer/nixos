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
  systemd.services.minidlna.serviceConfig.ProtectHome = lib.mkForce "read-only";
  #DLNA
  services.minidlna.enable = true;
  services.minidlna.settings = {
    friendly_name = "DLNA MEDIA";
    media_dir = [
      "PV,${home}/Videos" # Videos files are located here
      "A,${home}/Music" # Audio files are here
    ];
    log_level = "error";
    # so changes in media dirs are updates in the server listing
    inotify = "yes";
    notify_interval = 60;
  };
  services.minidlna.openFirewall = true;
  environment.systemPackages = [ pkgs.inotify-tools ];

  users.users.minidlna = {
    extraGroups = [ "users" ]; # so minidlna can access the files.
  };

  # Necessary to share files from home dir
  users.users.${user}.homeMode = "755";

}
