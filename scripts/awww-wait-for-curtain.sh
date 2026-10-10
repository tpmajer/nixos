# Holds the wallpaper daemon back until Quickshell's curtain is drawn in this
# session (~/.dotfiles, Arrival.qml), 3 s at most: the wallpaper comes under it.

for _ in $(seq 30); do
    [ "$(cat "$XDG_RUNTIME_DIR/quickshell-arrived" 2>/dev/null)" = "$NIRI_SOCKET" ] && exit 0
    sleep 0.1
done
exit 0
