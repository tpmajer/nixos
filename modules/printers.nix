# ~/.nixos/printers.nix

{
  config,
  pkgs,
  inputs,
  lib,
  private,
  ...
}:

{
  services.printing = {
    enable = true;
    drivers = [ pkgs.samsung-unified-linux-driver ];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Xerox-Phaser-3020";
        deviceUri = "usb://Xerox/Phaser%203020?serial=${private.printerSerial}";
        model = "samsung/ML-2160.ppd";
        ppdOptions.PageSize = "A4";
      }
    ];
    ensureDefaultPrinter = "Xerox-Phaser-3020";
  };
}
