# Fonts and the default families.

{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    adwaita-fonts
    fira-sans
    font-awesome
    nerd-fonts.adwaita-mono
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.lekton
    nerd-fonts.roboto-mono
    nerd-fonts.victor-mono
    noto-fonts-cjk-sans
    roboto
    work-sans
  ];

  # Generic families otherwise resolve to DejaVu.
  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "Adwaita Sans"
      "Noto Sans CJK JP"
    ];
    monospace = [
      "JetBrainsMono Nerd Font"
      "Noto Sans Mono CJK JP"
    ];
  };
}
