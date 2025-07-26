# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    chromium
    git
	stow
	tree
    vim
    micro
    wget
    zsh
    ghostty
    starship
    zsh-autocomplete
    zsh-completions
    zsh-autosuggestions
    fzf
    yt-dlp
    wgcf
    yubikey-manager
    fastfetch
    btop
    htop
    neovim
    waybar
    warp-terminal
    gnome-tweaks
    signal-desktop
    nix-search-tv
    fuzzel
    mako
    swww
    nwg-bar
    swaylock
    xwayland-satellite
    cava
    simp1e-cursors
    catppuccin-gtk
    thunderbird
    bazaar_git
    evolve-core
    libnotify
    clock-rs
    grim
    slurp
    ncspot
    bat
    nixfmt-rfc-style
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      enableLsColors = true;
      syntaxHighlighting.enable = true;
    };
    niri.enable = true;
    starship.enable = true;
    firefox.enable = true;
    yazi.enable = true;
    television = {
      enable = true;
      enableZshIntegration = true;
    };
    fzf.fuzzyCompletion = true;
  };
}
