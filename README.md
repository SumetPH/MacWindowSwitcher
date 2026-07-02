# Mac Window Switcher

Mac Window Switcher is a lightweight macOS menu-bar app that replaces the default `Cmd+Tab` flow with a window-focused switcher. It shows switchable windows from the current Space and the display where the mouse cursor is, then raises the selected window when Command is released.

## Features

- Intercepts `Cmd+Tab` and `Cmd+Shift+Tab` with a global keyboard event tap.
- Shows individual windows, including multiple windows from the same app.
- Filters out desktop elements, minimized windows, invisible windows, invalid bounds, and common transient helper windows.
- Narrows candidates to the current macOS Space when private Space APIs are available.
- Narrows candidates to the monitor currently containing the mouse cursor.
- Includes a menu-bar control for enabling/disabling the switcher, launch-at-login, and quitting the app.
- Requests Accessibility permission and opens System Settings when permission is missing.

## Requirements

- macOS 13 or newer
- Swift 6 toolchain
- Accessibility permission for the built app or Swift executable
- An Apple Development signing identity for the default app bundle build

The app uses public Accessibility/Core Graphics APIs plus dynamically loaded private macOS symbols for Space/window matching. If those private symbols are unavailable, the app falls back instead of crashing.

## Run in Development

```bash
./Scripts/dev-app.sh
```

On first launch, grant Accessibility permission in:

```text
System Settings > Privacy & Security > Accessibility
```

If macOS does not recognize the dev executable after rebuilding, remove the old entry from Accessibility and add the current executable again.

## Build the App Bundle

```bash
./Scripts/build-app.sh
```

The script creates:

```text
dist/Mac Window Switcher.app
```

By default the bundle is signed with `Apple Development` so Accessibility permission is more likely to persist across rebuilds. To use ad-hoc signing:

```bash
CODE_SIGN_IDENTITY=- ./Scripts/build-app.sh
```

## Usage

1. Launch the app.
2. Grant Accessibility permission when prompted.
3. Press `Cmd+Tab` to open the switcher.
4. Keep holding Command and press `Tab` or `Shift+Tab` to cycle.
5. Release Command to activate the selected window.
6. Press `Esc` while the overlay is open to cancel.

## Project Layout

```text
Assets/                         App icon source
Docs/                           Original implementation prompt and notes
Scripts/build-app.sh            Builds and signs the .app bundle
Scripts/dev-app.sh              Builds and runs the Swift executable
Sources/MacWindowSwitcher/      App source
Tests/                          Existing Swift package tests
```
