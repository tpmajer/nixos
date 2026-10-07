{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
    nerd-fonts.hack
    nerd-fonts.adwaita-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.victor-mono
    nerd-fonts.lekton
    work-sans
    noto-fonts-cjk-sans
    adwaita-fonts
    roboto
    font-awesome
    fira-sans
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
