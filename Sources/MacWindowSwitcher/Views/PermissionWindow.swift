import AppKit

/// Setup window shown while Accessibility permission is missing.
final class PermissionWindow: NSWindow {
    init(target: AnyObject, openSettingsAction: Selector, quitAction: Selector) {
        let width: CGFloat = 380
        let height: CGFloat = 180
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        super.init(
            contentRect: rect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        self.title = "Mac Window Switcher Setup"
        self.center()
        self.isReleasedWhenClosed = false

        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 16
        container.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "Accessibility Permission Required")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 15)
        titleLabel.alignment = .center
        container.addArrangedSubview(titleLabel)

        let descLabel = NSTextField(labelWithString: "Mac Window Switcher requires Accessibility privileges to monitor the Cmd+Tab hotkey and bring selected windows to the front.")
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.lineBreakMode = .byWordWrapping
        container.addArrangedSubview(descLabel)

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12

        let settingsButton = NSButton(title: "Open System Settings", target: target, action: openSettingsAction)
        settingsButton.bezelStyle = .rounded
        buttonStack.addArrangedSubview(settingsButton)

        let quitButton = NSButton(title: "Quit", target: target, action: quitAction)
        quitButton.bezelStyle = .rounded
        buttonStack.addArrangedSubview(quitButton)

        container.addArrangedSubview(buttonStack)
        self.contentView = container

        if let contentView = self.contentView {
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                container.topAnchor.constraint(equalTo: contentView.topAnchor),
                container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
                settingsButton.widthAnchor.constraint(equalToConstant: 160),
                quitButton.widthAnchor.constraint(equalToConstant: 80)
            ])
        }
    }
}
