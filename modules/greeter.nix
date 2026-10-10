# The login screen: greetd, with Quickshell drawing it in a niri of its own
# (greeter/shell.qml). Background in notes/greeter.md.

{
  config,
  pkgs,
  lib,
  user,
  ...
}:

let
  script = import ./script.nix { inherit pkgs; };

  niri = config.programs.niri.package;

  # The session's wallpapers, kept for the login screen by greeter-wallpaper.
  wallpapers = "/var/cache/greeter";
  greeterWallpaper = script "greeter-wallpaper" {
    inputs = [
      pkgs.awww
      pkgs.coreutils
      pkgs.gnused
      pkgs.imagemagick
    ];
  };

  # Whatever greetd starts, with its output in the journal and no cursor on
  # the VT (notes/greeter.md). No PATH of its own: the session would keep it.
  run = pkgs.writeShellScript "greeter-session" ''
    printf '\033[?25l'
    identifier=$1
    shift
    exec ${pkgs.systemd}/bin/systemd-cat --identifier="$identifier" -- "$@"
  '';

  # The greeter's home is /var/empty: a cache of its own, for niri's and
  # Quickshell's shaders to outlast a start.
  cache = "/var/cache/greeter-shell";

  # The greeter's whole session: Quickshell, and niri gone with it.
  greeter = pkgs.writeShellScript "greeter" ''
    export PATH=${
      lib.makeBinPath [
        niri
        pkgs.bash
        pkgs.coreutils
        pkgs.systemd
      ]
    }:$PATH
    export GREETER_USER=${user}
    export GREETER_SESSIONS=${config.services.displayManager.sessionData.desktops}/share/wayland-sessions
    export GREETER_WALLPAPERS=${wallpapers}
    export GREETER_RUN=${run}
    # niri gives what it spawns no output: Quickshell's goes to the journal here.
    ${pkgs.systemd}/bin/systemd-cat --identifier=greeter ${lib.getExe pkgs.quickshell} --path ${../greeter}
    niri msg action quit --skip-confirmation
  '';

  # No binds: nothing to start from the login screen. Checked at build: niri
  # starts with its defaults, binds and all, on a config it cannot read.
  niriConfig = pkgs.writeTextFile {
    name = "greeter-niri.kdl";
    checkPhase = "${niri}/bin/niri validate --config $target";
    text = ''
      input {
          // niri would suspend at the power key, which is the reader too;
          // logind ignores it (power.nix).
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

      // Black under the login screen as it goes, as the VT after it is.
      layout {
          background-color "#000000"
      }

      // No X11 for the login screen: it would take display :0 first.
      xwayland-satellite {
          off
      }

      binds {
      }

      spawn-at-startup "${greeter}"
    '';
  };
in

{
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.coreutils}/bin/env XDG_CACHE_HOME=${cache} ${run} greeter ${niri}/bin/niri --config ${niriConfig}";
  };

  # The reader for the login screen alone, ahead of login's rules; a TTY keeps
  # to the password. 10 s is pam_fprintd's least (notes/greeter.md).
  security.pam.services.login.fprintAuth = false;
  security.pam.services.greetd.rules.auth.fprintd = {
    order = 10000;
    control = "sufficient";
    modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
    settings.timeout = 10;
  };

  # The greeter cannot read the user's home: a copy of what awww shows, made
  # as the session starts and whenever awww records another image.
  systemd.tmpfiles.rules = [
    "d ${wallpapers} 0755 ${user} users -"
    "d ${cache} 0700 greeter greeter -"
  ];
  systemd.user.services.greeter-wallpaper = {
    description = "The wallpaper, for the login screen";
    after = [ "awww-daemon.service" ];
    wantedBy = [ "niri.service" ];
    # Wallpapers shuffled in a row: the limit would stop the path unit too.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe greeterWallpaper} ${wallpapers}";
    };
  };
  systemd.user.paths.greeter-wallpaper = {
    wantedBy = [ "niri.service" ];
    pathConfig.PathChanged = "%h/.cache/awww/${pkgs.awww.version}";
  };
}
