# Locale, the user, sudo and Nix itself.

{ pkgs, inputs, ... }:

{
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

  users.users.tpmajer = {
    isNormalUser = true;
    description = "Tomasz Majer";
    extraGroups = [
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

  security.sudo.extraConfig = ''
    Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
    Defaults insults
    # wgauto (fish function) re-enables the wg-auto dispatcher without a password;
    # disabling it (touch + stopping wg0) still asks for one on purpose.
    tpmajer ALL=(root) NOPASSWD: /run/current-system/sw/bin/rm -f /var/lib/wg-auto-disabled
  '';

  services = {
    userborn.enable = true;
    dbus.implementation = "broker";
    fwupd.enable = true;
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.claude-code.overlays.default
      inputs.niri.overlays.niri
      (self: super: {
        mpv-unwrapped = super.mpv-unwrapped.override {
          ffmpeg = super.ffmpeg-full;
        };
      })
    ];
  };

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://claude-code.cachix.org" ];
    trusted-public-keys = [
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    ];
  };

  system.stateVersion = "25.05";
}
