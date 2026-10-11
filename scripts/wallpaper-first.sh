# greeter-wallpaper's copies, drawn on their outputs as the session starts,
# until awww shows its own: it decodes and scales the image at every start.
#   wallpaper-first <directory>

dir=$1

painter=()
for copy in "$dir"/*.jpg; do
    case $copy in *.tmp.jpg) continue ;; esac
    [ -f "$copy" ] || continue
    painter+=(-o "$(basename "$copy" .jpg)" -m fill -i "$copy")
done
[ ${#painter[@]} -gt 0 ] || exit 0

swaybg "${painter[@]}" &

# For 5 s at most, then a moment for awww's image to be drawn.
for _ in $(seq 50); do
    awww query 2>/dev/null | grep -q 'currently displaying: image: ' && break
    sleep 0.1
done
sleep 0.5
kill $!
