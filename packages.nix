# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    baobab
    bat
    bluetui
    brightnessctl
    btop
    cachix
    calcure
    caligula # TUI for disk imaging
    candy-icons
    catppuccin-papirus-folders
    cava
    clean-css-cli # css formatter
    clinfo
    cliphist
    clock-rs
    coreutils
    davinci-resolve
    discord
    distrobox
    fastfetch
    fd
    ffmpeg-full
    ffmpegthumbnailer
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.grc
    fuzzel
    ghostty
    git
    gnome-calendar
    gnome-font-viewer
    gnome-logs
    gnome-tweaks
    google-chrome
    grc
    grim
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-ugly
    gthumb
    gtk-layer-shell
    helix
    impala
    libnotify
    loupe
    mako
    mesa
    micro
    (mpv.override {
      scripts = [
        mpvScripts.uosc
      ];
    })
    nautilus
    ncspot
    networkmanager_dmenu
    nixfmt-rfc-style
    nix-search-tv
    nmgui
    nwg-bar
    obsidian
    onlyoffice-desktopeditors
    papers
    pinta
    playerctl
    reaction # for ip46tables command
    signal-desktop
    simp1e-cursors
    simple-scan
    slurp
    spotify
    starship
    stow
    superfile
    inputs.swww.packages.${pkgs.system}.swww
    thunderbird
    timg # for terminal image preview
    transmission_4
    tree
    tuba
    upscaler
    # inputs.vicinae.packages.${pkgs.system}.default
    vulkan-tools
    waybar
    wgcf
    wget
    wireguard-tools
    wiremix
    wl-clipboard-rs
    wlogout
    xwayland-satellite
    yt-dlp
    yubikey-manager
    zstd
  ];

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

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

}
