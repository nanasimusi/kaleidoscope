import CoreMotion
import SwiftUI

@Observable
final class MotionManager {
    private let motionManager = CMMotionManager()
    private var lastAcceleration: CMAcceleration?
    private var shakeThreshold: Double = 0.3
    
    var currentAcceleration: CGPoint = .zero
    var currentIntensity: Double = 0
    var currentTilt: CGPoint = .zero  // X: roll (左右), Y: pitch (前後)
    var isAvailable: Bool = false
    var onShake: (() -> Void)?
    var onTiltChange: ((CGPoint) -> Void)?
    
    init() {
        isAvailable = motionManager.isAccelerometerAvailable && motionManager.isDeviceMotionAvailable
    }
    
    func startMonitoring() {
        print("=== MotionManager: Starting monitoring ===")
        print("Accelerometer available: \(motionManager.isAccelerometerAvailable)")
        print("Device motion available: \(motionManager.isDeviceMotionAvailable)")
        
        guard motionManager.isAccelerometerAvailable else {
            print("ERROR: Accelerometer not available!")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            let acceleration = data.acceleration
            
            // Calculate delta from last reading for shake detection
            var deltaX: Double = 0
            var deltaY: Double = 0
            var deltaZ: Double = 0
            
            if let last = self.lastAcceleration {
                deltaX = acceleration.x - last.x
                deltaY = acceleration.y - last.y
                deltaZ = acceleration.z - last.z
            }
            
            self.lastAcceleration = acceleration
            
            // Calculate shake intensity from acceleration changes
            let shakeMagnitude = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
            
            // Filter out small movements (noise)
            if shakeMagnitude > self.shakeThreshold {
                // Normalize and cap intensity
                let intensity = min(1.0, (shakeMagnitude - self.shakeThreshold) / 1.5)
                
                // Direction based on current tilt (not delta)
                let direction = CGPoint(
                    x: acceleration.x,
                    y: -acceleration.y // Invert Y for natural feel
                )
                
                self.currentAcceleration = direction
                self.currentIntensity = intensity
                
                // Trigger shake callback if available
                if intensity > 0.5 {
                    self.onShake?()
                }
            }
        }
        
        // デバイスの傾きを継続的に監視（ジャイロスコープ統合データ）
        guard motionManager.isDeviceMotionAvailable else {
            print("ERROR: Device motion not available!")
            return
        }
        
        print("Starting device motion updates...")
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Device motion error: \(error)")
                return
            }
            
            guard let motion = motion else {
                print("No motion data received")
                return
            }
            
            // デバイスの姿勢から傾きを取得
            let attitude = motion.attitude
            
            // pitch: 前後の傾き (-π/2 ~ π/2)
            // roll: 左右の傾き (-π ~ π)
            let pitch = attitude.pitch
            let roll = attitude.roll
            
            // 自然な範囲に正規化 (-1.0 ~ 1.0)
            // 縦持ち時の傾きを基準に調整
            let normalizedRoll = max(-1.0, min(1.0, roll / (Double.pi / 3)))  // ±60度で最大
            let normalizedPitch = max(-1.0, min(1.0, pitch / (Double.pi / 4))) // ±45度で最大
            
            let tilt = CGPoint(
                x: normalizedRoll,
                y: normalizedPitch
            )
            
            // 初回のみログ出力
            if self.currentTilt == .zero {
                print("✓ First tilt detected: roll=\(normalizedRoll), pitch=\(normalizedPitch)")
            }
            
            self.currentTilt = tilt
            self.onTiltChange?(tilt)
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        lastAcceleration = nil
        currentAcceleration = .zero
        currentIntensity = 0
        currentTilt = .zero
    }
    
    deinit {
        stopMonitoring()
    }
}
