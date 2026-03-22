# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    musnix.url = "github:musnix/musnix";
    niri.url = "github:sodiboo/niri-flake";
    awww.url = "git+https://codeberg.org/LGFae/awww";
	nix-index-database.url = "github:nix-community/nix-index-database";
	nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    #  ghostty.url = "github:ghostty-org/ghostty";
    #  nix-flatpak.url = "github:gmodena/nix-flatpak";
    #  hypridle.url = "github:hyprwm/hypridle";
    #  nix-search-tv.url = "github:3timeslazy/nix-search-tv";
    #  eza.url = "github:eza-community/eza";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      musnix,
      niri,
      awww,
      nix-index-database,
      #  ghostty,
      #  nix-flatpak,
      #  hypridle,
      #  nix-search-tv,
      #  eza,
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
          #  nix-flatpak.nixosModules.nix-flatpak
        ];
      };
    };
}
