import Foundation

/// パフォーマンス品質レベル
enum QualityLevel: Int, Comparable {
    case low = 0      // 省電力: 粒子少なめ、エフェクト最小
    case medium = 1   // バランス: 標準設定
    case high = 2     // 高品質: 粒子多め、全エフェクト
    case ultra = 3    // 最高品質: 粒子最大、全機能
    
    static func < (lhs: QualityLevel, rhs: QualityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var particleCountRange: ClosedRange<Int> {
        switch self {
        case .low: return 20...30
        case .medium: return 30...50
        case .high: return 50...80
        case .ultra: return 80...120
        }
    }
    
    var enableCollisionDetection: Bool {
        switch self {
        case .low: return false
        case .medium, .high, .ultra: return true
        }
    }
    
    var maxCollisionChecks: Int {
        switch self {
        case .low: return 0
        case .medium: return 3
        case .high: return 5
        case .ultra: return 8
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Low (Power Saver)"
        case .medium: return "Medium (Balanced)"
        case .high: return "High (Performance)"
        case .ultra: return "Ultra (Maximum)"
        }
    }
}

/// FPSとパフォーマンスを監視し、品質を適応的に調整
@Observable
class PerformanceMonitor {
    private(set) var currentFPS: Double = 120.0
    private(set) var averageFPS: Double = 120.0
    private(set) var currentQuality: QualityLevel = .medium
    
    private var fpsHistory: [Double] = []
    private let historySize = 60  // 1秒分のサンプル（60fps想定）
    private var lastUpdateTime: Date?
    
    private var timeSinceLastQualityChange: Double = 0.0
    private let qualityChangeMinInterval: Double = 5.0  // 最低5秒間は変更しない
    
    // ターゲットFPS閾値
    private let targetFPS: Double = 120.0
    private let goodFPSThreshold: Double = 115.0  // これ以上なら品質アップ検討
    private let acceptableFPSThreshold: Double = 100.0  // これ以上なら維持
    private let poorFPSThreshold: Double = 80.0   // これ以下なら品質ダウン
    
    // 品質変更のヒステリシス（頻繁な変更を防ぐ）
    private var consecutiveGoodFrames = 0
    private var consecutivePoorFrames = 0
    private let framesRequiredForChange = 120  // 2秒間安定したら変更
    
    init(initialQuality: QualityLevel = .medium) {
        self.currentQuality = initialQuality
    }
    
    /// フレームタイムを記録してFPSを計算
    func recordFrame(deltaTime: Double) {
        guard deltaTime > 0 && deltaTime < 1.0 else { return }
        
        let fps = 1.0 / deltaTime
        currentFPS = fps
        
        // 履歴に追加
        fpsHistory.append(fps)
        if fpsHistory.count > historySize {
            fpsHistory.removeFirst()
        }
        
        // 平均FPSを計算
        if !fpsHistory.isEmpty {
            averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
        }
        
        // 品質調整のタイミングチェック
        timeSinceLastQualityChange += deltaTime
        if timeSinceLastQualityChange >= qualityChangeMinInterval {
            evaluateQualityAdjustment()
        }
    }
    
    /// パフォーマンスに基づいて品質レベルを評価
    private func evaluateQualityAdjustment() {
        // 平均FPSが十分なサンプルを持っているか確認
        guard fpsHistory.count >= historySize / 2 else { return }
        
        if averageFPS >= goodFPSThreshold {
            // 良好なパフォーマンス - 品質アップを検討
            consecutiveGoodFrames += 1
            consecutivePoorFrames = 0
            
            if consecutiveGoodFrames >= framesRequiredForChange {
                if currentQuality < .ultra {
                    increaseQuality()
                }
                consecutiveGoodFrames = 0
            }
            
        } else if averageFPS < poorFPSThreshold {
            // 低パフォーマンス - 品質ダウンを検討
            consecutivePoorFrames += 1
            consecutiveGoodFrames = 0
            
            if consecutivePoorFrames >= framesRequiredForChange / 2 {  // より早く反応
                if currentQuality > .low {
                    decreaseQuality()
                }
                consecutivePoorFrames = 0
            }
            
        } else {
            // 許容範囲内 - カウンターリセット
            consecutiveGoodFrames = 0
            consecutivePoorFrames = 0
        }
    }
    
    /// 品質レベルを上げる
    private func increaseQuality() {
        let oldQuality = currentQuality
        
        switch currentQuality {
        case .low: currentQuality = .medium
        case .medium: currentQuality = .high
        case .high: currentQuality = .ultra
        case .ultra: return
        }
        
        print("📈 Quality increased: \(oldQuality.description) → \(currentQuality.description) (FPS: \(String(format: "%.1f", averageFPS)))")
        timeSinceLastQualityChange = 0.0
        fpsHistory.removeAll()  // 履歴をリセット
    }
    
    /// 品質レベルを下げる
    private func decreaseQuality() {
        let oldQuality = currentQuality
        
        switch currentQuality {
        case .low: return
        case .medium: currentQuality = .low
        case .high: currentQuality = .medium
        case .ultra: currentQuality = .high
        }
        
        print("📉 Quality decreased: \(oldQuality.description) → \(currentQuality.description) (FPS: \(String(format: "%.1f", averageFPS)))")
        timeSinceLastQualityChange = 0.0
        fpsHistory.removeAll()  // 履歴をリセット
    }
    
    /// 手動で品質を設定（ユーザー設定用）
    func setQuality(_ quality: QualityLevel) {
        let oldQuality = currentQuality
        currentQuality = quality
        print("⚙️ Quality manually set: \(oldQuality.description) → \(quality.description)")
        
        // カウンターとタイマーをリセット
        consecutiveGoodFrames = 0
        consecutivePoorFrames = 0
        timeSinceLastQualityChange = 0.0
        fpsHistory.removeAll()
    }
    
    /// 統計情報を取得
    func getStats() -> String {
        let minFPS = fpsHistory.min() ?? 0
        let maxFPS = fpsHistory.max() ?? 0
        
        return """
        Quality: \(currentQuality.description)
        Current FPS: \(String(format: "%.1f", currentFPS))
        Average FPS: \(String(format: "%.1f", averageFPS))
        Min/Max FPS: \(String(format: "%.1f", minFPS)) / \(String(format: "%.1f", maxFPS))
        """
    }
}
