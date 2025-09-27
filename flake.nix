# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
	niri.url = "github:sodiboo/niri-flake";
	swww.url = "github:LGFae/swww";
  };

  outputs =
    {
      self,
      nixpkgs,
      chaotic,
      niri,
      swww,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./system.nix
          ./packages.nix
          # ./user-services.nix
          ./fonts.nix
          chaotic.nixosModules.default
          niri.nixosModules.niri
        ];
      };
    };
}
