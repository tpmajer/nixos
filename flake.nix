# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    vicinae.url = "github:vicinaehq/vicinae";
	niri.url = "github:sodiboo/niri-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      chaotic,
      vicinae,
      niri,
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
