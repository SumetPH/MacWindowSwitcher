You are an expert macOS Swift/AppKit engineer.

Build a macOS app called `MacWindowSwitcher`.

The app is a custom Cmd+Tab replacement focused on window/app switching.

This is for personal use only. You may use private macOS APIs when needed. It does not need to be App Store safe.

Reference project for ideas:
https://github.com/ejbills/DockDoor

Use DockDoor only as a technical reference for:

- global keyboard event handling
- Cmd+Tab interception
- Accessibility window collection
- private Spaces APIs
- window focusing/activation
- overlay UI behavior

Main goal:
Create a working macOS app that replaces Cmd+Tab with a custom switcher showing only valid windows from the current Space and the monitor where the mouse cursor is.

Required features:

1. Global Cmd+Tab handling

- Intercept Cmd+Tab globally.
- Suppress the native macOS Cmd+Tab switcher while this app handles the shortcut.
- Show a custom overlay while Cmd is held.
- Cmd+Tab cycles forward.
- Cmd+Shift+Tab cycles backward.
- Releasing Cmd confirms the selected item and hides the overlay.

2. Window/app candidates
   Each candidate should represent a real switchable window when possible.

Each item should include:

- app icon
- app name
- window title if available
- process id
- window id if available
- accessibility window reference if available

Show multiple windows from the same app as separate candidates.

3. Current Space filtering

- Only show windows from the currently active macOS Space.
- Use private Spaces APIs if needed.
- Implement this as reliably as possible.
- If private Spaces APIs fail, fallback gracefully to visible on-screen windows.

4. Current monitor filtering

- Detect which monitor contains the mouse cursor.
- Show only windows belonging to that monitor.
- If a window overlaps multiple monitors, assign it to the monitor with the largest intersection area.

5. Exclude invalid windows
   Exclude:

- hidden apps
- minimized windows
- invisible windows
- desktop windows
- menu bar/system overlay windows
- windows with invalid bounds
- windows that cannot reasonably be activated

Use a combination of:

- CGWindowListCopyWindowInfo
- NSRunningApplication
- Accessibility APIs
- private APIs if useful

6. Overlay UI
   Create a simple usable switcher overlay:

- appears centered on the monitor containing the mouse cursor
- floating above normal windows
- does not steal focus if possible
- dark translucent background
- rounded corners
- app icons
- app names
- window titles
- selected item highlight

The UI does not need to be beautiful, but it must be usable.

7. Window activation
   When the user releases Cmd:

- activate the target app
- focus/raise the target window
- use NSRunningApplication activation
- use Accessibility APIs such as AXRaise and focused window attributes
- use fallback strategies when focusing fails

8. Permissions
   Handle required permissions:

- Accessibility permission
- Input Monitoring permission if needed

If permissions are missing:

- do not crash
- show a clear message
- provide a way to open System Settings

Suggested architecture:
You may choose the exact structure, but prefer clear modules such as:

- AppDelegate
- KeyboardEventTap
- WindowCollector
- WindowCandidate
- SpaceManager
- ScreenManager
- SwitcherController
- SwitcherOverlayWindow
- SwitcherOverlayView
- PermissionManager
- WindowActivator
- PrivateApis

Implementation approach:

- Start by creating a minimal working macOS AppKit app.
- Then implement the core loop:
  1. permission checks
  2. collect windows
  3. filter hidden/minimized/invalid windows
  4. filter current Space
  5. filter current monitor by mouse cursor
  6. show overlay
  7. cycle selection
  8. activate selected window

- Prefer a working implementation over a perfect architecture.
- Keep private API declarations isolated in PrivateApis.swift.
- Add comments explaining private API usage.
- Add reasonable debug logging so issues can be diagnosed.

Acceptance criteria:

- App builds and runs on macOS.
- After permissions are granted, pressing Cmd+Tab shows the custom switcher.
- Native macOS Cmd+Tab should not appear while this app handles Cmd+Tab.
- Cmd+Tab cycles forward.
- Cmd+Shift+Tab cycles backward.
- Releasing Cmd activates the selected app/window.
- Overlay appears on the monitor where the mouse cursor is.
- Hidden apps are not shown.
- Minimized windows are not shown.
- Windows from other Spaces are not shown.
- Windows from other monitors are not shown.
- App does not crash when permissions are missing.
- App does not crash if private Spaces APIs fail.

After implementation, report:

- files created/changed
- how to build and run
- permissions required
- private APIs used
- known limitations
- what to test manually
