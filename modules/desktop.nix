# Sound, portals, the keyring and the desktop's services.
# Background in notes/desktop.md and notes/oo7.md.

{ pkgs, lib, ... }:

let
  notGreeter.unitConfig.ConditionUser = "!greeter";

  # Catppuccin Mocha, for newt dialogs (nmtui): widget=foreground,background.
  text = "#cdd6f4";
  green = "#a6e3a1";
  crust = "#11111b";
  base = "#1e1e2e";

  # oo7's prompter under Plasma, with Quickshell drawing the prompt.
  secretPrompter = pkgs.writers.writePython3Bin "secret-prompter" {
    libraries = [ pkgs.python3Packages.dbus-fast ];
  } (builtins.readFile ../scripts/secret-prompter.py);
in

{
  services = {
    xserver.xkb.layout = "pl";
    libinput.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # The Secret Service: oo7 in place of gnome-keyring, which niri-flake turns on.
    oo7.enable = true;
    gnome.gnome-keyring.enable = lib.mkForce false;
    gnome.gcr-ssh-agent.enable = true; # would go off with gnome-keyring
    dbus.packages = [
      pkgs.gcr_3 # gcr-prompter, for gcr-ssh-agent's passphrase dialog
      (pkgs.writeTextDir "share/dbus-1/services/org.kde.secretprompter.service" ''
        [D-BUS Service]
        Name=org.kde.secretprompter
        Exec=${secretPrompter}/bin/secret-prompter
      '')
    ];

    gnome.core-apps.enable = false;
    gnome.tinysparql.enable = true;
    gnome.localsearch.enable = true;
    gnome.sushi.enable = true; # Nautilus quick preview (Space)
    gvfs.enable = true;

    flatpak.enable = true;
    fprintd.enable = true; # 'sudo fprintd-enroll $USER' to enroll
  };

  security.rtkit.enable = true;
  security.polkit.enable = true;

  # The Quickshell lock's password check; the name is from hyprlock's days.
  security.pam.services.hyprlock = {
    fprintAuth = false;
    oo7.enable = true;
  };

  # The lock's reader, a conversation of its own next to the password's: a
  # finger and nothing else.
  security.pam.services.lock-fingerprint = {
    fprintAuth = true;
    unixAuth = false;
  };
  # GDM's name for it, to go once ~/.dotfiles asks for the new one
  # (notes/greeter.md).
  security.pam.services.gdm-fingerprint = {
    fprintAuth = true;
    unixAuth = false;
  };

  # Quickshell's polkit prompt: the reader gives way to the password after
  # 10 s, not 30.
  security.pam.services.polkit-1.rules.auth.fprintd.settings.timeout = 10;

  # oo7-daemon's mlockall needs its whole address space under RLIMIT_MEMLOCK:
  # 2G for it, through user@.service, and the 8M default for everything else.
  systemd.services."user@".serviceConfig.LimitMEMLOCK = "2G";
  systemd.user.settings.Manager.DefaultLimitMEMLOCK = "8M";

  # Neither a keyring nor an SSH agent for the login screen's user.
  systemd.user.sockets.gcr-ssh-agent = notGreeter;
  systemd.user.services.gcr-ssh-agent = notGreeter;
  systemd.user.services.oo7-daemon = notGreeter // {
    serviceConfig.LimitMEMLOCK = "2G";
    # oo7 asks org.kde.secretprompter, not gcr-prompter, only under Plasma.
    environment.XDG_CURRENT_DESKTOP = "KDE";
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };
  xdg.terminal-exec.enable = true; # Nautilus opens ghostty instead of kgx

  environment.variables = {
    EDITOR = "micro";
    VISUAL = "micro";
    TERMINAL = "ghostty";
    NEWT_COLORS = lib.concatStringsSep " " [
      "root=${text},${crust}"
      "border=${green},${crust}"
      "window=${crust},${crust}"
      "shadow=${crust},${crust}"
      "title=${green},${crust}"
      "button=${crust},${green}"
      "button_active=${crust},${base}"
      "actbutton=${green},${crust}"
      "compactbutton=${green},${crust}"
      "checkbox=${green},${crust}"
      "entry=${green},${crust}"
      "disentry=${crust},${crust}"
      "textbox=${green},${crust}"
      "acttextbox=${green},${crust}"
      "label=${green},${crust}"
      "listbox=${green},${crust}"
      "actlistbox=${green},${crust}"
      "sellistbox=${green},${crust}"
      "actsellistbox=${crust},${green}"
    ];
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
