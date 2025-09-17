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
    ./network.nix
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocminfo
    ];
  };
  hardware.steam-hardware.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge of Bluetooth devices
      };
    };
  };
  hardware.sane.enable = true; # enables support for SANE scanners

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    #  kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxPackages_cachyos;
    initrd.luks.devices."luks-2388d8ad-9a00-401a-b4b4-8e3582a4ef9f".device =
      "/dev/disk/by-uuid/2388d8ad-9a00-401a-b4b4-8e3582a4ef9f";
    initrd.availableKernelModules = [
      "usbhid"
    ];
    blacklistedKernelModules = [ "ucsi_acpi" ];
  };

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
  security.polkit.enable = true;
  security.pam.services.hyprlock = { };
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = "
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ";
  };

  services = {
    hypridle.enable = true;
    gnome.gnome-keyring.enable = true;
    gnome.core-apps.enable = false;
    gvfs.enable = true;
    geoclue2.enable = true;
    preload.enable = true;
    power-profiles-daemon.enable = false;
    tlp.enable = true;
    fwupd.enable = true;
    xserver.enable = false;
    xserver.xkb = {
      layout = "pl";
      variant = "";
    };
    blueman.enable = true;
    desktopManager.gnome.enable = false;
    displayManager = {
      gdm.enable = true;
      autoLogin = {
        enable = false;
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
      "scanner"
      "lp"
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
      substituters = [ "https://vicinae.cachix.org" ];
      trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
  xdg.terminal-exec.enable = true; # Makes nautilus open ghostty insted of kgx

  environment.variables.EDITOR = "micro";
  environment.variables.VISUAL = "micro";
  environment.variables.TERMINAL = "ghostty";
  environment.variables.RUSTICL_ENABLE = "radeonsi";
  environment.variables.AMD_VULKAN_ICD = "RADV";
  environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID"; # set the runtime directory
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.NEWT_COLORS = "root=#cdd6f4,#11111b border=#a6e3a1,#11111b window=#11111b,#11111b shadow=#11111b,#11111b title=#a6e3a1,#11111b button=#11111b,#a6e3a1 button_active=#11111b,#1e1e2e actbutton=#a6e3a1,#11111b compactbutton=#a6e3a1,#11111b checkbox=#a6e3a1,#11111b entry=#a6e3a1,#11111b disentry=#11111b,#11111b textbox=#a6e3a1,#11111b acttextbox=#a6e3a1,#11111b label=#a6e3a1,#11111b listbox=#a6e3a1,#11111b actlistbox=#a6e3a1,#11111b sellistbox=#a6e3a1,#11111b actsellistbox=#11111b,#a6e3a1";

  system.stateVersion = "25.05";

}
