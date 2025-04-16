//
//  DragRectangleView.swift
//  TouchScreen
//
//  Created by 변희주 on 4/15/25.
//

import Cocoa

class DragRectangleWindow: NSWindow {
    init() {
        let frame = NSScreen.main?.frame ?? .zero
        super.init(contentRect: frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = DragRectangleView(frame: frame)
    }
}

class DragRectangleView: NSView {
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let start = startPoint, let current = currentPoint else { return }

        let rect = CGRect(x: min(start.x, current.x),
                          y: min(start.y, current.y),
                          width: abs(start.x - current.x),
                          height: abs(start.y - current.y))

        NSColor.systemBlue.withAlphaComponent(0.3).setFill()
        NSBezierPath(rect: rect).fill()

        NSColor.systemBlue.withAlphaComponent(0.8).setStroke()
        NSBezierPath(rect: rect).stroke()
    }

    func begin(at point: CGPoint) {
        startPoint = point
        currentPoint = point
        needsDisplay = true
    }

    func update(to point: CGPoint) {
        currentPoint = point
        needsDisplay = true
    }

    func clear() {
        startPoint = nil
        currentPoint = nil
        needsDisplay = true
    }
}
