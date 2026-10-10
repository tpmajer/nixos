# The login screen: greetd, with Quickshell drawing it in a niri of its own
# (greeter/shell.qml). Background in notes/desktop.md.

{
  config,
  pkgs,
  lib,
  user,
  ...
}:

let
  niri = config.programs.niri.package;

  # The greeter's whole session: Quickshell, and niri gone with it.
  greeter = pkgs.writeShellScript "greeter" ''
    export PATH=${
      lib.makeBinPath [
        niri
        pkgs.systemd
      ]
    }:$PATH
    # The greeter's home is /var/empty: Quickshell's cache goes with the session.
    export XDG_CACHE_HOME=$XDG_RUNTIME_DIR/cache
    export GREETER_USER=${user}
    export GREETER_SESSION=${niri}/bin/niri-session
    ${lib.getExe pkgs.quickshell} --path ${../greeter}
    niri msg action quit --skip-confirmation
  '';

  # No binds: nothing to start from the login screen. The VT keys are niri's own.
  niriConfig = pkgs.writeText "greeter-niri.kdl" ''
    input {
        keyboard {
            xkb {
                layout "pl"
            }

            numlock
        }

        touchpad {
            tap
            natural-scroll
        }
    }

    // As in the session (~/.dotfiles, niri's config.kdl).
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

    binds {
    }

    spawn-at-startup "${greeter}"
  '';
in

{
  services.greetd = {
    enable = true;
    settings.default_session.command = "${niri}/bin/niri --config ${niriConfig}";
  };

  # The password, not the reader: only a password unlocks the keyring. GDM's
  # module did this by itself.
  security.pam.services.login.fprintAuth = false;
}
