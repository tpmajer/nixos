# Packages and the programs configured through NixOS.
# A specific version: inputs.<name>.legacyPackages.${pkgs.stdenv.hostPlatform.system}.<package>

{
  pkgs,
  config,
  inputs,
  user,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    awww
    baobab
    bat
    bella
    bluetui
    brightnessctl
    btop
    cachix
    calcure
    caligula # TUI for disk imaging
    candy-icons
    catppuccin-papirus-folders
    cava
    claude-code # from the claude-code input's overlay (core.nix), not nixpkgs
    clinfo
    cliphist
    clock-rs
    diff-so-fancy
    discord
    distrobox
    editorconfig-core-c # for micro's editorconfig plugin (~/.dotfiles)
    eza
    fastfetch
    fd
    ffmpeg-full
    ffmpegthumbnailer
    file-roller
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.grc
    fishPlugins.sponge
    fragments
    fuzzel
    gammastep
    gh
    ghostty
    git
    git-filter-repo
    gnome-calculator
    gnome-calendar
    gnome-feeds
    gnome-font-viewer
    gnome-logs
    gnome-network-displays
    gnome-tweaks
    gocryptfs
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
    jq # for niri screencasting
    keepassxc
    lazygit
    libnotify
    libsecret
    loupe
    micro
    millisecond
    miru # Wayland screen magnifier / cursor spotlight
    (mpv.override {
      scripts = [
        mpvScripts.mpris
        mpvScripts.uosc
      ];
    })
    nautilus
    nautilus-python
    ncdu
    networkmanager_dmenu
    newsflash
    nfs-utils
    nixfmt
    nodejs # for CC MCP servers
    nushell
    obsidian
    onlyoffice-desktopeditors
    opencommit
    openlogi
    papers
    pinentry-all
    pinta
    playerctl
    python3
    quickshell # the bar, config in ~/.dotfiles/.config/quickshell
    reaction # for ip46tables command
    ripgrep
    signal-desktop
    simp1e-cursors
    simple-scan
    spotify
    starship
    stow
    superfile
    thunderbird
    timg # for terminal image preview
    tree
    tuba
    # upscaler  # pysdl2 test failures with current SDL2_ttf/FreeType
    vulkan-tools
    wayland-utils
    wgcf
    wget
    wireguard-tools
    wiremix
    wl-clipboard-rs
    wl-mirror
    xwayland-satellite
    yt-dlp
    zstd
  ];

  programs = {
    nix-index-database.comma.enable = true;
    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };
    tmux = {
      enable = true;
      clock24 = true;
      aggressiveResize = true;
      baseIndex = 1;
      extraConfig = ''
        set-option -g default-shell ${pkgs.fish}/bin/fish
        set -g allow-passthrough on
        set -g mouse on
        set -g default-terminal "tmux-256color"
        set -g status-style bg=default,fg=green
        set -g status-left ""
      '';
    };
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 50";
      flake = "${config.users.users.${user}.home}/.nixos"; # sets NH_OS_FLAKE variable for you
    };
    yubikey-manager.enable = true;
    yubikey-touch-detector = {
      enable = true;
      libnotify = true;
    };
    gnome-disks.enable = true;
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
    niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };
    firefox = {
      enable = true;
      # Local Network Access breaks unifi.ui.com's console (notes/desktop.md).
      policies.LocalNetworkAccess = {
        Enabled = true;
        SkipDomains = [ "*.id.ui.direct" ];
      };
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      # Proton from chaotic: its name in Steam stays the same across updates.
      extraCompatPackages = [ pkgs.proton-cachyos_x86_64_v3 ];
    };
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
