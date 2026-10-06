{ inputs, ... }:

{
  imports = [
    ./core.nix
    ./hardware.nix
    ./power.nix
    ./desktop.nix
    ./packages.nix
    ./fonts.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    inputs.niri.nixosModules.niri
    inputs.nix-index-database.nixosModules.default
    inputs.littlesnitch.nixosModules.default
    ./littlesnitch.nix
    inputs.chaotic.nixosModules.default

    ../hardware-configuration.nix
    ./network.nix
    ./wireguard.nix
    ./session.nix
    ./background-apps.nix
    # ./optional/llm.nix
    ./printers.nix
    # ./optional/dlna.nix
  ];
}
