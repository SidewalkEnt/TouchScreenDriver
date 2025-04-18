# ⚙️ 터치스크린 연결 방법
1. XCode 프로젝트 macOS로 생성
2. DriverKit 설치
3. 프로젝트 빌드하지 말고 app으로 배포 (아카이브)
4. 설치한 driver 사용 위해 system extension 권한 요청
5. HIDManager 초기화 & 연결된 HID open & vendorID로 원하는 HID 감지
6. callBack으로 오는 usage, usagePage, intValue 가지고 동작 처리


## 1. XCode 프로젝트 macOS로 생성
![스크린샷 2025-04-18 오후 12 33 24](https://github.com/user-attachments/assets/d4acfe8b-f931-4e88-9c3f-c65b7f91342f)


## 2. DriverKit 설치
* File -> New -> Target

![스크린샷 2025-04-18 오후 12 04 38](https://github.com/user-attachments/assets/4c0a6b77-a5e1-4705-92e2-c252dda07c88)


* DriverKit 탭 -> Driver

![스크린샷 2025-04-18 오후 12 04 50](https://github.com/user-attachments/assets/b2679b79-c095-4aaa-8c4b-adf9d3943694)
![스크린샷 2025-04-18 오후 12 38 15](https://github.com/user-attachments/assets/d20ff328-3c09-4a59-8d5b-de6351988d06)

  * 이렇게 설치를 하면 자동으로 3개의 파일이 생성 (.iig, .cpp, .plist)
  * .iig 파일을 아래와 같이 수정
  
    ```c
    #ifndef TouchScreenExtension_h // 생성한 file이름_h
    #define TouchScreenExtension_h

    #include <DriverKit/IOService.iig>
    #include <HIDDriverKit/IOUserUSBHostHIDDevice.iig>

    class TouchScreenExtension: public IOUserUSBHostHIDDevice { // 생성할 클래스 이름
         public:
         virtual bool init() override;
         virtual void free() override;
    
    virtual kern_return_t
    Start(IOService * provider) override;
    };

    #endif /* TouchScreenExtension_h */
    ```
 * .cpp 파일을 아래와 같이 수정
   ```c
   #include "TouchScreenExtension.h" // 생성한 file이름.h
   
   #include <os/log.h>
   #include <DriverKit/IOUserServer.h>
   #include <DriverKit/IOLib.h>
   #include <DriverKit/OSCollections.h>
   
   struct TouchScreenExtension_IVars // 생성한 file이름_IVars
   {
       OSArray *elements;
       
       struct {
           OSArray *collections;
       } digitizer;
   };
   
   #define _elements   ivars->elements
   #define _digitizer  ivars->digitizer
   
   bool TouchScreenExtension::init()
   {
       os_log(OS_LOG_DEFAULT, "TouchScreenExtension init");
   
       if (!super::init()) {
           return false;
       }
       
       ivars = IONewZero(TouchScreenExtension_IVars, 1);
       if (!ivars) {
           return false;
       }
       
   exit:
       return true;
   }
   
   void TouchScreenExtension::free()
   {
       if (ivars) {
           OSSafeReleaseNULL(_elements);
           OSSafeReleaseNULL(_digitizer.collections);
       }
       
       IOSafeDeleteNULL(ivars, TouchScreenExtension_IVars, 1);
       super::free();
   }
   
   kern_return_t
   IMPL(TouchScreenExtension, Start)
   {
       kern_return_t ret;
       
       ret = Start(provider, SUPERDISPATCH);
       if (ret != kIOReturnSuccess) {
           Stop(provider, SUPERDISPATCH);
           return ret;
       }
   
       os_log(OS_LOG_DEFAULT, "Hello World");
       
       RegisterService();
       
       return ret;
   }
   ```

 * .plist 파일 sourceCode로 연다음, 아래 코드 참고하여 수정

![스크린샷 2025-04-18 오후 2 30 10](https://github.com/user-attachments/assets/d85e6dce-6c07-4346-b2e5-a1b01eab0562) 

   ```swift
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   	<key>IOKitPersonalities</key>
   	<dict>
   		<key>TouchScreenExtension</key> // 생성한 클래스 이름
   		<dict>
   			<key>CFBundleIdentifier</key>
   			<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   			<key>IOClass</key>
   			<string>AppleUserHIDDevice</string>
   			<key>IOProviderClass</key>
   			<string>IOUSBHostInterface</string>
   			<key>IOUserClass</key>
   			<string>TouchScreenExtension</string> // 생성한 클래스 이름
   			<key>IOUserServerName</key>
   			<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   			<key>IOUserServerOneProcess</key>
   			<true/>
   			<key>PrimaryUsage</key>
   			<integer>4</integer>
   			<key>PrimaryUsagePage</key>
   			<integer>13</integer>
   			<key>ProductID</key>
   			<integer>21781</integer>
   			<key>Transport</key>
   			<string>USB</string>
   			<key>VendorID</key>
   			<integer>1267</integer>
   		</dict>
   	</dict>
   </dict>
   </plist>
   ```

 * project TARGETS 확인
![스크린샷 2025-04-18 오후 2 33 59](https://github.com/user-attachments/assets/72c635ec-27d2-4d1a-a5a5-3b4bf88ab6dc)

* Frameworks 칸에 아래와 같이 .dext 파일이 들어가 있는 것 확인, 추가적으로 IOKit framework 설치
![스크린샷 2025-04-18 오후 2 34 42](https://github.com/user-attachments/assets/88d645c5-7798-476f-8287-78fb36042f95)

* Signing & Capabilities 탭 누르고 +Capablility 버튼 누른 다음 System Extension 추가
![스크린샷 2025-04-18 오후 3 00 55](https://github.com/user-attachments/assets/923bca4d-2727-43b4-8989-0be60ed93d5e)

* 추가로 .entitlements 파일에 아래와 같이 Communicates with Drivers 추가 후 YES로 설정
![스크린샷 2025-04-18 오후 3 03 00](https://github.com/user-attachments/assets/cc39b044-7f21-4a88-a481-a246bea47176)

* Driver의 TARGETS도 확인 (DriverKit은 이미 추가되어 있으니 HIDDriverKit 설치)
![스크린샷 2025-04-18 오후 2 37 30](https://github.com/user-attachments/assets/a9e34728-9b1d-442c-a89d-716aa67908da)

* Signing & Capabilities 탭 누르고 
![스크린샷 2025-04-18 오후 2 38 48](https://github.com/user-attachments/assets/f98a16bd-c530-4877-bc3b-235110955f13)

* +Capability 버튼 누른다음 위의 3가지 모두 다 넣기
![스크린샷 2025-04-18 오후 2 39 33](https://github.com/user-attachments/assets/b66874f1-3267-4506-b090-0531289d3515)



## 3. 프로젝트 빌드하지 말고 app으로 배포 (아카이브)
* ❗️빌드해서 테스트하면 IOHID 열리지 않기 때문에 꼭!!! 아카이브
* 테스트용으로 아카이브 (Product -> Archive)
![스크린샷 2025-04-18 오후 2 44 19](https://github.com/user-attachments/assets/e189a208-1436-4db0-aac2-5e38aea250ca)

* 이 상태에서 Distribute App -> Custom -> Copy App -> Export
![스크린샷 2025-04-18 오후 2 45 41](https://github.com/user-attachments/assets/50094053-54d1-4117-a603-660457747d3b)
![스크린샷 2025-04-18 오후 2 46 17](https://github.com/user-attachments/assets/4e14d92b-1e69-43ec-9c3c-3666513ef888)
![스크린샷 2025-04-18 오후 2 46 35](https://github.com/user-attachments/assets/fe9ec1bc-eab8-4dff-8b3c-b862cc21283f)

* 저장된 폴더에서 .app 파일을 Applications로 옮기기 (ex. mv ~/Desktop/TouchScreenApp/TouchScreen.app /Applications/)
  *  ~/Desktop/TouchScreenApp/TouchScreen.app : 앱이 저장된 경로
  *  /Applications/ : 옮길 경로

* Applications에서 앱 열기 (open /Applications/TouchScreen.app)



## 4. 설치한 driver 사용 위해 system extension 권한 요청
* 권한 요청할 파일에
   ```swift
   import SystemExtensions
   ```

* 권한 허용 요청 코드 작성
   ```swift
     let identifier = "com.naver.heejoo-byun.TouchScreen.TouchScreenExtension"
     let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: identifier,
                                                                 queue: .main)
     request.delegate = self
     OSSystemExtensionManager.shared.submitRequest(request)
   ```

* delegate 위임하고 함수 작성
   ```swift
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
           initializeHIDManager() // 이어서 작성할 HID 초기화 함수
       }
       
       func request(_ request: OSSystemExtensionRequest, didFailWithError error: any Error) {
           print("❌ Failed to activate extension: \(error.localizedDescription)")
           logMessage = "❌ Failed to activate extension: \(error.localizedDescription)"
       }
   }
   ```


## 5. HIDManager 초기화 & 연결된 HID open & vendorID로 원하는 HID 감지
    ```swift
    private let targetVendorID = 1267 // 터치스크린의 vendorID

    private func initializeHIDManager() {
           manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
           IOHIDManagerSetDeviceMatching(manager, nil)
           IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
           let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) // 연결된 HID open
           
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
                   IOHIDDeviceRegisterInputValueCallback(device, inputCallback, context) // inputCallback 함수는 이어서 작성 (이 함수에서 터치스크린의 이벤트를 받아와 처리)
   
               }
           }
       }
    ```


## 6. callBack으로 오는 usage, usagePage, intValue 가지고 동작 처리
    ```swift
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
                onScrollEvent(down: monitor.currentY ?? 0.0 > CGFloat((intValue >> 16) & 0xFFFF))
    
                monitor.currentY = CGFloat((intValue >> 16) & 0xFFFF)
                monitor.minY = CGFloat(IOHIDElementGetLogicalMin(element))
                monitor.maxY = CGFloat(IOHIDElementGetLogicalMax(element))
            }
            
            if let x = monitor.currentX, let y = monitor.currentY {
                let (convertedX, convertedY) = convertPosition(xRaw: x, yRaw: y)
                onMoveEvent(x: convertedX, y: convertedY)
                
                DispatchQueue.main.async {
                    monitor.logMessage = "📍Touch at (X: \(Int(convertedX)), Y: \(Int(convertedY)))"
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
    
    private func onMoveEvent(x: CGFloat, y: CGFloat) {
        CGEvent(mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: CGPoint(x: x, y: y),
                mouseButton: .left)?.post(tap: .cghidEventTap)
    }
    
    private func onScrollEvent(down: Bool) {
        CGEvent(scrollWheelEvent2Source: nil,
                units: .pixel,
                wheelCount: 2,
                wheel1: Int32(down ? -35 : 35),
                wheel2: Int32(0),
                wheel3: 0)?.post(tap: .cghidEventTap)
    }
    
    private func onClickEvent(x: CGFloat, y: CGFloat) {
        CGEvent(mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: CGPoint(x: x, y: y),
                mouseButton: .left)?.post(tap: .cghidEventTap)
    }
    
    private func onClickEndEvent(x: CGFloat, y: CGFloat) {
        CGEvent(mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: CGPoint(x: x, y: y),
                mouseButton: .left)?.post(tap: .cghidEventTap)
    }
    ```
