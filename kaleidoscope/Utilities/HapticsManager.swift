import UIKit
import CoreHaptics

final class HapticsManager {
    static let shared = HapticsManager()
    
    // 標準のフィードバックジェネレーター
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // Core Hapticsエンジン（カスタムパターン用）
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    private init() {
        prepareGenerators()
        setupCoreHaptics()
    }
    
    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        rigidGenerator.prepare()
        softGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    private func setupCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }
        
        supportsHaptics = true
        
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.stoppedHandler = { [weak self] reason in
                self?.restartEngine()
            }
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }
            try engine?.start()
        } catch {
            print("Core Haptics setup failed: \(error)")
            supportsHaptics = false
        }
    }
    
    private func restartEngine() {
        guard supportsHaptics else { return }
        do {
            try engine?.start()
        } catch {
            print("Failed to restart haptic engine: \(error)")
        }
    }
    
    // MARK: - 基本のタップフィードバック
    
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
    
    func rigidTap() {
        rigidGenerator.impactOccurred()
        rigidGenerator.prepare()
    }
    
    func softTap() {
        softGenerator.impactOccurred()
        softGenerator.prepare()
    }
    
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - 通知系フィードバック
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // MARK: - 強度指定のインパクト
    
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
    
    // MARK: - カレイドスコープ専用フィードバック
    
    /// タップ時の波紋フィードバック（柔らかく広がる感覚）
    func rippleFeedback() {
        guard supportsHaptics, let engine = engine else {
            softTap()
            return
        }
        
        do {
            // 柔らかい波紋のようなパターン
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            
            let events: [CHHapticEvent] = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                ], relativeTime: 0.08),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ], relativeTime: 0.16)
            ]
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            softTap()
        }
    }
    
    /// シェイク時の結晶化フィードバック（シャープで力強い）
    func crystallizeFeedback(intensity: Double) {
        guard supportsHaptics, let engine = engine else {
            heavyTap()
            return
        }
        
        let clampedIntensity = Float(max(0.5, min(1.0, intensity)))
        
        do {
            var events: [CHHapticEvent] = []
            
            // 最初の衝撃
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0
            ))
            
            // 連続した細かい振動（結晶が形成される感覚）
            let burstCount = Int(5 * clampedIntensity)
            for i in 0..<burstCount {
                let time = 0.03 + Double(i) * 0.025
                let burstIntensity = clampedIntensity * (1.0 - Float(i) / Float(burstCount) * 0.5)
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: burstIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: time
                ))
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            heavyTap()
        }
    }
    
    /// 強いシェイク時の衝撃フィードバック
    func strongShakeFeedback() {
        guard supportsHaptics, let engine = engine else {
            heavyTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.rigidTap()
            }
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // 強い衝撃の連続
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0
            ))
            
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0.05
            ))
            
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.1
            ))
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            heavyTap()
        }
    }
    
    /// 傾き変化時の滑らかなフィードバック
    func tiltFeedback(magnitude: Double) {
        guard magnitude > 0.3 else { return }
        
        let intensity = CGFloat(min(1.0, magnitude * 0.8))
        softGenerator.impactOccurred(intensity: intensity)
        softGenerator.prepare()
    }
    
    /// 形状変化時のフィードバック（円→曲線→多角形）
    func morphFeedback(shapeMode: Double) {
        guard supportsHaptics, let engine = engine else {
            selection()
            return
        }
        
        // 形状モードに応じてシャープネスを変化
        let sharpness = Float(0.2 + shapeMode * 0.6)  // 円は柔らか、多角形はシャープ
        
        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            selection()
        }
    }
    
    /// ピンチ時のスケールフィードバック
    func pinchFeedback(scale: Double) {
        let intensity = CGFloat(abs(scale - 1.0) * 2)
        if intensity > 0.1 {
            lightGenerator.impactOccurred(intensity: min(1.0, intensity))
            lightGenerator.prepare()
        }
    }
    
    /// パレット変更時のフィードバック
    func paletteChangeFeedback() {
        guard supportsHaptics, let engine = engine else {
            success()
            return
        }
        
        do {
            // 華やかなパターン
            var events: [CHHapticEvent] = []
            
            for i in 0..<4 {
                let time = Double(i) * 0.06
                let intensity = Float(1.0 - Double(i) * 0.2)
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: time
                ))
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            success()
        }
    }
    
    /// 対称数変更時のフィードバック
    func symmetryChangeFeedback(count: Int) {
        guard supportsHaptics, let engine = engine else {
            selection()
            return
        }
        
        do {
            // 対称数に応じた回数のタップ
            var events: [CHHapticEvent] = []
            let tapCount = min(count, 8)
            
            for i in 0..<tapCount {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: Double(i) * 0.03
                ))
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            selection()
        }
    }
    
    /// スクリーンショット保存時のフィードバック
    func screenshotFeedback() {
        guard supportsHaptics, let engine = engine else {
            success()
            return
        }
        
        do {
            // カメラシャッターのような感覚
            var events: [CHHapticEvent] = []
            
            // シャッター音的な瞬間
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            ))
            
            // 成功の確認
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.15
            ))
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            success()
        }
    }
    
    /// 連続的な振動（ドラッグ中など）
    func continuousVibration(intensity: Double, duration: TimeInterval = 0.1) {
        guard supportsHaptics, let engine = engine else { return }
        
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: duration
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // フォールバック不要（静かに失敗）
        }
    }
    
    // MARK: - レガシー互換
    
    func patternChange() {
        success()
    }
}
