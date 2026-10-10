# A trial: SDDM in place of greetd's login screen, to see its hand-over to the
# session (notes/greeter.md). The default theme, and the password alone.

{ pkgs, config, ... }:

let
  niri = config.programs.niri.package;

  # The greeter's compositor: niri as greeter.nix has it, so the mode, the
  # scale and the keyboard are the session's. Checked at build, as there.
  niriConfig = pkgs.writeTextFile {
    name = "sddm-niri.kdl";
    checkPhase = "${niri}/bin/niri validate --config $target";
    text = ''
      input {
          disable-power-key-handling

          keyboard {
              xkb {
                  layout "${config.services.xserver.xkb.layout}"
              }

              numlock
          }

          touchpad {
              tap
              natural-scroll
          }
      }

      output "eDP-1" {
          scale 1.6
      }

      cursor {
          xcursor-theme "Simp1e-Catppuccin-Mocha"
          xcursor-size 24
      }

      hotkey-overlay {
          skip-at-startup
      }

      layout {
          background-color "#000000"
      }

      animations {
          off
      }

      xwayland-satellite {
          off
      }

      // SDDM's greeter is a plain window that asks to be fullscreen.
      window-rule {
          open-fullscreen true
      }

      binds {
      }
    '';
  };

  # SDDM ends its Wayland compositor with the greeter, at a login, and the VT
  # goes back to text before the session is up. It waits 5 s for it to go:
  # held for 3, the compositor keeps the VT until the session has the screen.
  compositor = pkgs.writeShellScript "sddm-compositor" ''
    ${niri}/bin/niri --config ${niriConfig} &
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
