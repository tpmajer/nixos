# Firefox's files and those of the profile last used, read into the page
# cache, so that the first start is not slowed by the disk.
#   firefox-preload <firefox's lib directory>

lib=$1

# The profile last used: its prefs.js is written at every exit.
profile=
for dir in "$HOME"/.mozilla/firefox/*/; do
    [ -f "$dir/prefs.js" ] || continue
    if [ -z "$profile" ] || [ "$dir/prefs.js" -nt "$profile/prefs.js" ]; then
        profile=${dir%/}
    fi
done

{
    find -L "$lib" -type f -exec cat {} +
    if [ -n "$profile" ]; then
        startup_cache=$HOME/.cache/mozilla/firefox/$(basename "$profile")/startupCache
        # Not storage/, the sites' own data: hundreds of MiB a start does not read.
        find "$profile" "$profile/extensions" "$startup_cache" -maxdepth 1 -type f \
            -exec cat {} +
    fi
} > /dev/null 2>&1
exit 0
