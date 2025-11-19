# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
	inputs.awww.packages.${pkgs.system}.awww
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
    discord
    distrobox
    eza
    # inputs.eza.packages.${pkgs.system}.default
    fastfetch
    fd
    ffmpeg-full
    ffmpegthumbnailer
    file-roller
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.grc
    fishPlugins.sponge
    fuzzel
    # ghostty
    inputs.ghostty.packages.${pkgs.system}.default
    git
    gnome-calculator
    gnome-calendar
    gnome-font-viewer
    gnome-logs
    gnome-tweaks
    google-chrome
    grc
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gthumb
    gtk-layer-shell
    helix
    impala
	keepassxc
    lazygit
    libnotify
    libsecret
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
    networkmanager_dmenu
    nixfmt-rfc-style
    nushell
    nix-search-tv
    # inputs.nix-search-tv.packages.${pkgs.system}.default
    obsidian
    onlyoffice-desktopeditors
    papers
    pinentry-all
    pinta
    playerctl
    reaction # for ip46tables command
    signal-desktop
    simp1e-cursors
    simple-scan
    spotify
    starship
    stow
    superfile
    thunderbird
    timg # for terminal image preview
    transmission_4
    tree
    tuba
    # upscaler
    vulkan-tools
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

    waybar = {
      enable = true;
    };

    localsend = {
      enable = true;
      openFirewall = true;
    };

    fish = {
      enable = true;
      package = pkgs.fish;
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
