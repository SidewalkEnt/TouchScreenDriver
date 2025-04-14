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
    var lastGesture: String = "No gesture detected yet"

    private var manager: IOHIDManager!
    private let targetVendorID = 10176
    
    private var currentX: Int?
    private var currentY: Int?
    private var gestureRecognizer = TouchGestureRecognizer()

    func start() {
        activateDriverExtension()
        gestureInit()
    }

    private func activateDriverExtension() {
        let identifier = "com.naver.heejoo-byun.TouchScreen.driver"
        let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: identifier,
                                                                 queue: .main)
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }

    private func gestureInit() {
        gestureRecognizer.onGestureDetected = { [weak self] gesture in
            DispatchQueue.main.async {
                switch gesture {
                case .tap:
                    self?.lastGesture = "👆 Tap detected"
                    TouchHIDMonitor.shared.logMessage = "👆 Tap detected"
                    
                case .doubleTap:
                    self?.lastGesture = "👆👆 Double Tap detected"
                    TouchHIDMonitor.shared.logMessage = "👆👆 Double Tap detected"
                    
                case .drag(let startX, let startY, let endX, let endY):
                    self?.lastGesture = "✋ Drag from (\(startX),\(startY)) to (\(endX),\(endY))"
                    TouchHIDMonitor.shared.logMessage = "✋ Drag from (\(startX),\(startY)) to (\(endX),\(endY))"
                    
                case .swipeLeft:
                    self?.lastGesture = "👈 Swipe Left"
                    TouchHIDMonitor.shared.logMessage =  "👈 Swipe Left"

                case .swipeRight:
                    self?.lastGesture = "👉 Swipe Right"
                    TouchHIDMonitor.shared.logMessage = "👉 Swipe Right"

                case .swipeUp:
                    self?.lastGesture = "👆 Swipe Up"
                    TouchHIDMonitor.shared.logMessage = "👆 Swipe Up"

                case .swipeDown:
                    self?.lastGesture = "👇 Swipe Down"
                    TouchHIDMonitor.shared.logMessage = "👇 Swipe Down"

                }
            }
        }
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
                
                IOHIDDeviceRegisterInputValueCallback(device, { context, result, sender, value in
                    let element = IOHIDValueGetElement(value)
                    let usage = IOHIDElementGetUsage(element)
                    let usagePage = IOHIDElementGetUsagePage(element)
                    let intValue = IOHIDValueGetIntegerValue(value)
                    
                    let monitor = TouchHIDMonitor.shared
                    
                    // 터치 상태 (누르기/떼기)
                    if usagePage == kHIDPage_Digitizer && usage == kHIDUsage_Dig_TipSwitch {
                        let isTouching = intValue == 1

                        if isTouching && monitor.currentX == nil {
                            monitor.currentX = 0
                            monitor.currentY = 0
                        }
                        
                        monitor.gestureRecognizer.processTouchEvent(
                            isTouching: isTouching,
                            x: monitor.currentX,
                            y: monitor.currentY
                        )
                    }
                }, nil)
            }
        }
    }
    
    func stopMonitoring() {
        if manager != nil {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            manager = nil
        }
    }
    
    deinit {
        stopMonitoring()
    }
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
