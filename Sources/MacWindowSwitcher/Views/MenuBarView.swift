import AppKit
import SwiftUI

struct MenuBarView: View {
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
