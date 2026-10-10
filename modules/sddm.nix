# A trial: SDDM in place of greetd's login screen, to see its hand-over to the
# session (notes/greeter.md). The default theme, and the password alone.

{ pkgs, lib, ... }:

{
  # The greeter under Xorg: SDDM's Wayland greeter and its compositor go as
  # the session starts, an X server stays until the session is up.
  services.xserver.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      # The session's mode, 120 Hz: the panel names 60 Hz as preferred too,
      # and a change of rate at the hand-over is a modeset, which shows.
      setupScript = ''
        ${lib.getExe pkgs.xrandr} --output eDP-1 --mode 2880x1920 --rate 120 ||
          ${lib.getExe pkgs.xrandr} --output eDP --mode 2880x1920 --rate 120 || true
      '';
    };
    defaultSession = "niri";
  };

  # As greeter.nix has it: a TTY and SDDM ask for the password.
  security.pam.services.login.fprintAuth = false;
}
