# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
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
    #  inputs.eza.packages.${pkgs.stdenv.hostPlatform.system}.default
    fastfetch
    fd
    ffmpeg-full
    ffmpegthumbnailer
    file-roller
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.grc
    fishPlugins.sponge
    fragments
    fuzzel
    ghostty
    #  inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    git
    gnome-calculator
    gnome-calendar
    gnome-font-viewer
    gnome-logs
    gnome-network-displays
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
    #  impala
    jq # for niri screencasting
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
    newsflash
    nixfmt-rfc-style
    nushell
    nix-search-tv
    #  inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default
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
	tidal-hifi
    timg # for terminal image preview
    tree
    tuba
    upscaler
    vulkan-tools
    wgcf
    wget
    #  winbox4
    wireguard-tools
    wiremix
    wl-clipboard-rs
    wl-mirror
    wlogout
    xwayland-satellite
    yt-dlp
    zstd
  ];

  nixpkgs.overlays = with pkgs; [ 
  	inputs.niri.overlays.niri
  	(self: super: {
  	    mpv-unwrapped = super.mpv-unwrapped.override {
  	      ffmpeg = ffmpeg-full;
  	    };
  	})
  ];

 # nixpkgs.overlays = with pkgs; [
 #   (self: super: {
 #     mpv = super.mpv.override {
 #       ffmpeg = ffmpeg-full;
 #     };
 #   })
 # ];

  programs = {
     
    yubikey-manager.enable = true;
    yubikey-touch-detector = {
      enable = true;
      libnotify = true;
    };

    gnome-disks.enable = true;

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

    firefox = {
      enable = true;
      package = pkgs.firefox;
    };

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
