# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    wiremix.url = "github:tsowell/wiremix";
  };

  outputs =
    {
      self,
      nixpkgs,
      chaotic,
      wiremix,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./system.nix
          ./packages.nix
          ./fonts.nix
          chaotic.nixosModules.default
        ];
      };
    };
}
