# /etc/nixos/system.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    amdvlk
    mesa.opencl
  ];
  hardware.steam-hardware.enable = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.luks.devices."luks-2388d8ad-9a00-401a-b4b4-8e3582a4ef9f".device =
      "/dev/disk/by-uuid/2388d8ad-9a00-401a-b4b4-8e3582a4ef9f";
    initrd.availableKernelModules = [ "usbhid" ];
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  #  networking.wireless.iwd = {
  #    enable = true;
  #    settings = {
  #      IPv6.Enabled = false;
  #      Settings.AutoConnect = true;
  #      Settings.BandModifier2_4Ghz = "0";
  #      Settings.BandModifier5Ghz = "1";
  #      Settings.BandModifier6Ghz = "10";
  #    };
  #  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  console.keyMap = "pl2";

  security.rtkit.enable = true;

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  systemd.services.systemd-vconsole-setup = {
    unitConfig = {
      After = "local-fs.target";
    };
  };

  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  services = {
    preload.enable = true;
    power-profiles-daemon.enable = true;
    fwupd.enable = true;
    xserver.enable = false;
    xserver.xkb = {
      layout = "pl";
      variant = "";
    };
    desktopManager.gnome.enable = true;
    displayManager = {
      gdm.enable = true;
      autoLogin = {
        enable = true;
        user = "tpmajer";
      };
    };
    printing.enable = false;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    flatpak.enable = true;
    envfs.enable = true;
    fprintd.enable = true; # 'sudo fprintd-enroll $USER' to enroll
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          #"use sendfile" = "yes";
          #"max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "192.168.0. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
      };
    };
  };

  users.users.tpmajer = {
    isNormalUser = true;
    description = "Tomasz Majer";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];
    packages = with pkgs; [
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
    ];
  };
  environment.variables.EDITOR = "micro";
  environment.variables.RUSTICL_ENABLE = "radeonsi";

  system.stateVersion = "25.05";

}
