# Graphics, radios, the kernel and the disk. Background in notes/hardware.md,
# notes/s2idle.md and notes/mt7925.md.

{ pkgs, ... }:

{
  hardware.enableAllFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
    ];
  };
  # amdgpu.dcdebugmask=0x10. Keep while the s2idle hang is open (notes/s2idle.md).
  hardware.amdgpu.dcDebugMask.disablePsr = true;

  hardware.steam-hardware.enable = true;
  hardware.xone.enable = true; # Xbox controllers, by cable and the wireless adapter
  hardware.sane.enable = true; # scanners

  hardware.bluetooth = {
    enable = true;
    settings.General.Experimental = true; # battery charge of Bluetooth devices
  };
  services.blueman.enable = true;

  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="PL"
  '';

  # uaccess rules for Logitech HID++ nodes: systemPackages does not install them.
  services.udev.packages = [ pkgs.openlogi ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amdgpu.cwsr_enable=0" # MES ring wedge on gfx1150, likely redundant by now
      "amdgpu.gpu_recovery=1" # diagnostic for the s2idle hang, keep until explained
    ];
    initrd.luks.devices = {
      # Without allowDiscards fstrim does nothing under LUKS.
      "luks-175275f3-e11c-4a06-b71a-7050baff3149".allowDiscards = true; # /
      "luks-2388d8ad-9a00-401a-b4b4-8e3582a4ef9f" = {
        device = "/dev/disk/by-uuid/2388d8ad-9a00-401a-b4b4-8e3582a4ef9f";
        allowDiscards = true; # swap
      };
    };
    initrd.availableKernelModules = [ "usbhid" ];
    blacklistedKernelModules = [
      "ucsi_acpi" # spams "unknown error 256" on this hardware
      "mt7925e" # only kept from udev: mt7925-init loads it after a reset (power.nix)
    ];
    kernel.sysctl."vm.swappiness" = 10;
  };
}
