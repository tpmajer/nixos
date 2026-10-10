# A trial: SDDM in place of greetd's login screen, to see its hand-over to the
# session (notes/greeter.md). The default theme, and the password alone.

{ ... }:

{
  # The greeter under Xorg: SDDM's Wayland greeter and its compositor go as
  # the session starts, an X server stays until the session is up.
  services.xserver.enable = true;
  services.displayManager = {
    sddm.enable = true;
    defaultSession = "niri";
  };

  # As greeter.nix has it: a TTY and SDDM ask for the password.
  security.pam.services.login.fprintAuth = false;
}
