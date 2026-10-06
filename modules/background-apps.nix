# Thunderbird and Signal running without a window, for their notifications,
# and the commands that bring their windows up. See notes/background-apps.md.

{ pkgs, lib, ... }:

let
  background = {
    after = [
      "niri.service"
      "quickshell.service"
    ];
    wantedBy = [ "niri.service" ];
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
          (pkgs.writeShellScript "thunderbird-wait-for-mail-server" ''
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
            exit 0
          '')
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
        ExecCondition = pkgs.writeShellScript "signal-not-running" ''
          lock=$(${pkgs.coreutils}/bin/readlink "$HOME/.config/Signal/SingletonLock") || exit 0
          ! ${pkgs.gnugrep}/bin/grep -qs signal-desktop "/proc/''${lock##*-}/cmdline"
        '';
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
