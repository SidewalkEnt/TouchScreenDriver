//
//  DragOverlayView.swift
//  TouchScreen
//
//  Created by 변희주 on 4/15/25.
//

import Cocoa

class DragPaintWindow: NSWindow {
    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        super.init(contentRect: screenFrame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = DragPaintView(frame: screenFrame)
    }
}

class DragPaintView: NSView {
    private var path = NSBezierPath()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        path.lineWidth = 30.0  // 브러시 크기
        NSColor.systemBlue.setStroke()  // 칠할 색
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.systemBlue.setStroke()
        path.stroke()
    }

    func addPoint(_ point: CGPoint) {
        if path.isEmpty {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
        needsDisplay = true
    }
}
