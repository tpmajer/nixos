# Fonts and the default families.

{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    adwaita-fonts
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
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
