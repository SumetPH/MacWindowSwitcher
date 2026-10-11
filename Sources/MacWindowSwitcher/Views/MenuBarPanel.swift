import AppKit

/// Borderless panel that can still take key focus for its toggles.
final class MenuBarPanel: NSPanel {
  override var canBecomeKey: Bool { true }
}
