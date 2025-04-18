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

    class TouchScreenExtension: public IOUserUSBHostHIDDevice {
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
