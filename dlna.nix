{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  systemd.services.minidlna.serviceConfig.ProtectHome = lib.mkForce "read-only";
  #DLNA
  services.minidlna.enable = true;
  services.minidlna.settings = {
    friendly_name = "DLNA MEDIA";
    media_dir = [
      "PV,/home/tpmajer/Videos" # Videos files are located here
      "A,/home/tpmajer/Music" # Audio files are here
    ];
    log_level = "error";
    # so changes in media dirs are updates in the server listing
    # also make sure "inotify-tools" packages is installed
    inotify = "yes";
    notify_interval = 60;
  };
  services.minidlna.openFirewall = true;
  users.users.minidlna = {
    extraGroups = [ "users" ]; # so minidlna can access the files.
  };

}
