---
dusk: v1alpha1
namespace: stout
kind: repository
name: dotfiles
title: Dotfiles
attributes:
  manager: yadm
  visibility: public
---

Personal dotfiles, managed with [yadm](https://yadm.io) rather than a symlink farm.
The repository's work tree is the home directory itself, so a tracked path is the real path and there is no linking step in between.

Machine differences are handled by yadm alternates rather than by branches or shell conditionals.
A file tracked as `<name>##a.<arch>` or `<name>##h.<hostname>` is chosen on a machine that matches, `<name>##default` is the fallback, and `yadm alt` links the winner into place.
A `##template.*` variant goes further and is rendered from the live system, which is how a machine-facts file arrives already filled in with the running host's name, architecture and user.
The consequence is that a plain `git clone` of this repository is not usable on its own: you get filenames with `##` in them and nothing rendered.

The shell side is `.zshrc` plus `functions.sh`, which holds the small helper functions and the wrappers, including a `git()` function that shadows git with a personal wrapper CLI.
`Brewfile` and `.tool-versions` carry packages and runtime versions, `.config/` carries editor, terminal and prompt configuration, and `.claude/` and `.agents/` carry agent configuration and vendored agent skills.
`.bootstrap/main.sh` is what `yadm bootstrap` runs on a new machine: brew bundle, runtimes, fonts, and macOS defaults.

## Gotchas

**No secrets are stored here, because this repository is public.**
`secrets.sh` is a fetcher rather than a store: it shells out to a password manager at shell startup and exports the results, so what is committed is the list of secret names and never a value.
Keep it that way when adding one.

**`.claude/CLAUDE.md` is a symlink into a different repository.**
On a machine that has not cloned that one it dangles, and agent context comes up empty without saying why.

**Anything at the repository root lands directly in the home directory**, this file included.
A root `dusk.md` is the only way a repository joins the catalog, so `~/dusk.md` turning up after a pull is expected rather than stray.
