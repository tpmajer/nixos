# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # niri-src.url = "github:niri-wm/niri";  # main
    # niri-src.url = "github:niri-wm/niri/refs/pull/3481/head";  # PR
    niri.url = "github:sodiboo/niri-flake";
    # niri.inputs.niri-unstable.follows = "niri-src"; # override source

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    claude-code.url = "github:sadjow/claude-code-nix";
    mako-blur.url = "github:tpmajer/mako/blur";

    firefox-nightly.url = "github:nix-community/flake-firefox-nightly";
    firefox-nightly.inputs.nixpkgs.follows = "nixpkgs";

    # <input_name>.url = "github:NixOS/nixpkgs/<hash_from_nixhub.io>";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      niri,
      nix-index-database,
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
          niri.nixosModules.niri
          nix-index-database.nixosModules.default
        ];
      };
    };
}
