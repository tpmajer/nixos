# CLAUDE.md

# Tools

Nix is installed on this system. When you need a tool that is not
available, use `nix run nixpkgs#<package>` or `nix shell nixpkgs#<package>`
to run it ad-hoc. Do not install packages permanently.

Search for packages with `nix search nixpkgs <term>`.

# Commits

Conventional Commits, title in the imperative ("add…", "remove…",
"stop…"), not a description of the result. Title including
`type(scope): ` at most 72 characters; body wrapped at 72 columns.

The title says what changes — no "tweaks", "review fixes", "cleanups".

Scopes, one per area:

- the module name: `core`, `hardware`, `power`, `desktop`, `session`,
  `background-apps`, `network`, `wireguard`, `packages`, …
- `scripts` and `notes` for those directories, when a change is theirs alone
- `docs:` without a scope for the README
- no comma-joined scopes and no one-off ones

Do not copy the style from `git log`: part of the history predates this
convention.

One commit is one logical change. A fix, a style change and a feature
go into separate commits even when they touch the same file — split by
hunk. Do not rewrite pushed history for style alone.

Commit and push only when asked.

## flake.lock

Never part of these commits, even when the lock changes because of
the change being committed. Leave it modified; the fish wrappers
commit it on their own as `chore: update flake.lock`.

## private.nix

`A  private.nix` in `git status` is the intended resting state — do
not unstage it. The flake only sees files git knows about, so the
post-commit hook force-adds it and the pre-commit hook strips it
before the commit object exists. It holds secrets: never commit it,
never delete it.

Commit with a pathspec (`git commit -- <files>`), never `git add -A`
or `git add .`. The hooks need `core.hooksPath = .githooks`.
