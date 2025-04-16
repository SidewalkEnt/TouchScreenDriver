//
//  DragRectangleController.swift
//  TouchScreen
//
//  Created by 변희주 on 4/15/25.
//

import Foundation

class DragRectangleController {
    static let shared = DragRectangleController()
    private var window: DragRectangleWindow?
    private var view: DragRectangleView? {
        return window?.contentView as? DragRectangleView
    }

    func show() {
        if window == nil {
            window = DragRectangleWindow()
            window?.makeKeyAndOrderFront(nil)
        }
    }

    func beginDrag(at point: CGPoint) {
        show()
        view?.begin(at: point)
    }

    func updateDrag(to point: CGPoint) {
        view?.update(to: point)
    }

    func endDrag() {
        view?.clear()
    }
}
