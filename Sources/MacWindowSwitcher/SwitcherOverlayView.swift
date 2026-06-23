import AppKit

class CandidateCardView: NSView {
    private let iconView = NSImageView()
    private let appNameLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    init(candidate: WindowCandidate) {
        super.init(frame: .zero)
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        self.layer?.masksToBounds = true
        
        // App Icon Config
        iconView.image = candidate.appIcon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        
        // App Name Label Config
        appNameLabel.font = NSFont.boldSystemFont(ofSize: 12)
        appNameLabel.textColor = .white
        appNameLabel.alignment = .center
        appNameLabel.lineBreakMode = .byTruncatingTail
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appNameLabel)
        appNameLabel.stringValue = candidate.appName
        
        // Window Title Label Config
        titleLabel.font = NSFont.systemFont(ofSize: 10)
        titleLabel.textColor = NSColor(white: 0.8, alpha: 1.0)
        titleLabel.alignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 2
        titleLabel.cell?.usesSingleLineMode = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        let titleText = candidate.windowTitle.isEmpty ? "(No Title)" : candidate.windowTitle
        titleLabel.stringValue = titleText
        
        setupConstraints()
        updateAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Fixed card dimension bounds
            self.widthAnchor.constraint(equalToConstant: 160),
            self.heightAnchor.constraint(equalToConstant: 120),
            
            // Icon layout bounds
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // App name text layout
            appNameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            appNameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            appNameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            
            // Window title text layout
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8)
        ])
    }
    
    private func updateAppearance() {
        if isSelected {
            // Bright highlight with active accent border
            self.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.18).cgColor
            self.layer?.borderColor = NSColor.controlAccentColor.cgColor
            self.layer?.borderWidth = 2.0
        } else {
            // Subtle translucency
            self.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.05).cgColor
            self.layer?.borderColor = NSColor.clear.cgColor
            self.layer?.borderWidth = 0.0
        }
    }
}

class SwitcherOverlayView: NSView {
    private let visualEffectView = NSVisualEffectView()
    private let stackView = NSStackView()
    private var cardViews: [CandidateCardView] = []
    
    init(candidates: [WindowCandidate], selectedIndex: Int) {
        super.init(frame: .zero)
        
        // Configure dark translucent blur backdrop panel
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.masksToBounds = true
        addSubview(visualEffectView)
        
        // Configure stack layout
        stackView.orientation = .horizontal
        stackView.spacing = 10
        stackView.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stackView.alignment = .centerY
        stackView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(stackView)
        
        // Populate window cards
        for (index, candidate) in candidates.enumerated() {
            let card = CandidateCardView(candidate: candidate)
            card.isSelected = (index == selectedIndex)
            stackView.addArrangedSubview(card)
            cardViews.append(card)
        }
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Fill visualEffectView inside this view
            visualEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            // Align stackView inside visualEffectView content area
            stackView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
    }
    
    /// Highlights the selected card and un-highlights others
    func updateSelection(index: Int) {
        for (idx, card) in cardViews.enumerated() {
            card.isSelected = (idx == index)
        }
    }
}
