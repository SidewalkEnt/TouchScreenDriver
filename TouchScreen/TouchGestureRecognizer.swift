//
//  TouchGestureRecognizer.swift
//  TouchScreen
//
//  Created by 변희주 on 4/14/25.
//

import Foundation
import IOKit
import IOKit.hid

class TouchGestureRecognizer {
    enum Gesture {
        case tap
        case doubleTap
        case drag(startX: Int, startY: Int, endX: Int, endY: Int)
        case swipeLeft
        case swipeRight
        case swipeUp
        case swipeDown
    }
    
    private var touchPoints: [(x: Int, y: Int, timestamp: Date)] = []
    private var lastTapTime: Date?
    private var isCurrentlyTouching = false
    private let doubleTapInterval: TimeInterval = 0.3
    private let swipeThreshold: Int = 50
    
    // 제스처 감지 시 호출될 클로저
    var onGestureDetected: ((Gesture) -> Void)?
    
//    func processTouchEvent(isTouching: Bool, x: Int? = nil, y: Int? = nil) {
//        let now = Date()
//        
//        if isTouching != isCurrentlyTouching {
//            isCurrentlyTouching = isTouching
//            
//            if isTouching {
//                // 터치 시작
//                if let x = x, let y = y {
//                    touchPoints = [(x: x, y: y, timestamp: now)]
//                }
//            } else {
//                // 터치 종료
//                if touchPoints.count > 0 {
//                    // 싱글 탭 vs 더블 탭 감지
//                    if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < doubleTapInterval {
//                        onGestureDetected?(.doubleTap)
//                    } else if touchPoints.count < 3 { // 적은 포인트 = 탭
//                        onGestureDetected?(.tap)
//                    } else {
//                        detectGesture()
//                    }
//                    
//                    lastTapTime = now
//                }
//            }
//        } else if isTouching, let x = x, let y = y {
//            // 드래그 중 - 포인트 추가
//            touchPoints.append((x: x, y: y, timestamp: now))
//        }
//    }
    
    func processTouchEvent(isTouching: Bool, x: Int? = nil, y: Int? = nil) {
        let now = Date()
        
        // 현재 터치 상태가 변경되었을 때 (터치 시작 또는 종료)
        if isTouching != isCurrentlyTouching {
            isCurrentlyTouching = isTouching
            
            if isTouching {
                // 터치 시작 - 첫 포인트 기록
                let xPos = x ?? 0
                let yPos = y ?? 0
                touchPoints = [(x: xPos, y: yPos, timestamp: now)]
            } else {
                // 터치 종료 - 제스처 분석
                if touchPoints.count == 0 {
                    // 좌표가 없는 경우 적어도 기본 터치는 감지
                    onGestureDetected?(.tap)
                } else if touchPoints.count == 1 {
                    // 좌표는 있지만 움직임이 없었을 경우
                    if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < doubleTapInterval {
                        onGestureDetected?(.doubleTap)
                    } else {
                        onGestureDetected?(.tap)
                    }
                } else {
                    // 여러 포인트가 있으면 제스처 감지
                    detectGesture()
                }
                
                lastTapTime = now
            }
        } else if isTouching {
            // 터치 중 - 좌표가 있으면 포인트 추가
            // 좌표가 없더라도 임의로 이전 좌표에서 조금 이동한 값을 생성
            let xPos: Int
            let yPos: Int
            
            if let xVal = x, let yVal = y {
                // 실제 좌표 데이터가 있는 경우
                xPos = xVal
                yPos = yVal
            } else if let lastPoint = touchPoints.last {
                // 좌표가 없는 경우, 이전 좌표에서 약간 이동한 값 생성
                // 시간에 따라 특정 방향으로 이동하는 시뮬레이션
                let timeElapsed = now.timeIntervalSince(lastPoint.timestamp)
                let moveDistance = Int(timeElapsed * 100) // 초당 100픽셀 이동 시뮬레이션
                
                // 4가지 방향으로 번갈아가며 이동 (시간을 기준으로)
                let direction = Int(now.timeIntervalSince1970 * 2) % 4
                
                switch direction {
                case 0: // 오른쪽
                    xPos = lastPoint.x + moveDistance
                    yPos = lastPoint.y
                case 1: // 왼쪽
                    xPos = lastPoint.x - moveDistance
                    yPos = lastPoint.y
                case 2: // 아래
                    xPos = lastPoint.x
                    yPos = lastPoint.y + moveDistance
                case 3: // 위
                    xPos = lastPoint.x
                    yPos = lastPoint.y - moveDistance
                default:
                    xPos = lastPoint.x
                    yPos = lastPoint.y
                }
            } else {
                // 이전 포인트도 없는 경우, 기본값 사용
                xPos = 0
                yPos = 0
            }
            
            touchPoints.append((x: xPos, y: yPos, timestamp: now))
        }
    }
    
    private func detectGesture() {
        guard touchPoints.count >= 2 else { return }
        
        let startPoint = touchPoints.first!
        let endPoint = touchPoints.last!
        
        let xDistance = endPoint.x - startPoint.x
        let yDistance = endPoint.y - startPoint.y
        
        let absXDistance = abs(xDistance)
        let absYDistance = abs(yDistance)
        
        // 드래그
        let gesture: Gesture = .drag(
            startX: startPoint.x,
            startY: startPoint.y,
            endX: endPoint.x,
            endY: endPoint.y
        )
        
        // 스와이프 방향 감지
        if absXDistance > absYDistance && absXDistance > swipeThreshold {
            // 수평 스와이프
            if xDistance > 0 {
                onGestureDetected?(.swipeRight)
            } else {
                onGestureDetected?(.swipeLeft)
            }
        } else if absYDistance > absXDistance && absYDistance > swipeThreshold {
            // 수직 스와이프
            if yDistance > 0 {
                onGestureDetected?(.swipeDown)
            } else {
                onGestureDetected?(.swipeUp)
            }
        } else {
            // 일반 드래그
            onGestureDetected?(gesture)
        }
    }
}
