# /etc/nixos/user-services.nix

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  # Keep every other user service at the 8 MiB default; only oo7-daemon needs the raised
  # ceiling that user@.service now provides (see the mlock comment in system.nix).
  systemd.user.settings.Manager.DefaultLimitMEMLOCK = "8M";

  systemd.user.services = {

    # mlockall needs the whole address space (VmSize ~1.66 GiB, mostly PROT_NONE malloc arenas)
    # to fit under RLIMIT_MEMLOCK, not just the ~10 MiB it pins. See the comment in system.nix.
    oo7-daemon.serviceConfig.LimitMEMLOCK = "2G";

    # path = [ ] keeps the session PATH (from niri) instead of a Nix-built one, so
    # the bar's scripts and click commands (nmcli, wpctl, ghostty, niri msg, ...)
    # resolve as in the shell.
    quickshell = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "Quickshell bar";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.quickshell}/bin/quickshell";
        # always, not on-failure: it is the session lock too. If it goes while
        # the session is locked, even cleanly (qs kill, SIGTERM), niri keeps the
        # session locked with nothing to unlock it; the next process locks
        # again by its marker. systemctl stop still stops it.
        Restart = "always";
        RestartSec = "2s";
      };
      path = lib.mkForce [ ];
    };

    hypridle = {
      path = lib.mkForce [ ];
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
    };

    awww-daemon = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      path = [ pkgs.awww ];
    };

    gammastep = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "Gammastep Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # The packaged unit ships in $out/share/systemd/user, but NixOS's
    # systemd.packages only scans etc/systemd/user and lib/systemd/user
    # (nixos/lib/systemd-lib.nix:441), so adding the package there would be a
    # no-op — define the unit here instead. Bound to niri.service like the rest
    # of the session services, not to the upstream graphical-session.target.
    # The agent takes ~/.config/openlogi/agent.lock and exits 0 if another
    # instance already holds it, so Restart=on-failure won't fight the GUI.
    openlogi-agent = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "OpenLogi background agent (Logitech HID++ device control)";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.openlogi}/bin/openlogi-agent";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    "app-com.mitchell.ghostty" = {
      after = [
        "graphical-session.target"
        "niri.service"
      ];
      wantedBy = [ "niri.service" ];
      description = "Ghostty Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.ghostty}/bin/ghostty --gtk-single-instance=true --initial-window=false";
        Restart = "on-failure";
        RestartSec = "2s";
      };
      path = lib.mkForce [ ];
    };

    # Thunderbird without a window, so that new mail is notified of while the
    # client is closed. The account is under Google's Advanced Protection: no
    # app passwords, and only a few clients are let at the mail at all, so a
    # small IMAP watcher is not an option, while Thunderbird is signed in
    # already. Measured on 2026-10-04: about 330 MiB, and a notification with
    # "Mark as Read" and "Delete".
    # Thunderbird runs one instance per profile, so the thunderbird wrapper
    # below stops this before the window comes up and starts it again once
    # the window is closed. The condition is for a start with the window up.
    thunderbird-headless = {
      after = [
        "niri.service"
        "quickshell.service"
      ];
      wantedBy = [ "niri.service" ];
      description = "Thunderbird without a window, for new mail notifications";
      serviceConfig = {
        Type = "simple";
        ExecCondition = pkgs.writeShellScript "thunderbird-no-window-up" ''
          ! ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -f 'bin/\.thunderbird-wrapped_' > /dev/null
        '';
        # Logging in can come before the Wi-Fi is up, and the first mail
        # check then fails with a notification; the next is 10 minutes
        # later. Wait for the mail server to answer, but start without it
        # after 60 s. The same goes for the restart hypridle does after a
        # suspend.
        # Not nm-online: it is done when NetworkManager has any connection,
        # which is before DNS works (2 s later on 2026-10-06) and before
        # wg-auto has brought wg0 up on an untrusted network. Hence the
        # server itself, twice 2 s apart, and not while wg0 is coming up.
        ExecStartPre = "-${pkgs.writeShellScript "thunderbird-wait-for-mail-server" ''
          answers=0
          while [ "$SECONDS" -lt 60 ]; do
            if [ "$(${pkgs.systemd}/bin/systemctl is-active wg-quick-wg0.service)" != activating ] \
              && ${pkgs.coreutils}/bin/timeout 3 ${pkgs.bash}/bin/bash -c ': < /dev/tcp/imap.gmail.com/993' 2> /dev/null; then
              answers=$((answers + 1))
              [ "$answers" -ge 2 ] && exit 0
            else
              answers=0
            fi
            ${pkgs.coreutils}/bin/sleep 2
          done
          echo "imap.gmail.com did not answer within 60 s: starting without it" >&2
          exit 1
        ''}";
        ExecStart = "${pkgs.thunderbird}/bin/thunderbird --headless";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    # Signal without a window, so that messages are notified of while it is
    # closed. Unlike Thunderbird it needs no swapping for the window: started
    # in the tray it shows none, running it again brings up the window of
    # the instance there is, and closing that leaves it running. Checked on
    # 8.28.0 with no tray in the bar, 2026-10-05; about 500 MiB.
    # Not next to a Signal started some other way: as its second instance
    # this would only bring that one's window up and end. Signal is slow to
    # go on SIGTERM, hence the short stop timeout.
    signal-background = {
      after = [
        "niri.service"
        "quickshell.service"
      ];
      wantedBy = [ "niri.service" ];
      description = "Signal without a window, for message notifications";
      serviceConfig = {
        Type = "simple";
        ExecCondition = pkgs.writeShellScript "signal-not-running" ''
          lock=$(${pkgs.coreutils}/bin/readlink "$HOME/.config/Signal/SingletonLock") || exit 0
          ! ${pkgs.gnugrep}/bin/grep -qs signal-desktop "/proc/''${lock##*-}/cmdline"
        '';
        ExecStart = "${pkgs.signal-desktop}/bin/signal-desktop --start-in-tray";
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStopSec = "10s";
      };
      # The session's PATH, as for quickshell: Signal opens links with it.
      path = lib.mkForce [ ];
    };

  };

  # Over the package's own bin/thunderbird, which the launcher entry, mailto
  # links and the shell all run: the window in place of the instance without
  # one. With a window up already this is only a message to it.
  environment.systemPackages = [
    (lib.hiPrio (
      pkgs.writeShellScriptBin "thunderbird" ''
        unit=thunderbird-headless.service
        if ! systemctl --user is-active --quiet "$unit" \
          && pgrep -u "$(id -u)" -f 'bin/\.thunderbird-wrapped_' > /dev/null; then
          exec ${pkgs.thunderbird}/bin/thunderbird "$@"
        fi
        systemctl --user stop "$unit"
        # Thunderbird has no setting for the folder to start in: the first
        # tab comes back from session.json with the folder it was closed on.
        # Point that tab at the Inbox of the same account and select it; the
        # other tabs stay as they were.
        for session in "$HOME"/.thunderbird/*/session.json; do
          [ -f "$session" ] || continue
          ${pkgs.jq}/bin/jq -c '
            (.windows[]?.tabs | select(.tabs | any(.state.firstTab == true))) |= (
              .selectedIndex = (.tabs | map(.state.firstTab == true) | index(true))
              | (.tabs[] | select(.state.firstTab == true) | .state.folderURI)
                |= sub("^(?<server>imap://[^/]+)/.*$"; "\(.server)/INBOX")
            )' "$session" > "$session.inbox" \
            && mv "$session.inbox" "$session" \
            || rm -f "$session.inbox"
        done
        ${pkgs.thunderbird}/bin/thunderbird "$@"
        status=$?
        # Not waited for: offline, the unit takes up to 60 s to start.
        systemctl --user start --no-block "$unit"
        exit $status
      ''
    ))
    # Over the package's own bin/signal-desktop, which the launcher entry
    # runs. With no Signal running the unit above is started first, so that
    # the one whose window comes up is the one that stays when the window is
    # closed; then, as with one running, this is only a message to it.
    (lib.hiPrio (
      pkgs.writeShellScriptBin "signal-desktop" ''
        running() {
          lock=$(readlink "$HOME/.config/Signal/SingletonLock" 2> /dev/null) \
            && grep -qs signal-desktop "/proc/''${lock##*-}/cmdline"
        }
        if ! running; then
          systemctl --user start signal-background.service
          # A second instance that comes before the lock is taken would be
          # the first, and stay.
          for _ in $(seq 50); do
            running && break
            sleep 0.1
          done
        fi
        exec ${pkgs.signal-desktop}/bin/signal-desktop "$@"
      ''
    ))
  ];

}
