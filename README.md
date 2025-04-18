# 터치스크린 연결 방법
1. XCode 프로젝트 macOS로 생성
2. DriverKit 설치
3. 프로젝트 빌드하지 말고 app으로 배포 (아카이브)
4. 설치한 driver 사용 위해 system extension 권한 요청
5. 권한 허용 이후 HIDManager 초기화
6. IOHIDManagerOpen (연결된 HID open)
7. vendorID로 원하는 HID 감지
8. callBack으로 오는 usage, usagePage, intValue 가지고 동작 처리
