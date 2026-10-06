{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    # niri-src.url = "github:niri-wm/niri";  # main
    # niri-src.url = "github:niri-wm/niri/refs/pull/3481/head";  # PR
    niri.url = "github:epireyn/niri-flake";
    # niri.inputs.niri-unstable.follows = "niri-src"; # override source

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    claude-code.url = "github:sadjow/claude-code-nix";

    littlesnitch.url = "github:noblepayne/littlesnitch-linux-flake";
    littlesnitch.inputs.nixpkgs.follows = "nixpkgs";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # <input_name>.url = "github:NixOS/nixpkgs/<hash_from_nixhub.io>";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          # Secrets, kept out of the repo: see private.nix.example.
          private = import ./private.nix;
        };
        modules = [ ./modules ];
      };
    };
}
