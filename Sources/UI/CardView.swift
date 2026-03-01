import AppKit

class CardView: NSView {
    var cornerRadius: CGFloat = 8.0 {
        didSet {
            layer?.cornerRadius = cornerRadius
        }
    }

    var borderColor: NSColor = NSColor.separatorColor {
        didSet {
            layer?.borderColor = borderColor.cgColor
        }
    }

    var borderWidth: CGFloat = 1.0 {
        didSet {
            layer?.borderWidth = borderWidth
        }
    }

    var customBackgroundColor: NSColor = NSColor.controlBackgroundColor {
        didSet {
            layer?.backgroundColor = customBackgroundColor.cgColor
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    override var wantsUpdateLayer: Bool {
        return true
    }

    private func setupLayer() {
        self.wantsLayer = true
        self.layer?.cornerRadius = cornerRadius
        self.layer?.borderColor = borderColor.cgColor
        self.layer?.borderWidth = borderWidth
        self.layer?.backgroundColor = customBackgroundColor.cgColor
    }

    override func updateLayer() {
        super.updateLayer()
        self.layer?.borderColor = borderColor.cgColor
        self.layer?.backgroundColor = customBackgroundColor.cgColor
    }
}
