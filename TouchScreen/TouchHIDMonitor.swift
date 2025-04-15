//
//  TouchHIDMonitor.swift
//  TouchScreen
//
//  Created by 변희주 on 4/8/25.
//

import SwiftUI
import SystemExtensions
import IOKit.hid

final class TouchHIDMonitor: NSObject, ObservableObject {
    static let shared = TouchHIDMonitor()
    @Published var logMessage: String = "zz"
    var currentX: CGFloat?
    var currentY: CGFloat?
    
    private var manager: IOHIDManager!
    private let targetVendorID = 1267

    func start() {
        activateDriverExtension()
    }

    private func activateDriverExtension() {
        let identifier = "com.naver.heejoo-byun.TouchScreen.driver"
        let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: identifier,
                                                                 queue: .main)
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }
    
    private func initializeHIDManager() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, nil)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        if result != kIOReturnSuccess {
            logMessage = "❌ IOHIDManagerOpen failed with code: \(String(format: "0x%X", result))"
            return
        } else {
            logMessage = "✅ IOHIDManagerOpen succeeded"
        }
        
        guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return }
        
        for device in deviceSet {
            let vendorID = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
            let usagePage = (IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? NSNumber)?.intValue ?? 0
            let usage = (IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsageKey as CFString) as? NSNumber)?.intValue ?? 0
            
            if vendorID == targetVendorID && usagePage == kHIDPage_Digitizer && usage == kHIDUsage_Dig_TouchScreen {
                logMessage = "✅ Found touchscreen device: VendorID=\(vendorID)"
                
                let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
                IOHIDDeviceRegisterInputValueCallback(device, inputCallback, context)

            }
        }
    }
}

private func inputCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, value: IOHIDValue) {
    guard let context = context else { return }
    let monitor = Unmanaged<TouchHIDMonitor>.fromOpaque(context).takeUnretainedValue()
    let element = IOHIDValueGetElement(value)
    let usage = IOHIDElementGetUsage(element)
    let usagePage = IOHIDElementGetUsagePage(element)
    let intValue = IOHIDValueGetIntegerValue(value)

    if usagePage == kHIDPage_Digitizer {
        if usage == kHIDUsage_Dig_TipSwitch {
            DispatchQueue.main.async {
                monitor.logMessage = intValue == 1 ? "📍Touch On" : "📍Touch Off"
            }
        }
    }

    if usagePage == kHIDPage_GenericDesktop {
        if usage == kHIDUsage_GD_X {
            monitor.currentX = CGFloat(intValue)
        }
        
        if usage == kHIDUsage_GD_Y {
            monitor.currentY = CGFloat(intValue)
        }
        
        if let xRaw = monitor.currentX, let yRaw = monitor.currentY {
            let minX: CGFloat = 131_074
            let maxX: CGFloat = 134_219_776
            let minY: CGFloat = 131_074
            let maxY: CGFloat = 88_081_728
            
            let screenWidth = CGFloat(CGDisplayPixelsWide(CGMainDisplayID()))
            let screenHeight = CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
            
            let normalizedX = (xRaw - minX) / (maxX - minX)
            let normalizedY = (yRaw - minY) / (maxY - minY)
            
            let screenX = normalizedX * screenWidth
            let screenY = normalizedY * screenHeight
            
            moveCursorToPosition(x: screenX, y: screenY)
            
            DispatchQueue.main.async {
                monitor.logMessage = "📍Dragging"
            }
        }
    }
}

private func moveCursorToPosition(x: CGFloat, y: CGFloat) {
    let screenWidth = CGDisplayPixelsWide(CGMainDisplayID())
    let screenHeight = CGDisplayPixelsHigh(CGMainDisplayID())
    
    let boundedX = max(0, min(CGFloat(screenWidth), x))
    let boundedY = max(0, min(CGFloat(screenHeight), y))
    
    let moveEvent = CGEvent(mouseEventSource: CGEventSource(stateID: .hidSystemState),
                            mouseType: .mouseMoved,
                            mouseCursorPosition: CGPoint(x: boundedX, y: boundedY),
                            mouseButton: .left)
    
    moveEvent?.post(tap: .cghidEventTap)
}

extension TouchHIDMonitor: OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
    

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("🔒 System extension needs user approval")
        logMessage = "🔒 System extension needs user approval"
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print("✅ System Extension activated: \(result)")
        logMessage = "✅ System Extension activated: \(result)"
        initializeHIDManager()
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: any Error) {
        print("❌ Failed to activate extension: \(error.localizedDescription)")
        logMessage = "❌ Failed to activate extension: \(error.localizedDescription)"
    }
}
