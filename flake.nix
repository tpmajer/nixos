# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    musnix.url = "github:musnix/musnix";
    niri.url = "github:sodiboo/niri-flake";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
    mako-blur.url = "github:tpmajer/mako/blur";
    #  <input_name>.url = "github:NixOS/nixpkgs/<hash_from_nixhub.io>";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      musnix,
      niri,
      nix-index-database,
      claude-code,
      mako-blur,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./system.nix
          ./packages.nix
          ./fonts.nix
          nixos-hardware.nixosModules.framework-amd-ai-300-series
          musnix.nixosModules.musnix
          niri.nixosModules.niri
          nix-index-database.nixosModules.default
        ];
      };
    };
}
