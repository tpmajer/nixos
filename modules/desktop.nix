# The login screen, sound, portals, the keyring and the desktop's services.
# Background in notes/desktop.md and notes/oo7.md.

{ pkgs, lib, ... }:

let
  # GDM 50's greeter crashes on its own pipewire-pulse: no sound for it.
  skipGreeter = {
    unitConfig.ConditionUser = map (u: "!${u}") [
      "gdm-greeter"
      "gdm-greeter-2"
      "gdm-greeter-3"
      "gdm-greeter-4"
      "gdm-greeter-5"
    ];
  };

  # Catppuccin Mocha, for newt dialogs (nmtui): widget=foreground,background.
  text = "#cdd6f4";
  green = "#a6e3a1";
  crust = "#11111b";
  base = "#1e1e2e";
in

{
  services = {
    displayManager.gdm.enable = true;
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
    dbus.packages = [ pkgs.gcr_3 ]; # gcr-prompter, for oo7's unlock dialog

    gnome.core-apps.enable = false;
    gnome.tinysparql.enable = true;
    gnome.localsearch.enable = true;
    gnome.sushi.enable = true; # Nautilus quick preview (Space)
    gvfs.enable = true;
    geoclue2.enable = true;

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

  # oo7-daemon's mlockall needs its whole address space under RLIMIT_MEMLOCK:
  # 2G for it, through user@.service, and the 8M default for everything else.
  systemd.services."user@".serviceConfig.LimitMEMLOCK = "2G";
  systemd.user.settings.Manager.DefaultLimitMEMLOCK = "8M";

  systemd.user.sockets = lib.genAttrs [ "pipewire" "pipewire-pulse" ] (_: skipGreeter);
  systemd.user.services =
    lib.genAttrs [ "pipewire" "pipewire-pulse" "wireplumber" ] (_: skipGreeter)
    // {
      oo7-daemon.serviceConfig.LimitMEMLOCK = "2G";
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
