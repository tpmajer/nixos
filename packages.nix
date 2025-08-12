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
    fd
    wl-clipboard-rs
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.grc
    grc
    wiremix
    google-chrome
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
    networkmanager_dmenu
    tuba
    davinci-resolve
    showtime
    distrobox
    superfile
    candy-icons
    catppuccin-papirus-folders
    nix-search-tv
    timg # for terminal image preview
    krita
    godot
    obsidian
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
    niri.enable = true;
    starship.enable = true;
    firefox.enable = true;
    television = {
      enable = true;
      enableFishIntegration = true;
    };
    steam.enable = true;
  };
}
