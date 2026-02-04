# BSArchSE Release Checklist (Arch/Garuda)

## Build

1. Confirm binaries exist and are executable:
- `BSArch-linux`
- `linux/bin/bsarch-core`
- `linux/.build-bsarch-ui/bsarch-ui`
2. Run automated checks:
- `linux/native-port/smoke-test-bsarch.sh`
- `linux/native-port/regression-paths-bsarch.sh`
- `linux/native-port/stress-large-bsarch.sh`
3. Create distributable:
- `linux/native-port/package-bsarchse.sh`

## Runtime Validation

1. Terminal launch:
- `./BSArch-linux`
2. Dolphin launch:
- run `BSArch-linux` from file manager
3. UI parity sanity:
- load multiple archives
- use `Unpack Selected` and `Pack Selected`
- open `Archiv-Info` dialog
- verify `Tmp` cleanup on close

## User Install Validation

1. Run:
- `./linux/install-bsarch-ui.sh`
2. Confirm:
- `~/.local/bin/BSArch-linux` exists
- `~/.local/share/applications/BSArchSE.desktop` exists
3. Desktop launcher opens app.

## Release Artifacts

1. Attach archive:
- `linux/dist/bsarchse-linux-x86_64.tar.gz` (or chosen name)
2. Include short release notes:
- supported commands (`pack`, `unpack`, `list`, `dump`)
- known limitations
- tested desktop env/theme (Plasma, Breeze/Breeze Dark)
