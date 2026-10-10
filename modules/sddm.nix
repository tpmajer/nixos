# A trial: SDDM in place of greetd's login screen, to see its hand-over to the
# session (notes/greeter.md). The default theme, and the password alone.

{ ... }:

{
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "niri";
  };

  # As greeter.nix has it: a TTY and SDDM ask for the password.
  security.pam.services.login.fprintAuth = false;
}
