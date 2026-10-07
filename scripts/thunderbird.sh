# Thunderbird's window in place of the instance without one. With a window up
# already this is only a message to it.
unit=thunderbird-headless.service
if ! systemctl --user is-active --quiet "$unit" \
  && thunderbird-running; then
  exec "$THUNDERBIRD_BIN" "$@"
fi
systemctl --user stop "$unit"

# Open on the Inbox: point the first tab of the saved session at it.
for session in "$HOME"/.thunderbird/*/session.json; do
  [ -f "$session" ] || continue
  jq -c '
    (.windows[]?.tabs | select(.tabs | any(.state.firstTab == true))) |= (
      .selectedIndex = (.tabs | map(.state.firstTab == true) | index(true))
      | (.tabs[] | select(.state.firstTab == true) | .state.folderURI)
        |= sub("^(?<server>imap://[^/]+)/.*$"; "\(.server)/INBOX")
    )' "$session" > "$session.inbox" \
    && mv "$session.inbox" "$session"
  rm -f "$session.inbox" # what is left of a failed attempt
done

"$THUNDERBIRD_BIN" "$@"
status=$?
# Not waited for: offline, the unit takes up to 60 s to start.
systemctl --user start --no-block "$unit"
exit $status
