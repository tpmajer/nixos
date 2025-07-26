# /etc/nixos/fonts.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
    nerd-fonts.hack
    nerd-fonts.adwaita-mono
    nerd-fonts.jetbrains-mono
    work-sans
    noto-fonts-cjk-sans
    adwaita-fonts
    roboto
  ];
}
