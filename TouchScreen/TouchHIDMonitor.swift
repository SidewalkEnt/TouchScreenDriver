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
    
    @Published var logMessage: String = "aa"
    
    var currentX: CGFloat?
    var currentY: CGFloat?
    
    var minX: CGFloat = 0.0
    var maxX: CGFloat = 0.0
    var minY: CGFloat = 0.0
    var maxY: CGFloat = 0.0
        
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
            
    CGDisplayHideCursor(CGMainDisplayID()) // 포그라운드 상태일 때만 제대로 숨겨짐
    
    if usagePage == kHIDPage_Digitizer {
        if usage == kHIDUsage_Dig_TipSwitch {
            DispatchQueue.main.async {
                if intValue == 1 {
                    if let x = monitor.currentX, let y = monitor.currentY {
                        let (convertedX, counvertedY) = convertPosition(xRaw: x, yRaw: y)
                        onClickEvent(x: convertedX, y: counvertedY)
                    } else {
                        monitor.logMessage = "📍Touch On"
                    }
                } else {
                    if let x = monitor.currentX, let y = monitor.currentY {
                        let (convertedX, counvertedY) = convertPosition(xRaw: x, yRaw: y)
                        onClickEndEvent(x: convertedX, y: counvertedY)
                    }
                    monitor.currentX = nil
                    monitor.currentY = nil
                    monitor.logMessage = "📍Touch Off"
                }
            }
        }
    }

    if usagePage == kHIDPage_GenericDesktop {
        if usage == kHIDUsage_GD_X {
            monitor.currentX = CGFloat((intValue >> 16) & 0xFFFF)
            monitor.minX = CGFloat(IOHIDElementGetLogicalMin(element))
            monitor.maxX = CGFloat(IOHIDElementGetLogicalMax(element))
        }
        
        if usage == kHIDUsage_GD_Y {
            monitor.currentY = CGFloat((intValue >> 16) & 0xFFFF)
            monitor.minY = CGFloat(IOHIDElementGetLogicalMin(element))
            monitor.maxY = CGFloat(IOHIDElementGetLogicalMax(element))
        }
        
        if let x = monitor.currentX, let y = monitor.currentY {
            let (convertedX, counvertedY) = convertPosition(xRaw: x, yRaw: y)
            onDraggingEvent(x: convertedX, y: counvertedY)
            
            DispatchQueue.main.async {
                monitor.logMessage = "📍Touch at (X: \(Int(convertedX)), Y: \(Int(counvertedY)))"
            }
        }
    }
}

private func convertPosition(xRaw: CGFloat, yRaw: CGFloat) -> (CGFloat, CGFloat) {
    let monitor = TouchHIDMonitor.shared
    
    let screenWidth = CGFloat(CGDisplayPixelsWide(CGMainDisplayID()))
    let screenHeight = CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
    
    let normalizedX = (xRaw - monitor.minX) / (monitor.maxX - monitor.minX)
    let normalizedY = (yRaw - monitor.minY) / (monitor.maxY - monitor.minY)
    
    let screenX = normalizedX * screenWidth
    let screenY = normalizedY * screenHeight
    
    let boundedX = max(0, min(CGFloat(screenWidth), screenX))
    let boundedY = max(0, min(CGFloat(screenHeight), screenY))
    
    return (boundedX, boundedY)
}

private func onDraggingEvent(x: CGFloat, y: CGFloat) {
    CGEvent(mouseEventSource: nil,
            mouseType: .leftMouseDragged,
            mouseCursorPosition: CGPoint(x: x, y: y),
            mouseButton: .left)?.post(tap: .cghidEventTap)
}

//private func onScrollEvent(x: CGFloat, y: CGFloat) {
//    CGEvent(scrollWheelEvent2Source: nil,
//            units: .pixel, // .line도 가능
//            wheelCount: 2,
//            wheel1: Int32(y), // 수직 스크롤
//            wheel2: Int32(x), // 수평 스크롤
//            wheel3: 0)?.post(tap: .cghidEventTap)
//}

private func onClickEvent(x: CGFloat, y: CGFloat) {
    CGEvent(mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: CGPoint(x: x, y: y),
            mouseButton: .left)?.post(tap: CGEventTapLocation.cghidEventTap)
}

private func onClickEndEvent(x: CGFloat, y: CGFloat) {
    CGEvent(mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: CGPoint(x: x, y: y),
            mouseButton: .left)?.post(tap: CGEventTapLocation.cghidEventTap)
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
