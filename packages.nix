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
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-ugly
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
    simple-scan
    gnome-calendar
    gthumb
    papers
    clinfo
    vulkan-tools
    davinci-resolve
    ffmpegthumbnailer
    pinta
    walker
    # inputs.vicinae.packages.x86_64-linux.default
    nmgui
    cachix
  ];

  programs = {

    localsend = {
      enable = true;
      openFirewall = true;
    };

    fish = {
      enable = true;
      generateCompletions = true;
      vendor = {
        config.enable = true;
        functions.enable = true;
        completions.enable = true;
      };
    };

    starship.enable = true;

    television = {
      enable = true;
      enableFishIntegration = true;
    };

    niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };

    hyprlock.enable = true;

    firefox.enable = true;

    steam.enable = false;

    dconf.profiles.user = {
      databases = [
        {
          lockAll = true;
          settings = {
            "org/gnome/desktop/privacy" = {
              remember-recent-files = false;
            };
          };
        }
      ];
    };

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };

  };

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

}
