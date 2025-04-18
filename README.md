### ⚙️ 터치스크린 연결 방법
1. XCode 프로젝트 macOS로 생성
2. DriverKit 설치
3. 프로젝트 빌드하지 말고 app으로 배포 (아카이브)
4. 설치한 driver 사용 위해 system extension 권한 요청
5. 권한 허용 이후 HIDManager 초기화
6. IOHIDManagerOpen (연결된 HID open)
7. vendorID로 원하는 HID 감지
8. callBack으로 오는 usage, usagePage, intValue 가지고 동작 처리


#### 1.XCode 프로젝트 macOS로 생성
![스크린샷 2025-04-18 오후 12 33 24](https://github.com/user-attachments/assets/d4acfe8b-f931-4e88-9c3f-c65b7f91342f)


#### 2.DriverKit 설치
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

* Driver의 TARGETS도 확인 (DriverKit은 이미 추가되어 있으니 HIDDriverKit 설치)
![스크린샷 2025-04-18 오후 2 37 30](https://github.com/user-attachments/assets/a9e34728-9b1d-442c-a89d-716aa67908da)

* Signing & Capabilities 탭 누르고 
![스크린샷 2025-04-18 오후 2 38 48](https://github.com/user-attachments/assets/f98a16bd-c530-4877-bc3b-235110955f13)

* +Capability 버튼 누른다음 위의 3가지 모두 다 넣기
![스크린샷 2025-04-18 오후 2 39 33](https://github.com/user-attachments/assets/b66874f1-3267-4506-b090-0531289d3515)


#### 3. 프로젝트 빌드하지 말고 app으로 배포 (아카이브)
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

