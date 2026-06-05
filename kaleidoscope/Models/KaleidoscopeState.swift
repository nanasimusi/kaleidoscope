import SwiftUI
import Foundation

enum ElementType: CaseIterable {
    case circle      // 発光する球体
    case curve       // 流れる曲線
    case nebula      // 星雲のようなぼんやりした形
    case tendril     // 触手・蔓のような有機的な形
    case droplet     // 水滴・しずく形
    case petal       // 花びら形
    
    // 線形パターン（大幅に増加）
    case spiral      // 螺旋
    case wave        // 波形
    case zigzag      // ジグザグ
    case dash        // ダッシュ（短線）
    case arc         // 弧
    
    // 新しい線形パターンを追加
    case doubleLine  // 二重線
    case tripleLine  // 三重線
    case brokenLine  // 破線
    case wavyLine    // 波線
    case coil        // コイル・バネ
    case lightning   // 稲妻・雷
    case vine        // 蔓・つる
    case ribbon      // リボン
    case thread      // 糸
    case fiber       // 繊維
    case streak      // 筋・ストリーク
    case beam        // ビーム・光線
    case trail       // 軌跡
    case whip        // 鞭・ムチ
    case lasso       // 投げ縄
    case snake       // 蛇行線
    case helix       // 二重螺旋
    case braid       // 編み込み
    case chain       // 鎖
    case rope        // ロープ
    
    // 点・形系（少なめ）
    case ring        // リング
    case star        // 星形（小さな点）
    case crescent    // 三日月
    case diamond     // ダイヤモンド形
    case triangle    // 三角形
    case square      // 四角形
    case cross       // 十字
    case dot         // 微小な点
    case ellipse     // 楕円
    case hexagon     // 六角形
}

struct SeedElement: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var rotation: Angle
    var type: ElementType
    var velocity: CGPoint
    var rotationSpeed: Double
    var sizeOscillation: Double
    var phaseOffset: Double
    var colorIndex: Int
    var depth: Double
    var energy: Double = 0
    var targetPosition: CGPoint?
    var morphProgress: Double = 1.0
    
    // 生き物としての個性と知性
    var personality: Double  // 0.0-1.0: 内向的 <-> 外向的
    var curiosity: Double    // 0.0-1.0: 探索への興味
    var sociability: Double  // 0.0-1.0: 他の粒子への親和性
    var mood: Double = 0.5   // 0.0-1.0: 静か <-> 活発
    var awareness: Double = 0.0  // 周囲への気づき
    
    // 群れ行動（Boids）用
    var flockAlignment: Double = 0.0     // 周囲の粒子と同じ方向に進む
    var flockCohesion: Double = 0.0      // 群れの中心に向かう
    var flockSeparation: Double = 0.0    // 近すぎる粒子から離れる
    
    // 相互作用の履歴
    var lastInteractionTime: Double = 0.0
    var interactionCount: Int = 0
    
    // 軌跡（トレイル）用の位置履歴
    var trail: [CGPoint] = []
    let maxTrailLength = 8  // 軌跡の最大長
    
    // Metal互換の便利プロパティ
    var x: Double {
        get { Double(position.x) }
        set { position.x = CGFloat(newValue) }
    }
    var y: Double {
        get { Double(position.y) }
        set { position.y = CGFloat(newValue) }
    }
    var vx: Double {
        get { Double(velocity.x) }
        set { velocity.x = CGFloat(newValue) }
    }
    var vy: Double {
        get { Double(velocity.y) }
        set { velocity.y = CGFloat(newValue) }
    }
    
    static func random(colors: [Color], colorIndex: Int, depth: Double) -> SeedElement {
        // 線形パターンを大量に - 流れるような芸術体験
        let types: [ElementType] = [
            // 基本線形（多め）
            .curve, .curve, .curve, .curve, .curve,
            .tendril, .tendril, .tendril, .tendril,
            .wave, .wave, .wave,
            .spiral, .spiral, .spiral,
            .arc, .arc, .arc,
            .zigzag, .zigzag,
            .dash, .dash,
            
            // 新しい線形パターン（豊富に）
            .doubleLine, .doubleLine,
            .tripleLine, .tripleLine,
            .brokenLine, .brokenLine,
            .wavyLine, .wavyLine,
            .coil, .coil,
            .lightning, .lightning,
            .vine, .vine, .vine,
            .ribbon, .ribbon,
            .thread, .thread,
            .fiber, .fiber,
            .streak, .streak, .streak,
            .beam, .beam,
            .trail, .trail,
            .whip, .whip,
            .lasso,
            .snake, .snake,
            .helix, .helix,
            .braid,
            .chain,
            .rope,
            
            // 点系（少なめ）
            .circle,
            .dot, .dot,
            .star,
            
            // 形系（最小限）
            .droplet,
            .petal,
            .crescent,
            .diamond,
            .triangle,
            .square,
            .cross,
            .ellipse,
            .hexagon,
            .ring,
            .nebula
        ]
        
        // 多様なサイズバリエーション（飽きさせない）
        let sizeCategory = Int.random(in: 0...4)
        let sizeVariation: CGFloat
        switch sizeCategory {
        case 0: sizeVariation = CGFloat.random(in: 0.0008...0.003)  // 極小
        case 1: sizeVariation = CGFloat.random(in: 0.002...0.008)   // 小
        case 2: sizeVariation = CGFloat.random(in: 0.005...0.015)   // 中
        case 3: sizeVariation = CGFloat.random(in: 0.010...0.025)   // 大
        default: sizeVariation = CGFloat.random(in: 0.015...0.040)  // 極大
        }
        
        // 各粒子に個性を付与（生き物のように）
        let personality = Double.random(in: 0...1)
        let curiosity = Double.random(in: 0...1)
        let sociability = Double.random(in: 0...1)
        
        // 個性に基づいた初期速度 + ランダムな振る舞い
        let speedFactor = Double.random(in: 0.3...1.5)  // より広い範囲でランダム
        let isErratic = Bool.random()  // 一部の粒子は不規則な動き
        
        // 色のバリエーション（基本色から少しずらす）
        let baseColor = colors[colorIndex % colors.count]
        let colorVariation = Double.random(in: -0.15...0.15)
        let brightnessVariation = Double.random(in: 0.7...1.3)
        
        // 極端な個性を持つ粒子を時々生成（予測不可能性）
        let isExtreme = Double.random(in: 0...1) > 0.85
        
        return SeedElement(
            position: CGPoint(
                x: CGFloat.random(in: 0.02...0.98),
                y: CGFloat.random(in: 0.02...0.98)
            ),
            size: sizeVariation,
            color: baseColor.opacity(Double.random(in: 0.5...1.0)),
            rotation: Angle(degrees: Double.random(in: 0...360)),
            type: types.randomElement()!,
            velocity: CGPoint(
                x: CGFloat.random(in: -0.004...0.004) * speedFactor,
                y: CGFloat.random(in: -0.004...0.004) * speedFactor
            ),
            rotationSpeed: Double.random(in: -6.0...6.0) * (isErratic ? 2.0 : 1.0),
            sizeOscillation: Double.random(in: 0.1...0.6),
            phaseOffset: Double.random(in: 0...Double.pi * 4),  // より広い位相
            colorIndex: colorIndex,
            depth: depth,
            personality: isExtreme ? (Bool.random() ? 0.0 : 1.0) : personality,
            curiosity: isExtreme ? Double.random(in: 0.8...1.0) : curiosity,
            sociability: sociability,
            mood: Double.random(in: 0.2...0.8)
        )
    }
}

struct TapRipple: Identifiable {
    let id = UUID()
    var position: CGPoint
    var normalizedPosition: CGPoint
    var startTime: Double
    var color: Color
    var intensity: Double = 1.0
}

@Observable
final class KaleidoscopeState {
    var symmetryCount: Int = 8
    var targetSymmetryCount: Int = 8
    var symmetryTransitionProgress: Double = 1.0  // 0-1: 対称性の遷移
    var symmetryBreaking: Double = 0.0  // 0-1: 対称性の崩壊度
    
    var seedElements: [SeedElement] = []
    var animationPhase: Double = 0
    var touchOffset: CGPoint = .zero
    var smoothTouchOffset: CGPoint = .zero
    var targetPaletteColors: [Color] = []
    var currentPaletteColors: [Color] = []
    var colorTransitionProgress: Double = 1.0
    var globalRotation: Double = 0
    var targetGlobalRotation: Double = 0
    var tapRipples: [TapRipple] = []
    var timeSinceLastEvolution: Double = 0
    var evolutionInterval: Double = 15.0
    var isTransitioning: Bool = false
    var transitionProgress: Double = 0
    var pendingElements: [SeedElement] = []
    
    // Motion/Shake detection
    var motionIntensity: Double = 0
    var motionDirection: CGPoint = .zero
    var shakeEnergy: Double = 0
    
    // Device tilt detection
    var deviceTilt: CGPoint = .zero  // X: roll (左右), Y: pitch (前後)
    var smoothTilt: CGPoint = .zero  // スムーズ補間された傾き
    
    // Kinetic energy system - controls overall animation speed
    var kineticEnergy: Double = 1.0  // 1.0 = full speed, 0.0 = stopped
    var rotationVelocity: Double = 0.02  // Current rotation speed
    var isResting: Bool = false  // True when fully stopped
    
    // 自動パレット切り替え
    var timeSinceLastPaletteChange: Double = 0.0
    var paletteChangeInterval: Double = Double.random(in: 8...15)  // ランダムな間隔で切り替え
    
    // 生成アルゴリズムの自動切り替え
    var currentGenerationAlgorithm: GenerationAlgorithm = .random
    var timeSinceLastAlgorithmChange: Double = 0.0
    var algorithmChangeInterval: Double = Double.random(in: 20...40)  // パレットよりも長い間隔
    
    // 対称性の自動変化
    var timeSinceLastSymmetryChange: Double = 0.0
    var symmetryChangeInterval: Double = Double.random(in: 15...30)
    
    // 対称性の崩壊エフェクト
    var symmetryBreakingActive: Bool = false
    var symmetryBreakingDuration: Double = 0.0
    
    // Metal GPU acceleration
    private var metalEngine: MetalParticleEngine?
    private var useMetal: Bool = false
    
    // 適応的パフォーマンス管理
    private(set) var performanceMonitor = PerformanceMonitor()
    private var lastQuality: QualityLevel = .medium
    
    init() {
        // ランダムなパレットで開始
        let randomPalette = ColorPalette.allCases.randomElement()!
        targetPaletteColors = randomPalette.colors
        currentPaletteColors = randomPalette.colors
        randomize(with: randomPalette.colors)
        
        // Metal engineを初期化
        if let engine = MetalParticleEngine() {
            metalEngine = engine
            useMetal = true
            print("✅ Metal GPU acceleration enabled")
        } else {
            print("⚠️ Metal not available, using CPU fallback")
        }
    }
    
    func randomize(with colors: [Color]) {
        // 品質レベルに応じた粒子数
        let quality = performanceMonitor.currentQuality
        let elementCount = Int.random(in: quality.particleCountRange)
        
        seedElements = currentGenerationAlgorithm.generate(count: elementCount, colors: colors)
        
        // Metal bufferを初期化
        if useMetal {
            metalEngine?.initializeParticles(count: seedElements.count)
        }
    }
    
    func addTapRipple(at position: CGPoint, normalizedPosition: CGPoint) {
        let color = currentPaletteColors.randomElement() ?? .white
        let ripple = TapRipple(
            position: position,
            normalizedPosition: normalizedPosition,
            startTime: animationPhase,
            color: color
        )
        tapRipples.append(ripple)
        
        // === TAP ALSO INJECTS ENERGY ===
        // Tapping wakes up the kaleidoscope too!
        kineticEnergy = min(1.0, kineticEnergy + 0.15)
        rotationVelocity = min(0.03, rotationVelocity + 0.005)
        isResting = false
        
        for i in seedElements.indices {
            let dx = seedElements[i].position.x - normalizedPosition.x
            let dy = seedElements[i].position.y - normalizedPosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < 0.6 {
                let normalizedDist = distance / 0.6
                let falloff = 1.0 - easeOutQuad(normalizedDist)
                let force = falloff * 0.08
                
                let angle = atan2(dy, dx)
                seedElements[i].velocity.x += Foundation.cos(angle) * force
                seedElements[i].velocity.y += Foundation.sin(angle) * force
                seedElements[i].energy = min(1.0, seedElements[i].energy + falloff * 1.5)
                seedElements[i].rotationSpeed += Double.random(in: -10...10) * falloff
            }
        }
        
        if tapRipples.count > 6 {
            tapRipples.removeFirst()
        }
    }
    
    private func easeOutQuad(_ t: Double) -> Double {
        return 1.0 - (1.0 - t) * (1.0 - t)
    }
    
    func evolve(deltaTime: Double) {
        let smoothDelta = min(deltaTime, 0.033)
        
        // === PERFORMANCE MONITORING ===
        performanceMonitor.recordFrame(deltaTime: deltaTime)
        
        // 品質が変更されたら粒子を再生成
        if performanceMonitor.currentQuality != lastQuality {
            lastQuality = performanceMonitor.currentQuality
            randomize(with: currentPaletteColors)
        }
        
        // === KINETIC ENERGY DECAY SYSTEM ===
        // Gradually slow down over time (like a spinning top) - 極めて緩やかに
        let decayRate = 0.008  // さらに遅い減衰で永続的な滑らかさ
        kineticEnergy *= (1.0 - decayRate * smoothDelta * 60)
        
        // Clamp to minimum threshold
        if kineticEnergy < 0.001 {
            kineticEnergy = 0
            isResting = true
        } else {
            isResting = false
        }
        
        // Rotation velocity also decays - より緩やかに
        rotationVelocity *= (1.0 - decayRate * 0.5 * smoothDelta * 60)
        if rotationVelocity < 0.0005 {
            rotationVelocity = 0
        }
        
        // Apply kinetic energy to animation speed
        let effectiveEnergy = kineticEnergy * kineticEnergy  // Quadratic for smoother stop
        
        // Animation phase advances based on kinetic energy - より繊細な速度
        let basePhaseSpeed = 0.25 + Foundation.sin(animationPhase * 0.08) * 0.04
        animationPhase += smoothDelta * basePhaseSpeed * effectiveEnergy
        
        // Rotation with energy-based speed - 極めて滑らかな回転
        let breathCycle = Foundation.sin(animationPhase * 0.12) * 0.006
        targetGlobalRotation += smoothDelta * rotationVelocity * effectiveEnergy * 0.75
        
        // Critically damped spring for rotation - より滑らかに
        let omega = 2.5
        let rotationDiff = targetGlobalRotation - globalRotation
        let springForce = omega * omega * rotationDiff
        globalRotation += springForce * smoothDelta * (0.4 + effectiveEnergy * 0.6)
        
        // Exponential smoothing for touch
        let touchDecay = exp(-8.0 * smoothDelta)
        smoothTouchOffset.x = touchOffset.x + (smoothTouchOffset.x - touchOffset.x) * touchDecay
        smoothTouchOffset.y = touchOffset.y + (smoothTouchOffset.y - touchOffset.y) * touchDecay
        
        // Exponential smoothing for device tilt (極めて滑らかに)
        let tiltDecay = exp(-3.5 * smoothDelta)
        smoothTilt.x = deviceTilt.x + (smoothTilt.x - deviceTilt.x) * tiltDecay
        smoothTilt.y = deviceTilt.y + (smoothTilt.y - deviceTilt.y) * tiltDecay
        
        // Only evolve patterns when there's enough energy
        if kineticEnergy > 0.3 {
            timeSinceLastEvolution += smoothDelta * effectiveEnergy
            if timeSinceLastEvolution >= evolutionInterval && !isTransitioning {
                startEvolution()
            }
        }
        
        if isTransitioning {
            transitionProgress += smoothDelta * 0.2 * max(0.5, effectiveEnergy)
            if transitionProgress >= 1.0 {
                completeEvolution()
            } else {
                updateTransition()
            }
        }
        
        if colorTransitionProgress < 1.0 {
            colorTransitionProgress = min(1.0, colorTransitionProgress + smoothDelta * 0.6)
            updateElementColors()
        }
        
        tapRipples.removeAll { animationPhase - $0.startTime > 5.0 }
        
        // 自動パレット切り替え - ランダムな間隔で
        timeSinceLastPaletteChange += smoothDelta
        if timeSinceLastPaletteChange >= paletteChangeInterval {
            // ランダムな新しいパレットに切り替え
            let allPalettes = ColorPalette.allCases
            let newPalette = allPalettes.randomElement()!
            targetPaletteColors = newPalette.colors
            colorTransitionProgress = 0.0
            
            // 次回の切り替え間隔もランダムに
            paletteChangeInterval = Double.random(in: 8...15)
            timeSinceLastPaletteChange = 0.0
        }
        
        // 自動アルゴリズム切り替え - より長い間隔で
        timeSinceLastAlgorithmChange += smoothDelta
        if timeSinceLastAlgorithmChange >= algorithmChangeInterval {
            // ランダムな新しいアルゴリズムに切り替え
            let allAlgorithms = GenerationAlgorithm.allCases
            let newAlgorithm = allAlgorithms.randomElement()!
            
            if newAlgorithm != currentGenerationAlgorithm {
                currentGenerationAlgorithm = newAlgorithm
                print("🎨 Generation algorithm changed to: \(newAlgorithm.name)")
                
                // 新しいアルゴリズムで粒子を再生成
                randomize(with: currentPaletteColors)
            }
            
            // 次回の切り替え間隔もランダムに
            algorithmChangeInterval = Double.random(in: 20...40)
            timeSinceLastAlgorithmChange = 0.0
        }
        
        // 自動対称性変更 - ランダムな対称性で視覚的多様性
        timeSinceLastSymmetryChange += smoothDelta
        if timeSinceLastSymmetryChange >= symmetryChangeInterval {
            // 対称性の種類: 3, 4, 5, 6, 8, 10, 12, 16
            let symmetries = [3, 4, 5, 6, 8, 10, 12, 16]
            let newSymmetry = symmetries.randomElement()!
            
            if newSymmetry != targetSymmetryCount {
                targetSymmetryCount = newSymmetry
                symmetryTransitionProgress = 0.0
                print("✨ Symmetry changing to: \(newSymmetry)")
                
                // 10%の確率で対称性崩壊エフェクト
                if Double.random(in: 0...1) < 0.1 {
                    symmetryBreakingActive = true
                    symmetryBreakingDuration = 0.0
                    print("💥 Symmetry breaking activated!")
                }
            }
            
            // 次回の切り替え間隔
            symmetryChangeInterval = Double.random(in: 15...30)
            timeSinceLastSymmetryChange = 0.0
        }
        
        // 対称性の遷移をスムーズに
        if symmetryTransitionProgress < 1.0 {
            symmetryTransitionProgress = min(1.0, symmetryTransitionProgress + smoothDelta * 0.3)
            
            // イージング（スムーズな遷移）
            let eased = 1.0 - pow(1.0 - symmetryTransitionProgress, 3.0)
            let interpolated = Double(symmetryCount) * (1.0 - eased) + Double(targetSymmetryCount) * eased
            
            // 遷移完了時に正確な値に設定
            if symmetryTransitionProgress >= 1.0 {
                symmetryCount = targetSymmetryCount
            }
        }
        
        // 対称性崩壊エフェクト
        if symmetryBreakingActive {
            symmetryBreakingDuration += smoothDelta
            
            // 0→1→0 の山型カーブ
            let breakProgress = min(1.0, symmetryBreakingDuration / 3.0)
            if breakProgress < 0.5 {
                symmetryBreaking = breakProgress * 2.0  // 0→1
            } else {
                symmetryBreaking = 2.0 - breakProgress * 2.0  // 1→0
            }
            
            // 3秒後に終了
            if symmetryBreakingDuration >= 3.0 {
                symmetryBreakingActive = false
                symmetryBreaking = 0.0
            }
        }
        
        // === GPU ACCELERATION WITH METAL ===
        if useMetal, let engine = metalEngine {
            // Metal GPUで物理演算を実行
            engine.updateParticleData(from: seedElements)
            
            engine.simulate(
                particleCount: seedElements.count,
                deltaTime: smoothDelta,
                phase: animationPhase,
                touchX: 0.5,  // 正規化された座標
                touchY: 0.5,
                touchOffsetX: smoothTouchOffset.x,
                touchOffsetY: smoothTouchOffset.y,
                tiltX: smoothTilt.x,
                tiltY: smoothTilt.y,
                kineticEnergy: effectiveEnergy
            )
            
            engine.readParticleData(to: &seedElements)
            
            // 色とサイズのアニメーションはCPUで（軽量）
            for i in seedElements.indices {
                var element = seedElements[i]
                let phase = animationPhase + element.phaseOffset
                
                // 回転は既にMetalで計算済み
                
                // タッチによる視差効果
                let depthFactor = 1.0 - element.depth * 0.6
                let touchInfluence = 0.08 * depthFactor * depthFactor
                element.position.x += smoothTouchOffset.x * touchInfluence * smoothDelta
                element.position.y += smoothTouchOffset.y * touchInfluence * smoothDelta
                
                seedElements[i] = element
            }
        } else {
            // CPU版のフォールバック（元のコード）
            for i in seedElements.indices {
                var element = seedElements[i]
            
            // Energy decay with kinetic influence - より緩やかに
            let energyDecay = exp(-1.5 * smoothDelta)
            element.energy *= energyDecay
            if element.energy < 0.001 { element.energy = 0 }
            
            let phase = animationPhase + element.phaseOffset
            let energyBoost = 1.0 + element.energy * 1.5
            
            // === 予測不可能な有機的な動き ===
            
            // 個性に基づく動きの多様性
            let baseSpeed = 0.0015 * effectiveEnergy * energyBoost
            let personalityInfluence = element.personality * 2.0 + 0.5  // 0.5-2.5の範囲
            
            // パーリンノイズ風の複雑な動き
            let noiseX1 = Foundation.sin(phase * 1.3 + element.phaseOffset) * Foundation.cos(phase * 0.7 + element.personality * 10)
            let noiseX2 = Foundation.sin(phase * 2.1 - element.phaseOffset * 0.5) * Foundation.cos(phase * 1.9 + element.curiosity * 15)
            let noiseX3 = Foundation.sin(phase * 0.5 + element.sociability * 8) * Foundation.cos(phase * 3.2 - element.phaseOffset)
            
            let noiseY1 = Foundation.cos(phase * 1.5 - element.phaseOffset) * Foundation.sin(phase * 0.9 + element.personality * 12)
            let noiseY2 = Foundation.cos(phase * 1.8 + element.phaseOffset * 0.7) * Foundation.sin(phase * 2.3 - element.curiosity * 18)
            let noiseY3 = Foundation.cos(phase * 0.7 - element.sociability * 9) * Foundation.sin(phase * 2.9 + element.phaseOffset)
            
            // レヴィフライト（突発的な大きな移動）
            let levyFlight = Foundation.sin(phase * 0.3 + element.phaseOffset * 3.0)
            let isJumping = levyFlight > 0.95  // 5%の確率で大ジャンプ
            let jumpMultiplier = isJumping ? 5.0 : 1.0
            
            // フラクタルノイズ（複数スケールの重ね合わせ）
            var flowX = (noiseX1 * 0.4 + noiseX2 * 0.3 + noiseX3 * 0.3) * baseSpeed * personalityInfluence * jumpMultiplier
            var flowY = (noiseY1 * 0.4 + noiseY2 * 0.3 + noiseY3 * 0.3) * baseSpeed * personalityInfluence * jumpMultiplier
            
            // 探索行動（好奇心が高い粒子はより遠くへ）
            if element.curiosity > 0.6 {
                let exploreAngle = phase * element.curiosity * 2.0 + element.phaseOffset
                let exploreRadius = Foundation.sin(phase * 0.4 + element.curiosity * 5.0) * 0.002
                flowX += Foundation.cos(exploreAngle) * exploreRadius * element.curiosity
                flowY += Foundation.sin(exploreAngle) * exploreRadius * element.curiosity
            }
            
            // 内向的な粒子は時々静止する
            if element.personality < 0.3 {
                let pauseProbability = Foundation.sin(phase * 0.8 + element.phaseOffset * 2.0)
                if pauseProbability > 0.7 {
                    flowX *= 0.1
                    flowY *= 0.1
                }
            }
            
            // カオス的な突発的方向転換
            let suddenTurn = Foundation.sin(phase * 5.7 + element.phaseOffset * 3.3) * 
                           Foundation.cos(phase * 4.1 - element.phaseOffset * 2.1)
            if suddenTurn > 0.9 {
                let turnAngle = Double.random(in: 0...(2 * Double.pi))
                let turnStrength = 0.003 * element.mood
                flowX += Foundation.cos(turnAngle) * turnStrength
                flowY += Foundation.sin(turnAngle) * turnStrength
            }
            
            // デバイス傾きによる重力効果（目に見える自然な影響）
            // 深度によって傾きへの反応性を変える（奥のものほど遅く動く）
            let tiltResponsiveness = (1.0 - element.depth * 0.3) * effectiveEnergy
            let tiltStrength = 0.025 * tiltResponsiveness  // より明確な影響
            
            // 傾きに基づく重力的な力を加える（重力のように働く）
            flowX += smoothTilt.x * tiltStrength * energyBoost
            flowY += smoothTilt.y * tiltStrength * energyBoost
            
            // === 磁場のような力場エフェクト ===
            // タッチ位置を中心とした渦巻き磁場
            let touchCenterX = 0.5 + smoothTouchOffset.x * 0.1
            let touchCenterY = 0.5 + smoothTouchOffset.y * 0.1
            let toTouchX = touchCenterX - element.position.x
            let toTouchY = touchCenterY - element.position.y
            let distanceToTouch = sqrt(toTouchX * toTouchX + toTouchY * toTouchY)
            
            if distanceToTouch > 0.01 {
                // 渦巻き力（右回り）
                let vortexAngle = atan2(toTouchY, toTouchX) + Double.pi / 2
                let vortexStrength = (1.0 / (distanceToTouch + 0.1)) * 0.0008 * element.curiosity
                flowX += Foundation.cos(vortexAngle) * vortexStrength
                flowY += Foundation.sin(vortexAngle) * vortexStrength
                
                // 引力/斥力（タッチ時のエネルギーに応じて）
                let magneticStrength = Foundation.sin(animationPhase * 0.5) * 0.0005
                flowX += toTouchX * magneticStrength
                flowY += toTouchY * magneticStrength
            }
            
            // 画面中心からの放射状の力（呼吸するように）
            let toCenterX = 0.5 - element.position.x
            let toCenterY = 0.5 - element.position.y
            let distanceFromCenter = sqrt(toCenterX * toCenterX + toCenterY * toCenterY)
            let breathe = Foundation.sin(animationPhase * 0.3 + element.phaseOffset) * 0.0002
            flowX += toCenterX * breathe
            flowY += toCenterY * breathe
            
            // === 生き物としての知性と感情に基づく動き ===
            
            // 気分の変化（ランダムウォーク）
            element.mood += (Double.random(in: -0.02...0.02) * element.personality)
            element.mood = max(0.0, min(1.0, element.mood))
            
            // 周囲の粒子を感知（sociabilityが高いほど広範囲）+ 衝突反発
            var nearbyCount = 0
            var attractionX: Double = 0
            var attractionY: Double = 0
            var collisionForceX: Double = 0
            var collisionForceY: Double = 0
            let awarenessRadius = 0.15 * element.sociability
            
            // Boids群れ行動用
            var avgVelocityX: Double = 0  // Alignment: 周囲の平均速度
            var avgVelocityY: Double = 0
            var centerOfMassX: Double = 0  // Cohesion: 群れの中心
            var centerOfMassY: Double = 0
            var separationX: Double = 0    // Separation: 近すぎる粒子から離れる
            var separationY: Double = 0
            
            // 品質に応じた衝突検出
            var checkedCount = 0
            let maxChecks = performanceMonitor.currentQuality.maxCollisionChecks
            let enableCollision = performanceMonitor.currentQuality.enableCollisionDetection
            
            // 衝突検出が有効な場合のみ実行
            if enableCollision {
                for j in seedElements.indices where j != i && checkedCount < maxChecks {
                let other = seedElements[j]
                let dx = other.position.x - element.position.x
                let dy = other.position.y - element.position.y
                let distanceSq = dx * dx + dy * dy
                
                // 衝突判定（距離の二乗で高速化）- より大きく強い反発
                let collisionRadius = 0.08  // 衝突判定の半径を大きく
                let collisionRadiusSq = collisionRadius * collisionRadius
                
                if distanceSq < collisionRadiusSq && distanceSq > 0.0001 {
                    // 衝突している - ランダムな反発力を適用（予測不可能な動き）
                    let distance = sqrt(distanceSq)
                    let overlap = collisionRadius - distance
                    let baseRepulsion = overlap * 1.2  // 反発力を強く
                    
                    // ランダムな反発角度でカオス的な動きを生成
                    let randomAngle = Double.random(in: -0.3...0.3)
                    let angle = atan2(dy, dx) + randomAngle
                    
                    collisionForceX -= Foundation.cos(angle) * baseRepulsion
                    collisionForceY -= Foundation.sin(angle) * baseRepulsion
                    
                    // 衝突時にエネルギーとランダムな回転を付与
                    seedElements[i].energy = min(1.0, element.energy + 0.3)
                    seedElements[i].rotationSpeed += Double.random(in: -8...8)
                    
                    checkedCount += 1
                } else if distanceSq < awarenessRadius * awarenessRadius && distanceSq > 0.001 {
                    // 近くにいるが衝突していない - 通常の相互作用
                    let distance = sqrt(distanceSq)
                    nearbyCount += 1
                    
                    // 社交的な粒子は他の粒子に惹かれる
                    let attraction = element.sociability * 0.0008 / distance
                    attractionX += dx * attraction
                    attractionY += dy * attraction
                    
                    // 好奇心の強い粒子はランダムに探索
                    if element.curiosity > 0.7 {
                        let randomExplore = element.curiosity * 0.0002
                        attractionX += Foundation.cos(phase * 3.0 + element.phaseOffset) * randomExplore
                        attractionY += Foundation.sin(phase * 3.0 + element.phaseOffset) * randomExplore
                    }
                    
                    // === Boids群れ行動の情報収集 ===
                    // Alignment: 周囲の粒子の速度を集計
                    avgVelocityX += other.velocity.x
                    avgVelocityY += other.velocity.y
                    
                    // Cohesion: 群れの中心位置を計算
                    centerOfMassX += other.position.x
                    centerOfMassY += other.position.y
                    
                    // Separation: 近すぎる粒子からの反発
                    if distanceSq < 0.01 {  // 非常に近い
                        let separationStrength = (0.01 - distanceSq) * 10.0
                        separationX -= dx * separationStrength
                        separationY -= dy * separationStrength
                    }
                    
                    checkedCount += 1
                }
                }
            }
            
            // === Boids群れ行動の力を計算 ===
            if nearbyCount > 0 {
                // Alignment: 周囲の平均速度に合わせる
                avgVelocityX /= Double(nearbyCount)
                avgVelocityY /= Double(nearbyCount)
                let alignmentStrength = element.sociability * 0.05
                element.flockAlignment = alignmentStrength
                flowX += (avgVelocityX - element.velocity.x) * alignmentStrength
                flowY += (avgVelocityY - element.velocity.y) * alignmentStrength
                
                // Cohesion: 群れの中心に向かう
                centerOfMassX /= Double(nearbyCount)
                centerOfMassY /= Double(nearbyCount)
                let cohesionStrength = element.sociability * 0.0003
                element.flockCohesion = cohesionStrength
                flowX += (centerOfMassX - element.position.x) * cohesionStrength
                flowY += (centerOfMassY - element.position.y) * cohesionStrength
                
                // Separation: 近すぎる粒子から離れる
                let separationStrength = element.personality * 0.02  // 外向的な粒子はパーソナルスペース大
                element.flockSeparation = separationStrength
                flowX += separationX * separationStrength
                flowY += separationY * separationStrength
            }
            
            // 衝突力を速度に追加
            element.velocity.x += collisionForceX
            element.velocity.y += collisionForceY
            
            element.awareness = Double(nearbyCount) / 10.0
            
            // 相互作用の記録
            if nearbyCount > 0 {
                seedElements[i].lastInteractionTime = animationPhase
                seedElements[i].interactionCount += nearbyCount
            }
            
            // 個性に基づく速度調整
            let personalityFactor = 0.7 + element.personality * 0.6
            let moodFactor = 0.5 + element.mood * 0.5
            
            flowX += attractionX * personalityFactor * moodFactor
            flowY += attractionY * personalityFactor * moodFactor
            
            // 内向的な粒子は時々立ち止まる
            if element.personality < 0.3 && Foundation.sin(phase * 2.0 + element.phaseOffset) > 0.9 {
                flowX *= 0.1
                flowY *= 0.1
            }
            
            // より滑らかで自然な速度減衰（生物の動きのように）
            let velocityDecayRate = 2.2 + (1.0 - effectiveEnergy) * 2.8
            let velocityDecay = exp(-velocityDecayRate * smoothDelta)
            element.velocity.x *= velocityDecay
            element.velocity.y *= velocityDecay
            
            // 極めて滑らかな位置統合（慣性を保ち、カクつきを完全に排除）
            let responsiveness = (0.96 - element.depth * 0.08) * effectiveEnergy
            let positionDecay = exp(-3.5 * smoothDelta * max(0.2, responsiveness))
            
            let targetX = element.position.x + (element.velocity.x + flowX) * 20
            let targetY = element.position.y + (element.velocity.y + flowY) * 20
            
            // 位置更新前にトレイルを記録
            seedElements[i].trail.append(element.position)
            if seedElements[i].trail.count > element.maxTrailLength {
                seedElements[i].trail.removeFirst()
            }
            
            element.position.x = targetX + (element.position.x - targetX) * positionDecay
            element.position.y = targetY + (element.position.y - targetY) * positionDecay
            
            // Parallax touch influence based on depth
            let depthFactor = 1.0 - element.depth * 0.6
            let touchInfluence = 0.08 * depthFactor * depthFactor
            element.position.x += smoothTouchOffset.x * touchInfluence * smoothDelta
            element.position.y += smoothTouchOffset.y * touchInfluence * smoothDelta
            
            // Soft boundary with elastic response
            let boundary: Double = 0.05
            let softness: Double = 0.15
            
            if element.position.x < boundary {
                let penetration = boundary - element.position.x
                element.velocity.x += penetration * softness
                element.position.x += penetration * 0.1
            } else if element.position.x > 1.0 - boundary {
                let penetration = element.position.x - (1.0 - boundary)
                element.velocity.x -= penetration * softness
                element.position.x -= penetration * 0.1
            }
            
            if element.position.y < boundary {
                let penetration = boundary - element.position.y
                element.velocity.y += penetration * softness
                element.position.y += penetration * 0.1
            } else if element.position.y > 1.0 - boundary {
                let penetration = element.position.y - (1.0 - boundary)
                element.velocity.y -= penetration * softness
                element.position.y -= penetration * 0.1
            }
            
            // 生命のような有機的な回転（呼吸するように）- より滑らかに
            let rotationDecay = exp(-1.4 * smoothDelta)
            element.rotationSpeed *= rotationDecay
            
            // 複数の周波数を組み合わせた自然な回転変動（個性を反映）
            let rotationIntensity = 0.5 + element.mood * 0.5 + element.personality * 0.3
            var baseRotation = (Foundation.sin(phase * 0.28 + element.phaseOffset) * 0.42 +
                               Foundation.cos(phase * 0.17 + element.phaseOffset * 1.3) * 0.28 +
                               Foundation.sin(phase * 0.35 + element.phaseOffset * 0.7) * 0.18) * rotationIntensity
            
            // 好奇心の強い粒子はより活発に回転
            if element.curiosity > 0.6 {
                baseRotation += Foundation.sin(phase * 1.5 + element.phaseOffset) * 0.15 * element.curiosity
            }
            
            // 傾きによる回転への影響（左右の傾きで回転速度が変化）
            let tiltRotationInfluence = smoothTilt.x * 0.35 * (1.0 - element.depth * 0.25)
            baseRotation += tiltRotationInfluence
            
            element.rotation += Angle(degrees: (element.rotationSpeed + baseRotation) * smoothDelta * 45 * rotationIntensity)
            
            seedElements[i] = element
            }
        }
    }
    
    private func startEvolution() {
        isTransitioning = true
        transitionProgress = 0
        timeSinceLastEvolution = 0
        evolutionInterval = Double.random(in: 10...16)
        
        let newCount = Int.random(in: 40...60)
        pendingElements = (0..<newCount).map { index in
            let depth = Double(index) / Double(newCount)
            return SeedElement.random(colors: currentPaletteColors, colorIndex: index, depth: depth)
        }
        
        if Bool.random() && Bool.random() {
            let symmetryChange = Int.random(in: -1...1)
            let newSymmetry = max(5, min(12, symmetryCount + symmetryChange))
            symmetryCount = newSymmetry
        }
    }
    
    private func updateTransition() {
        let t = easeInOutCubic(transitionProgress)
        
        for i in seedElements.indices {
            seedElements[i].size *= (1.0 - t * 0.02)
            
            if i < pendingElements.count {
                let target = pendingElements[i]
                seedElements[i].position.x += (target.position.x - seedElements[i].position.x) * t * 0.05
                seedElements[i].position.y += (target.position.y - seedElements[i].position.y) * t * 0.05
            }
        }
    }
    
    private func completeEvolution() {
        isTransitioning = false
        transitionProgress = 0
        
        for i in seedElements.indices {
            if i < pendingElements.count {
                seedElements[i] = pendingElements[i]
            }
        }
        
        if pendingElements.count > seedElements.count {
            seedElements.append(contentsOf: pendingElements[seedElements.count...])
        } else if pendingElements.count < seedElements.count {
            seedElements = Array(seedElements.prefix(pendingElements.count))
        }
        
        pendingElements = []
    }
    
    private func easeInOutCubic(_ t: Double) -> Double {
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            return 1 - pow(-2 * t + 2, 3) / 2
        }
    }
    
    func updatePalette(_ palette: ColorPalette) {
        targetPaletteColors = palette.colors
        colorTransitionProgress = 0.0
    }
    
    private func updateElementColors() {
        for i in seedElements.indices {
            let colorIndex = seedElements[i].colorIndex
            let fromColor = currentPaletteColors[colorIndex % currentPaletteColors.count]
            let toColor = targetPaletteColors[colorIndex % targetPaletteColors.count]
            seedElements[i].color = interpolateColor(from: fromColor, to: toColor, progress: colorTransitionProgress)
        }
        
        if colorTransitionProgress >= 1.0 {
            currentPaletteColors = targetPaletteColors
        }
    }
    
    private func interpolateColor(from: Color, to: Color, progress: Double) -> Color {
        let t = progress
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * t
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * t
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * t
        let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * t
        
        return Color(.displayP3, red: r, green: g, blue: b, opacity: a)
    }
    
    func adjustSymmetry(by delta: Int) {
        symmetryCount = max(3, min(12, symmetryCount + delta))
    }
    
    func setSymmetryFromPinch(scale: CGFloat, baseSymmetry: Int) {
        let newSymmetry = Int(Double(baseSymmetry) * Double(scale))
        symmetryCount = max(3, min(12, newSymmetry))
    }
    
    // MARK: - Motion Response
    
    func applyMotion(acceleration: CGPoint, intensity: Double) {
        motionIntensity = intensity
        motionDirection = acceleration
        
        // === INJECT KINETIC ENERGY FROM SHAKE ===
        // Shake wakes up the kaleidoscope!
        let energyInjection = intensity * 0.5
        kineticEnergy = min(1.0, kineticEnergy + energyInjection)
        
        // Also boost rotation velocity
        rotationVelocity = min(0.05, rotationVelocity + intensity * 0.02)
        
        // Mark as no longer resting
        if intensity > 0.2 {
            isResting = false
        }
        
        // Accumulate visual shake energy
        shakeEnergy = min(1.0, shakeEnergy + intensity * 0.3)
        
        // Apply force to all elements based on acceleration
        let forceMultiplier = intensity * 0.15
        
        for i in seedElements.indices {
            // Apply directional force
            seedElements[i].velocity.x += acceleration.x * forceMultiplier * (1.0 - seedElements[i].depth * 0.5)
            seedElements[i].velocity.y += acceleration.y * forceMultiplier * (1.0 - seedElements[i].depth * 0.5)
            
            // Add rotation based on shake
            seedElements[i].rotationSpeed += Double.random(in: -15...15) * intensity
            
            // Boost element energy
            seedElements[i].energy = min(1.0, seedElements[i].energy + intensity * 0.8)
        }
        
        // Strong shake triggers rotation burst
        if intensity > 0.5 {
            targetGlobalRotation += Double.random(in: -0.3...0.3) * intensity
        }
        
        // Very strong shake can trigger evolution
        if intensity > 0.8 && !isTransitioning && timeSinceLastEvolution > 3.0 {
            startEvolution()
        }
    }
    
    func decayMotion(deltaTime: Double) {
        let decay = 1.0 - deltaTime * 3.0
        motionIntensity *= decay
        shakeEnergy *= (1.0 - deltaTime * 1.5)
        
        if motionIntensity < 0.01 { motionIntensity = 0 }
        if shakeEnergy < 0.01 { shakeEnergy = 0 }
    }
}
