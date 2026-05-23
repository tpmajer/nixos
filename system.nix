# /etc/nixos/system.nix

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./user-services.nix
    ./llm.nix
    ./printers.nix
    # ./dlna.nix
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

  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="PL"
  '';

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
      };
      efi.canTouchEfiVariables = true;
    };
    # kernelPackages = pkgs.linuxPackages;
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.luks.devices."luks-2388d8ad-9a00-401a-b4b4-8e3582a4ef9f".device =
      "/dev/disk/by-uuid/2388d8ad-9a00-401a-b4b4-8e3582a4ef9f";
    initrd.availableKernelModules = [ "usbhid" ];
    blacklistedKernelModules = [
      "ucsi_acpi"
      "mt7925e"
      "amdxdna"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
    kernelPatches = [
      {
        name = "btmtk-fix-func-ctrl-too-short";
        patch = ./patches/btmtk-fix-func-ctrl-too-short.patch;
      }
    ];
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
  security.pam.services.hyprlock = {
    fprintAuth = false; # removes pam_fprintd.so from PAM for hyprlock
  };
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
  security.sudo.extraConfig = ''
    Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
    Defaults insults
  '';

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  services = {
    dbus.implementation = "broker";
    hypridle.enable = true;
    gnome.gnome-keyring.enable = true;
    gnome.core-apps.enable = false;
    gnome.tinysparql.enable = true;
    gnome.localsearch.enable = true;
    gvfs.enable = true;
    geoclue2.enable = true;
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      pd.enable = true;
    };
    fwupd.enable = true;
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

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    flatpak.enable = true;
    envfs.enable = false; # Fuse filesystem that returns symlinks to executables based on the PATH of the requesting process.
    fprintd.enable = true; # 'sudo fprintd-enroll $USER' to enroll
  };

  systemd.services.pcie-flr-init = {
    description = "PCIe FLR reset for MT7925 WiFi and AMDXDNA NPU before driver probe";
    wantedBy = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "pcie-flr-init" ''
        echo 1 > /sys/bus/pci/devices/0000:c2:00.1/reset
        echo 1 > /sys/bus/pci/devices/0000:c0:00.0/reset
        sleep 0.5
        ${pkgs.kmod}/bin/modprobe amdxdna
        ${pkgs.kmod}/bin/modprobe mt7925e
      '';
    };
  };

  users.users.tpmajer = {
    isNormalUser = true;
    description = "Tomasz Majer";
    extraGroups = [
      "users"
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "scanner"
      "lp"
    ];
    packages = with pkgs; [
    ];
  };

  nixpkgs = {

    config.allowUnfree = true;

    overlays = with pkgs; [
      inputs.mako-blur.overlays.default
      inputs.claude-code.overlays.default
      inputs.niri.overlays.niri
      (self: super: {
        mpv-unwrapped = super.mpv-unwrapped.override {
          ffmpeg = ffmpeg-full;
        };
      })
    ];

  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://niri.cachix.org"
        "https://claude-code.cachix.org"
        # "https://ghostty.cachix.org"
      ];
      trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        # "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      ];
    };
    gc = {
      automatic = false;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      gnome-keyring
    ];
  };
  xdg.terminal-exec.enable = true; # Makes nautilus open ghostty insted of kgx

  environment.variables = {
    EDITOR = "micro";
    VISUAL = "micro";
    TERMINAL = "ghostty";
    RUSTICL_ENABLE = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
    XDG_RUNTIME_DIR = "/run/user/$UID"; # set the runtime directory
    NEWT_COLORS = "root=#cdd6f4,#11111b border=#a6e3a1,#11111b window=#11111b,#11111b shadow=#11111b,#11111b title=#a6e3a1,#11111b button=#11111b,#a6e3a1 button_active=#11111b,#1e1e2e actbutton=#a6e3a1,#11111b compactbutton=#a6e3a1,#11111b checkbox=#a6e3a1,#11111b entry=#a6e3a1,#11111b disentry=#11111b,#11111b textbox=#a6e3a1,#11111b acttextbox=#a6e3a1,#11111b label=#a6e3a1,#11111b listbox=#a6e3a1,#11111b actlistbox=#a6e3a1,#11111b sellistbox=#a6e3a1,#11111b actsellistbox=#11111b,#a6e3a1";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.pathsToLink = [
    "/share/gnome-session" # GDM 50: gdm pkg provides gnome-login.session here; not in default pathsToLink, so it must be added explicitly
  ];

  system.stateVersion = "25.05";

}
