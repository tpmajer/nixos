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
    bazaar
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
    clapgrep
    # claude-code
	inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    clinfo
    cliphist
    clock-rs
    coreutils
    diff-so-fancy
    discord
    distrobox
    distroshelf
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
    fishPlugins.fzf-fish
    fragments
    fuzzel
    gammastep
    ghostty
    #  inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    #  impala
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
    opencommit
    papers
    pinentry-all
    pinta
    playerctl
    protonup-qt
	python3
    reaction # for ip46tables command
    reaper
    reaper-reapack-extension
    reaper-sws-extension
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
    upscaler
    uxplay
    vaults
    vulkan-tools
    wayland-utils
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
	#  zoxide
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
	    	
	    # Enable mouse support
	    set -g mouse on

	  '';
	};
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 50";
      flake = "/etc/nixos"; # sets NH_OS_FLAKE variable for you
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
    hyprlock.enable = true;
    firefox = {
      enable = true;
      package = pkgs.firefox;
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
