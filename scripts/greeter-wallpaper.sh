# The image awww shows on each output, cut to the output's size, to where the
# login screen can read it: <directory>/<output>.jpg.
#   greeter-wallpaper <directory>

dir=$1

# Output, its width, height and scale, and the image, tab-separated, a line
# per output that shows one.
shown() {
    awww query 2>/dev/null | sed -n 's/^:\{0,1\} *\([^ :]*\): \([0-9]*\)x\([0-9]*\), scale: \([0-9.]*\), currently displaying: image: \(.*\)$/\1\t\2\t\3\t\4\t\5/p'
}

# awww may still be starting.
for _ in 1 2 3 4 5; do
    now=$(shown)
    [ -n "$now" ] && break
    sleep 1
done

# Again if awww shows something else by the end: a change while this runs
# does not start it anew.
while [ -n "$now" ]; do
    printf '%s\n' "$now" | while IFS=$'\t' read -r output width height scale image; do
        [ -f "$image" ] || continue
        # In pixels, as awww fills the output: wallpaper-first draws the copy
        # as it is.
        size="%[fx:round($width*$scale)]x%[fx:round($height*$scale)]"
        # Not again for the image the copy is of: its path, time and size,
        # hashed, as the directory is everyone's to read.
        stamp=$(printf '%s %s %s' "$image" "$(stat -c %Y "$image")" "$width $height $scale" | sha256sum)
        [ -f "$dir/$output.jpg" ] && [ "$(cat "$dir/$output.stamp" 2>/dev/null)" = "$stamp" ] && continue
        # [0]: the first frame of an animated one.
        magick "${image}[0]" -filter Lanczos -resize "$size^" -gravity center -extent "$size" -quality 92 "$dir/$output.tmp.jpg" &&
            mv -f "$dir/$output.tmp.jpg" "$dir/$output.jpg" &&
            printf '%s\n' "$stamp" > "$dir/$output.stamp"
    done
    before=$now
    now=$(shown)
    [ "$now" = "$before" ] && break
done
