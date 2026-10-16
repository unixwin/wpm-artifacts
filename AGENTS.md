# wpm-artifacts agent guide

This repository builds and mirrors the artifacts that `wpm` cannot take from an
upstream release: unstable hosting, blocked direct links, or no official
Windows build. It publishes them to its own GitHub Releases; `unixwin/wpm-source`
indexes them. Rules below are the ones that broke a shipped package.

## What a release looks like

- One tag per package: `<pkg>-<version>` (`gawk-5.4.1`), and for a repackage
  `<pkg>-<version>-unixwin<N>` (`gawk-5.4.1-unixwin1`).
- Assets: `<pkg>-<version>-win-<arch>.zip`, plus `sha256.txt` and `size.txt`
  (the byte count the index needs).
- Everything is produced by `.github/workflows/` (`mirror-gawk.yml`,
  `build-ncat.yml`, `build-openssl.yml`, `build-rust.yml`); nothing is uploaded
  by hand. The workflow logs the digests; the release carries them.
- After a release, the index entry is a **pull request to `unixwin/wpm-source`**
  (see that repo's `AGENTS.md`), using the sha256/size measured from the
  published asset — not from the build log alone.

## Our rebuild must carry a packaging revision

`wpm` **orders** versions, it does not compare them for equality: a
dotted-numeric core plus an optional Debian-style revision, so
`5.4.1-unixwin2` > `5.4.1-unixwin1` > `5.4.1`. The tag and the `version` field
of the index entry must carry `-unixwin<N>`, and **every** repackage bumps `N`.
Without it the artifact is compared as the same version as what users already
have and is never offered as an update (this is how the gawk payload prune
became invisible until the revision was added).

## Prune with evidence, then move the index with it

- Walk the **import tables**, do not guess: `repackage/check-dll-deps.sh` reads
  every `exe`/`dll` with `objdump -p` and fails if a non-system DLL is missing.
  Use the same information to decide what to drop.
- The gawk prunes are the model: the unused extension-module tree (7.78 MB →
  4,366,656 B) and two DLLs nothing imports. Match files **by name**, not by
  path — the same upstream build lays its tree out differently between
  releases.
- A pruned file must leave the index `files` mapping in the same commit series
  as the artifact: a mapping for a path the zip no longer contains fails the
  install with "extracted path not found", and a file left unmapped silently
  disappears from installed copies.

## Layout and DLLs

- `layout: flat` only when the binary **is** the entry users and tools resolve.
  Otherwise `layout: shim`: the payload and its private DLLs live under
  `opt/<pkg>/`, and only links appear in `usr/bin`. The standalone WinuxCmd
  setup puts `<root>\usr\bin` on `%PATH%` (and the niubash layout has
  `<root>\bin` on it), so a private DLL in either directory is a loaded gun —
  a flat OpenSSH dropped `libcrypto.dll` into a PATH directory before it was
  repackaged as a shim.
- Declare **every** command the payload provides in `commands`; that list drives
  the `usr/bin` links and the PATH entry links, and a command missing from it is
  installed but unreachable.

## Traps

- **32-bit upstream builds.** ezwinports' `gawk-*-w32-bin.zip` is x86 and runs on
  x64 Windows through WOW64; the index still records it as `windows-x64` because
  that is the platform it runs on, but the description must say so. A pure x64
  build means compiling from source.
- **SourceForge 403s** the direct links for some regions; GitHub runners (US) are
  unaffected, so a mirror that works in CI can still be unreachable for a user.
- **Re-running a workflow must be safe.** The same tag with different bytes is
  the worst outcome: if the build is not reproducible, bump the revision
  instead of overwriting the release.
- `size.txt` and `sha256.txt` are read by hand when writing the index PR —
  cross-check them against the downloaded asset, once, every time.
