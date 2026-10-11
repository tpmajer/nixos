# greeter-wallpaper's copies, faded in from black on their outputs as the
# session starts, until awww shows its own: it decodes and scales the image
# at every start. Drawn by a second awww-daemon, a layer above the first's.
#   wallpaper-first <directory>

dir=$1

copies=()
for copy in "$dir"/*.jpg; do
    case $copy in *.tmp.jpg) continue ;; esac
    [ -f "$copy" ] && copies+=("$copy")
done
[ ${#copies[@]} -gt 0 ] || exit 0

# A cache of its own: the copies are not the session's wallpapers to keep.
cache=$XDG_RUNTIME_DIR/wallpaper-first
mkdir -p "$cache"
first() {
    XDG_CACHE_HOME=$cache "$@" --namespace first
}

# Not through first(): $! would be a shell's, and the daemon would stay.
XDG_CACHE_HOME=$cache awww-daemon --no-cache --layer bottom --namespace first &
daemon=$!

# The daemon may still be starting.
for _ in $(seq 200); do
    first awww query > /dev/null 2>&1 && break
    sleep 0.005
done
for copy in "${copies[@]}"; do
    first awww img "$copy" --outputs "$(basename "$copy" .jpg)" \
        --transition-type fade --transition-duration 0.25 --transition-fps 120
done

# For 5 s at most, then a moment for awww's image to be drawn.
for _ in $(seq 50); do
    awww query 2>/dev/null | grep -q 'currently displaying: image: ' && break
    sleep 0.1
done
sleep 0.5
kill "$daemon"
