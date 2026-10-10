# The image awww shows on each output, scaled down, to where the login screen
# can read it: <directory>/<output>.jpg.
#   greeter-wallpaper <directory>

dir=$1

# awww may still be starting.
for _ in 1 2 3 4 5; do
    shown=$(awww query 2>/dev/null | sed -n 's/^:\{0,1\} *\([^ :]*\): .*currently displaying: image: \(.*\)$/\1\t\2/p')
    [ -n "$shown" ] && break
    sleep 1
done

printf '%s\n' "$shown" | while IFS=$'\t' read -r output image; do
    [ -f "$image" ] || continue
    # [0]: the first frame of an animated one.
    magick "${image}[0]" -resize '2560x2560>' -quality 90 "$dir/$output.tmp.jpg" &&
        mv -f "$dir/$output.tmp.jpg" "$dir/$output.jpg"
done
