# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    coreutils
    colorls
    wl-clipboard-rs
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    grc
    wiremix
    pamixer
    google-chrome
    git
    stow
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
    transmission_4
    spotify
    zstd
    celluloid
    mesa
    ffmpeg
  ];

  programs = {
    fish.enable = true;
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
      enableFishIntegration = true;
    };
    fzf.fuzzyCompletion = true;
    light.enable = true;
  };
}
