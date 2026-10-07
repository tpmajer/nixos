{ inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    inputs.niri.nixosModules.niri
    inputs.nix-index-database.nixosModules.default
    inputs.littlesnitch.nixosModules.default
    inputs.chaotic.nixosModules.default

    ../hardware-configuration.nix
    ./core.nix
    ./hardware.nix
    ./power.nix
    ./desktop.nix
    ./session.nix
    ./background-apps.nix
    ./network.nix
    ./wireguard.nix
    ./packages.nix
    ./fonts.nix
    ./printers.nix
    ./littlesnitch.nix

    # ./optional/llm.nix
    # ./optional/dlna.nix
  ];
}
