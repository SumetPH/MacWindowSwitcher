import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let panel: NSPanel
  private var eventMonitors: [Any] = []
  private var isMenuBarIconHidden = false
  private var isShowingTemporaryIcon = false

  init(settings: AppSettings) {
    let contentSize = NSSize(width: 300, height: 140)
    panel = MenuBarPanel(
      contentRect: NSRect(origin: .zero, size: contentSize),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: true
    )

    super.init()

    isMenuBarIconHidden = settings.hideMenuBarIcon
    statusItem.isVisible = !isMenuBarIconHidden

    if let button = statusItem.button {
      if #available(macOS 11.0, *) {
        let image = NSImage(
          systemSymbolName: "macwindow",
          accessibilityDescription: "Mac Window Switcher"
        )
        image?.isTemplate = true
        button.image = image
      } else {
        button.title = "❖"
      }
      button.toolTip = "Mac Window Switcher"
      button.target = self
      button.action = #selector(togglePopover(_:))
    }

    panel.level = .popUpMenu
    panel.hasShadow = true
    panel.isFloatingPanel = true
    panel.hidesOnDeactivate = false
    panel.animationBehavior = .none
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.collectionBehavior = [.transient, .moveToActiveSpace]
    panel.contentViewController = NSHostingController(
      rootView: MenuBarView(settings: settings)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    )
  }

  func setMenuBarIconHidden(_ hidden: Bool) {
    isMenuBarIconHidden = hidden
    if !hidden {
      isShowingTemporaryIcon = false
    }
    statusItem.isVisible = !hidden || isShowingTemporaryIcon
  }

  func showPanelTemporarilyIfNeeded() {
    guard isMenuBarIconHidden else { return }

    isShowingTemporaryIcon = true
    statusItem.isVisible = true

    DispatchQueue.main.async { [weak self] in
      guard let self, !self.panel.isVisible, let button = self.statusItem.button else { return }
      self.showPanel(relativeTo: button)
    }
  }

  @objc private func togglePopover(_ sender: NSStatusBarButton) {
    if panel.isVisible {
      closePanel()
    } else {
      showPanel(relativeTo: sender)
    }
  }

  private func showPanel(relativeTo sender: NSStatusBarButton) {
    guard let buttonWindow = sender.window else { return }

    let buttonFrame = buttonWindow.convertToScreen(sender.convert(sender.bounds, to: nil))
    let screenFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
    let panelSize = panel.frame.size
    let centeredX = buttonFrame.midX - panelSize.width / 2
    let x = min(max(centeredX, screenFrame.minX), screenFrame.maxX - panelSize.width)

    panel.setFrameOrigin(NSPoint(x: x, y: screenFrame.maxY - panelSize.height))
    panel.orderFrontRegardless()
    panel.makeKey()
    installEventMonitors()

    DispatchQueue.main.async {
      sender.isHighlighted = true
    }
  }

  private func closePanel() {
    DispatchQueue.main.async {
      self.statusItem.button?.isHighlighted = false
    }
    panel.orderOut(nil)
    removeEventMonitors()

    if isShowingTemporaryIcon {
      isShowingTemporaryIcon = false
      statusItem.isVisible = !isMenuBarIconHidden
    }
  }

  private func installEventMonitors() {
    removeEventMonitors()

    let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    if let monitor = NSEvent.addGlobalMonitorForEvents(
      matching: mouseEvents,
      handler: { [weak self] _ in self?.closePanel() }
    ) {
      eventMonitors.append(monitor)
    }
    if let monitor = NSEvent.addLocalMonitorForEvents(
      matching: mouseEvents,
      handler: { [weak self] event in
        guard event.window !== self?.panel else { return event }
        self?.closePanel()
        return nil
      }
    ) {
      eventMonitors.append(monitor)
    }
    if let monitor = NSEvent.addLocalMonitorForEvents(
      matching: .keyDown,
      handler: { [weak self] event in
        guard event.keyCode == 53 else { return event }
        self?.closePanel()
        return nil
      }
    ) {
      eventMonitors.append(monitor)
    }
  }

  private func removeEventMonitors() {
    eventMonitors.forEach(NSEvent.removeMonitor)
    eventMonitors.removeAll()
  }
}

private final class MenuBarPanel: NSPanel {
  override var canBecomeKey: Bool { true }
}

private struct MenuBarView: View {
  @ObservedObject var settings: AppSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        if #available(macOS 11.0, *) {
          Image(systemName: "macwindow")
            .font(.title2)
        } else {
          Text("❖")
            .font(.title2)
        }
        Text("Mac Window Switcher")
          .font(.headline)
        Spacer()
        Toggle("Switcher", isOn: $settings.switcherEnabled)
          .labelsHidden()
          .toggleStyle(.switch)
          .controlSize(.small)
          .accessibilityLabel("Enable Mac Window Switcher")
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Toggle("Hide Menu Bar Icon", isOn: $settings.hideMenuBarIcon)
          .toggleStyle(.checkbox)
          .font(.caption)
          .foregroundStyle(.secondary)
          .controlSize(.small)
          .accessibilityLabel("Hide menu bar icon")

        HStack {
          Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            .toggleStyle(.checkbox)
            .font(.caption)
            .foregroundStyle(.secondary)
            .controlSize(.small)
            .accessibilityLabel("Launch at login")

          Spacer()

          Button("Quit", systemImage: "power") {
            NSApplication.shared.terminate(nil)
          }
          .buttonStyle(.borderless)
          .font(.caption)
        }
      }
    }
    .padding(16)
    .frame(width: 300)
  }
}
