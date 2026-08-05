# /etc/nixos/packages.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

# For specific versions: inputs.<input_name>.legacyPackages.${pkgs.stdenv.hostPlatform.system}.<package_name>

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
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    clinfo
    cliphist
    clock-rs
    coreutils
    diff-so-fancy
    discord
    distrobox
    eza
    # inputs.eza.packages.${pkgs.stdenv.hostPlatform.system}.default
    fastfetch
    fd
    ffmpeg-full
    ffmpegthumbnailer
    file-roller
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.grc
    fishPlugins.sponge
    fishPlugins.fzf-fish
    fragments
    fuzzel
    gammastep
    gh
    ghostty
    # inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    # graphite
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
    inotify-tools # for DLNA
    jq # for niri screencasting
    keepassxc
    lazygit
    libnotify
    libsecret
    loupe
    mako
    mesa
    micro
    millisecond
    (mpv.override {
      scripts = [
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
    ookla-speedtest
    opencommit
    papers
    pinentry-all
    pinta
    playerctl
    protonup-qt
    python3
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
    wlogout
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
      plugins = with pkgs; [
        # tmuxPlugins.catppuccin
      ];
    };
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 50";
      flake = "/home/tpmajer/.nixos"; # sets NH_OS_FLAKE variable for you
    };
    yubikey-manager.enable = true;
    yubikey-touch-detector = {
      enable = true;
      libnotify = true;
    };
    gnome-disks.enable = true;
    waybar.enable = true;
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
    hyprlock = {
      enable = true;
      # Reclaim fprintd device after Goodix USB re-enumeration on resume
      # (debug-session-2026-06-11.md) — upstream hyprlock permanently disables
      # fingerprint when the fprintd device object disappears.
      #package = pkgs.hyprlock.overrideAttrs (old: {
      #  patches = (old.patches or [ ]) ++ [ ./patches/hyprlock-fprint-reinit.patch ];
      #});
    };
    firefox = {
      enable = true;
      # Firefox 153 enables Local Network Access by default. unifi.ui.com is
      # controlled by a service worker, and LNA loses the address-space
      # classification for requests forwarded through it, so every call to the
      # console at *.id.ui.direct dies with no response — the Network app never
      # loads. The LNA gate itself logs "auto_allow"; the request is killed
      # anyway. Upstream: https://bugzilla.mozilla.org/show_bug.cgi?id=2056851
      # Exempt the target domain; the source-domain side of SkipDomains is
      # broken (https://bugzilla.mozilla.org/show_bug.cgi?id=2058449).
      policies.LocalNetworkAccess = {
        Enabled = true;
        SkipDomains = [ "*.id.ui.direct" ];
      };
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      gamescopeSession.enable = true;
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
