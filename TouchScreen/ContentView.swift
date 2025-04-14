//
//  ContentView.swift
//  TouchScreen
//
//  Created by 변희주 on 4/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var statusMessage: String = ""

    var body: some View {
        VStack {
            Text(statusMessage)
                .font(.title)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onReceive(TouchHIDMonitor.shared.$logMessage) { msg in
            statusMessage = msg
        }
    }
}
