# /etc/nixos/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    niri.url = "github:sodiboo/niri-flake";
    awww.url = "git+https://codeberg.org/LGFae/awww";
    ghostty.url = "github:ghostty-org/ghostty";
    #  hypridle.url = "github:hyprwm/hypridle";
    #  nix-search-tv.url = "github:3timeslazy/nix-search-tv";
    #  eza.url = "github:eza-community/eza";
  };

  outputs =
    {
      self,
      nixpkgs,
      chaotic,
      niri,
      awww,
      ghostty,
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
          chaotic.nixosModules.default
          niri.nixosModules.niri
        ];
      };
    };
}
