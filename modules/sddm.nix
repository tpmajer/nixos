# A trial: SDDM in place of greetd's login screen, to see its hand-over to the
# session (notes/greeter.md). The default theme, and the password alone.

{ pkgs, config, ... }:

let
  # The session's mode, 120 Hz: the panel names 60 Hz as preferred too, and
  # a change of rate at the hand-over is a modeset, which shows.
  westonIni = (pkgs.formats.ini { }).generate "sddm-weston.ini" {
    keyboard.keymap_layout = config.services.xserver.xkb.layout;
    libinput.enable-tap = true;
    output = {
      name = "eDP-1";
      mode = "2880x1920@120.0";
    };
  };

  # SDDM ends its Wayland compositor with the greeter, at a login, and the VT
  # goes back to text before the session is up. It waits 5 s for it to go:
  # held for 3, the compositor keeps the VT until the session has the screen.
  compositor = pkgs.writeShellScript "sddm-compositor" ''
    ${pkgs.weston}/bin/weston --shell=kiosk -c ${westonIni} &
    child=$!
    trap '${pkgs.coreutils}/bin/sleep 3; kill "$child"' TERM
    wait "$child"
    wait "$child"
  '';
in

{
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositorCommand = "${compositor}";
    };
    defaultSession = "niri";
  };

  # As greeter.nix has it: a TTY and SDDM ask for the password.
  security.pam.services.login.fprintAuth = false;
}
