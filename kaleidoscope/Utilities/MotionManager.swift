import CoreMotion
import SwiftUI

@Observable
final class MotionManager {
    private let motionManager = CMMotionManager()
    private var lastAcceleration: CMAcceleration?
    private var shakeThreshold: Double = 0.3
    
    var currentAcceleration: CGPoint = .zero
    var currentIntensity: Double = 0
    var isAvailable: Bool = false
    
    init() {
        isAvailable = motionManager.isAccelerometerAvailable
    }
    
    func startMotionUpdates(onMotion: @escaping (CGPoint, Double) -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        
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
                
                onMotion(direction, intensity)
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        lastAcceleration = nil
        currentAcceleration = .zero
        currentIntensity = 0
    }
    
    deinit {
        stopMotionUpdates()
    }
}
