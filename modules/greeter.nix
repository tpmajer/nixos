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

  wallpaperFirst = script "wallpaper-first" {
    inputs = [
      pkgs.awww
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.swaybg
    ];
  };

  layersWait = script "layers-wait" {
    inputs = [
      niri
      pkgs.coreutils
      pkgs.gnugrep
    ];
  };

  # Whether a password was given, for PAM: it is read from stdin.
  typed = pkgs.writeShellScript "greetd-typed" ''
    IFS= read -r -d "" password
    [ -n "$password" ]
  '';

  # The palette the session left (greeter/shell.qml), as rrggbb, Catppuccin's
  # with none. Its crust is the backdrop between the login screen and the
  # session, which its niri has for one too; the rest colour the VT's text.
  backdrop = ''
    crust=11111b subtext1=bac2de text=cdd6f4 green=a6e3a1 peach=fab387 red=f38ba8
    while IFS= read -r line; do
      [[ $line =~ ^(crust|subtext1|text|green|peach|red)=#([0-9a-fA-F]{6})$ ]] &&
        declare "''${BASH_REMATCH[1]}=''${BASH_REMATCH[2]}"
    done 2> /dev/null < ${wallpapers}/palette
    backdrop=$crust
  '';

  # Whatever greetd starts, with its output in the journal, and the VT in the
  # palette's colours with no cursor: it shows between the two, and systemd's
  # status as the machine goes down (notes/greeter.md). No PATH of its own:
  # the session would keep it.
  run = pkgs.writeShellScript "greeter-session" ''
    ${backdrop}
    # Plain text, bold, OK, failed, warnings: each colour and its bright one.
    printf '\033]P%s' "0$backdrop" "7$subtext1" "F$text" "2$green" "A$green" \
      "1$red" "9$red" "3$peach" "B$peach"
    printf '\033[2J\033[?25l'
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

      // The session's backdrop colour under the login screen as it goes:
      // a palette's from the file greeter-niri writes.
      layout {
          background-color "#11111b"
      }
      include optional=true "${cache}/backdrop.kdl"

      // No X11 for the login screen: it would take display :0 first.
      xwayland-satellite {
          off
      }

      binds {
      }

      spawn-at-startup "${greeter}"
    '';
  };

  # The greeter's niri, with the backdrop in a file its config includes.
  greeterNiri = pkgs.writeShellScript "greeter-niri" ''
    ${backdrop}
    printf 'layout {\n    background-color "#%s"\n}\n' "$backdrop" > ${cache}/backdrop.kdl
    exec ${niri}/bin/niri --config ${niriConfig}
  '';
in

{
  services.greetd = {
    enable = true;
    # greetd with the changes of ~/Claude/greetd (notes/greeter.md).
    package = pkgs.greetd.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ../patches/greetd/0001-fix-end-the-session-worker-when-a-session-is-cancell.patch
        ../patches/greetd/0002-fix-let-a-client-cancel-while-a-question-is-awaited.patch
        ../patches/greetd/0003-fix-do-not-fail-a-cancel-whose-worker-is-gone.patch
        ../patches/greetd/0004-fix-make-the-session-s-socket-non-blocking.patch
        ../patches/greetd/0005-feat-hand-over-to-a-session-on-a-VT-of-its-own.patch
      ];
    });
    # The session on a VT of its own, with the greeter kept until it is up
    # (notes/greeter.md).
    settings.terminal.handover = true;
    settings.default_session.command = "${pkgs.coreutils}/bin/env XDG_CACHE_HOME=${cache} ${run} greeter ${greeterNiri}";
  };

  # The login screen alone has the reader; a TTY keeps to the password. PAM
  # asks for the password first: one given goes to login's rules, none is a
  # round of the reader and nothing else. 10 s is pam_fprintd's least
  # (notes/greeter.md).
  security.pam.services.login.fprintAuth = false;
  security.pam.services.greetd.rules.auth = {
    typed = {
      order = 10000;
      control = "[success=1 default=ignore]";
      modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
      args = [
        "expose_authtok"
        "quiet"
        "quiet_log"
        "${typed}"
      ];
    };
    fprintd = {
      order = 10050;
      control = "[success=done default=die]";
      modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
      settings.timeout = 10;
    };
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
  # The copy on the screen at once as the session starts, until awww has its
  # own image up (notes/greeter.md).
  systemd.user.services.wallpaper-first = {
    description = "The wallpaper's first frame";
    bindsTo = [ "niri.service" ];
    after = [ "niri.service" ];
    wantedBy = [ "niri.service" ];
    serviceConfig.ExecStart = "${lib.getExe wallpaperFirst} ${wallpapers}";
  };
  # A curtain over the session until the wallpaper is there
  # (curtain/shell.qml). Started once it is on the screen: the wallpapers
  # wait for that.
  systemd.user.services.session-curtain = {
    description = "A curtain over the session's first moments";
    bindsTo = [ "niri.service" ];
    after = [ "niri.service" ];
    wantedBy = [ "niri.service" ];
    before = [
      "awww-daemon.service"
      "wallpaper-first.service"
    ];
    environment.CURTAIN_WAIT = lib.getExe layersWait;
    environment.CURTAIN_PALETTE = "${wallpapers}/palette";
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.quickshell} --path ${../curtain}";
      ExecStartPost = "${lib.getExe layersWait} 200 'Namespace: \"session-curtain\"'";
    };
  };
  systemd.user.paths.greeter-wallpaper = {
    wantedBy = [ "niri.service" ];
    pathConfig.PathChanged = "%h/.cache/awww/${pkgs.awww.version}";
  };
}
