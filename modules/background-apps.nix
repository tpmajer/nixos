# Thunderbird and Signal running without a window, for their notifications,
# and the commands that bring their windows up. See notes/background-apps.md.

{ pkgs, lib, ... }:

let
  script = import ./script.nix { inherit pkgs; };

  background = {
    after = [
      "niri.service"
      "quickshell.service"
    ];
    wantedBy = [ "niri.service" ];
  };

  signalRunning = script "signal-running" {
    inputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
  };

  waitForMailServer = script "thunderbird-wait-for-mail-server" {
    inputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.systemd
    ];
  };
in

{
  systemd.user.services = {
    # One instance per profile: the thunderbird command below stops this for
    # the window and starts it again after.
    thunderbird-headless = background // {
      description = "Thunderbird without a window, for new mail notifications";
      serviceConfig = {
        Type = "simple";
        # The wait always passes; the window is then looked for right before the start.
        ExecCondition = [
          (lib.getExe waitForMailServer)
          (pkgs.writeShellScript "thunderbird-no-window-up" ''
            ! ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -f 'bin/\.thunderbird-wrapped_' > /dev/null
          '')
        ];
        ExecStart = "${pkgs.thunderbird}/bin/thunderbird --headless";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    # Started in the tray it shows no window; running Signal again brings it up.
    signal-background = background // {
      description = "Signal without a window, for message notifications";
      serviceConfig = {
        Type = "simple";
        # Not next to a Signal started some other way.
        ExecCondition = pkgs.writeShellScript "signal-not-running" "! ${lib.getExe signalRunning}";
        ExecStart = "${pkgs.signal-desktop}/bin/signal-desktop --start-in-tray";
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStopSec = "10s"; # Signal is slow to go on SIGTERM
      };
      path = lib.mkForce [ ]; # the session's PATH: Signal opens links with it
    };
  };

  # Over the packages' own commands, which launcher entries and links run.
  environment.systemPackages = [
    (lib.hiPrio (
      script "thunderbird" {
        inputs = [ pkgs.jq ];
        env.THUNDERBIRD_BIN = "${pkgs.thunderbird}/bin/thunderbird";
      }
    ))
    (lib.hiPrio (
      script "signal-desktop" {
        inputs = [ signalRunning ];
        env.SIGNAL_BIN = "${pkgs.signal-desktop}/bin/signal-desktop";
      }
    ))
  ];
}
