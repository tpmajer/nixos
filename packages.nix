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
	xwayland-satellite
    discord
    helix
    coreutils
    reaction # for ip46tables command
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
    neovim
    waybar
    gnome-tweaks
    signal-desktop
    fuzzel
    mako
    swww
    nwg-bar
    cava
    simp1e-cursors
    thunderbird
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
    ffmpeg-full
    onlyoffice-desktopeditors
    impala
    wlogout
    gtk-layer-shell
    cliphist
    calcure
    tree
    networkmanager_dmenu
    tuba
    distrobox
    superfile
    candy-icons
    catppuccin-papirus-folders
    nix-search-tv
    timg # for terminal image preview
    obsidian
    wireguard-tools
    upscaler
    clean-css-cli # css formatter
    caligula # TUI for disk imaging
    (mpv.override {
      scripts = [
        mpvScripts.uosc
      ];
    })
    gnome-logs
    gnome-font-viewer
    loupe
    nautilus
    baobab
    gthumb
    papers
    clinfo
    vulkan-tools
    davinci-resolve
  ];

  programs = {
    localsend = {
      enable = true;
      openFirewall = true;
    };
    hyprlock.enable = true;
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
    steam.enable = false;
  };
}
