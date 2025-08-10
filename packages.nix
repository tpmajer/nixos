# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    git
    stow
    ghostty
    starship
    wget
    vim
    micro
    bluetui
    brightnessctl
    playerctl
    discord
    helix
    coreutils
    wl-clipboard-rs
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    grc
    wiremix
    google-chrome
    fzf
    yt-dlp
    wgcf
    yubikey-manager
    fastfetch
    neofetch
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
    xwayland-satellite
    cava
    simp1e-cursors
    thunderbird
    bazaar_git
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
    mesa
    ffmpeg
    onlyoffice-desktopeditors
    #    impala
    wlogout
    gtk-layer-shell
    cliphist
    calcure
    tree
    firefox_nightly
    networkmanager_dmenu
    tuba
    davinci-resolve
    showtime
    distrobox
    superfile
    candy-icons
    catppuccin-papirus-folders
  ];

  programs = {
    fish = {
      enable = true;
      generateCompletions = true;
      vendor = {
        config.enable = true;
        functions.enable = true;
        completions.enable = true;
      };
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    niri.enable = true;
    starship.enable = true;
    firefox.enable = true;
    television = {
      enable = true;
      enableFishIntegration = true;
    };
    fzf.fuzzyCompletion = true;
    steam.enable = true;
  };
}
