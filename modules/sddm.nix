# A trial: SDDM in place of greetd's login screen, for its hand-over to the
# session. Drawn as the lock is (sddm/Main.qml), and the password alone.
# Background in notes/sddm.md.

{
  pkgs,
  lib,
  config,
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

  # The battery, for the theme: it can read settings, and no sysfs.
  battery = "${config.users.users.sddm.home}/battery.ini";

  theme = pkgs.runCommand "sddm-theme-lock" { } ''
    dir=$out/share/sddm/themes/lock
    mkdir -p $dir
    cp ${../sddm}/Main.qml ${../sddm}/metadata.desktop $dir/
    cp ${
      (pkgs.formats.ini { }).generate "theme.conf" {
        General = {
          inherit user wallpapers battery;
          needsFullUserModel = false;
        };
      }
    } $dir/theme.conf
  '';

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

      // The outputs off after a minute, the machine asleep after ten, as
      // greetd's screen had it.
      spawn-at-startup "${pkgs.swayidle}/bin/swayidle" "-w" "timeout" "60" "${niri}/bin/niri msg action power-off-monitors" "timeout" "600" "${pkgs.systemd}/bin/systemctl suspend"
    '';
  };

  # SDDM ends its Wayland compositor with the greeter, at a login, and the VT
  # goes back to text before the session is up. It waits 5 s for it to go:
  # held for 3, the compositor keeps the VT until the session has the screen.
  # Meanwhile the battery is written down for the theme, when it changes.
  compositor = pkgs.writeShellScript "sddm-compositor" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
      ]
    }:$PATH
    supply=/sys/class/power_supply/BAT1
    while [ -r $supply/capacity ]; do
      capacity=$(cat $supply/capacity)
      status=$(cat $supply/status)
      if [ "$capacity $status" != "$was" ]; then
        printf '[battery]\ncapacity=%s\nstatus=%s\n' "$capacity" "$status" > ${battery}.new &&
          mv -f ${battery}.new ${battery}
        was="$capacity $status"
      fi
      sleep 5
    done &
    gauge=$!
    ${niri}/bin/niri --config ${niriConfig} &
    child=$!
    trap 'sleep 3; kill "$child" "$gauge"' TERM
    wait "$child"
    wait "$child"
    kill "$gauge" 2> /dev/null
  '';
in

{
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositorCommand = "${compositor}";
      theme = "lock";
      # niri at every login: the theme chooses it, and nothing is kept.
      settings.Users = {
        RememberLastSession = false;
        RememberLastUser = false;
      };
    };
    defaultSession = "niri";
  };
  environment.systemPackages = [ theme ];

  # As greeter.nix has it: a TTY and SDDM ask for the password.
  security.pam.services.login.fprintAuth = false;

  # SDDM's user cannot read the user's home: a copy of what awww shows, made
  # as the session starts and whenever awww records another image.
  systemd.tmpfiles.rules = [ "d ${wallpapers} 0755 ${user} users -" ];
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
