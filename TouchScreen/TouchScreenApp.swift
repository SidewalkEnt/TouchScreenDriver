//
//  TouchScreenApp.swift
//  TouchScreen
//
//  Created by 변희주 on 4/8/25.
//

import SwiftUI

@main
struct TouchScreenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300)
                .onAppear {
                    TouchHIDMonitor.shared.start()
                }
        }
    }
}
