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

#  hardware.enableAllFirmware = true;

  boot = {
  	loader = {
    	systemd-boot.enable = true;
    	efi.canTouchEfiVariables = true;
  	};
	kernelPackages = pkgs.linuxPackages_latest;
	initrd.luks.devices."luks-2388d8ad-9a00-401a-b4b4-8e3582a4ef9f".device = "/dev/disk/by-uuid/2388d8ad-9a00-401a-b4b4-8e3582a4ef9f";
  };

  networking.hostName = "nixos";
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "pl_PL.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  console.keyMap = "pl2";

  security.rtkit.enable = true;


# Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services = {
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
  };

  users.users.tpmajer = {
    isNormalUser = true;
    description = "Tomasz Majer";
    extraGroups = [
      "networkmanager"
      "wheel"
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

  environment.variables.EDITOR = "micro";

  system.stateVersion = "25.05";

}
