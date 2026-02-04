# BSArchSE Manual UI Parity Checklist (Large Archives)

Use this checklist in a desktop session (Plasma/Wayland or X11) to validate parity-critical UI workflows.

## Preconditions

- Build/output available:
  - `BSArch-linux`
  - `linux/bin/bsarch-core`
  - `linux/.build-bsarch-ui/bsarch-ui` (or runnable via `linux/bsarch-ui.sh`)
- Test data:
  - One medium archive (~500 MB)
  - One large archive (>1 GB) with deep folder structure and mixed file types
- Ensure writable target folders for unpack tests.

## Launch and Basic UX

1. Start `BSArch-linux` from terminal and from Dolphin.
2. Confirm window title/name is `BSArchSE`.
3. Confirm no blocking startup errors are shown.
4. Confirm menu button (hamburger) is present top-left.

Pass criteria:
- App opens in both launch modes.
- UI is responsive after load.

## Archive Loading

1. Open multiple archives via `Archives Browse` in one action.
2. Drag-and-drop one additional archive into the window.
3. Verify `Archive List` tab shows all loaded archives.
4. Select different archives and verify file list updates correctly.

Pass criteria:
- Multi-select works.
- Drag-and-drop loads archive(s) without replacing unexpectedly.

## Archive File List Behavior

1. Verify columns exist: `[Compressed] | Asset Name | Source File`.
2. Resize each column and confirm width persists while app is open.
3. Click `Asset Name` header: ascending/descending sort toggles.
4. Confirm left row numbers are not shown.

Pass criteria:
- Sorting and resizing are functional and stable.

## Filter and Selection Logic

1. Use search field and extension filter together.
2. Toggle compression filter checkboxes:
  - `All`
  - `Compressed`
  - `Uncompressed`
3. Verify filters are mutually consistent (no contradictory state).
4. Use `Rest` and `Clear List` buttons and verify result list updates.

Pass criteria:
- Filtered result count matches expectation.
- No stale rows remain after filter changes.

## Context Menu Parity

1. In `Archive File List`, right-click selected items.
2. Confirm menu entries include:
  - `Unpack Selected`
  - `Pack Selected`
  - `Archiv-Info`
3. Trigger `Archiv-Info` and verify it opens a dedicated dialog window (not output pane).

Pass criteria:
- All three actions are present and callable.

## Unpack Selected (Large Archive)

1. Select 50+ mixed entries from different folders.
2. Right-click `Unpack Selected`.
3. Choose target folder when prompted.
4. Verify extracted files exist with expected folder hierarchy.
5. Re-run to same folder and confirm overwrite/error behavior is sane.

Pass criteria:
- Extraction completes without crash.
- Paths and file contents are correct for sampled files.

## Pack Selected (Large Archive)

1. Select a representative subset in list.
2. Right-click `Pack Selected`.
3. Complete dialog options and create output archive.
4. Open created archive in app and verify listed entries match selection.

Pass criteria:
- Packed archive is valid and re-openable.
- Entry count/path set matches selected items.

## Double-Click Open Workflow

1. Double-click several list entries of different types.
2. Confirm files are unpacked to `./Tmp` and opened with default application.
3. Close app and confirm `./Tmp` is removed.

Pass criteria:
- Files open correctly.
- `Tmp` cleanup happens on normal close.

## Theme/Plasma Compatibility

1. Test with Breeze (light) and Breeze Dark.
2. Verify icons, text contrast, selection highlight, and context menus.
3. Confirm no broken font fallback messages affect usability.

Pass criteria:
- UI remains readable and usable on both themes.

## Report Template

Record for each test:
- Archive used
- Step number
- Result: Pass/Fail
- Notes (error text, screenshots, log path if any)

