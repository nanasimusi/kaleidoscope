import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func lightTap() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }
    
    func mediumTap() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    func heavyTap() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    func patternChange() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    func playImpact(intensity: Double) {
        let clampedIntensity = CGFloat(max(0.3, min(1.0, intensity)))
        
        if intensity > 0.8 {
            heavyGenerator.impactOccurred(intensity: clampedIntensity)
            heavyGenerator.prepare()
        } else if intensity > 0.6 {
            mediumGenerator.impactOccurred(intensity: clampedIntensity)
            mediumGenerator.prepare()
        } else {
            lightGenerator.impactOccurred(intensity: clampedIntensity)
            lightGenerator.prepare()
        }
    }
}
