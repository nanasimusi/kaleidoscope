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
    
    // 蛍の同期発光（Kuramoto振動子）
    var pulsePhase: Double = 0       // GPUが結合更新し、毎フレーム読み戻す
    var pulseFreq: Double = 1.0      // 固有周波数 [rad/s]、スポーン時に決定

    // 生きた色彩: HSBベース成分（colorが変わるたびに再抽出）
    var hueBase: Double = 0
    var satBase: Double = 0.7
    var briBase: Double = 0.9
    var alphaBase: Double = 1.0

    // フレーム毎プリコンピュート（evolve()で計算、描画側は読むだけ）
    var displayColor: Color = .white
    var swellBoost: Double = 0   // 鼓動波によるサイズ膨張 0...~0.16
    var glowBoost: Double = 0    // パルス+鼓動波+エネルギーの複合グロー 0...1

    // 生命体としての独立した行動
    var goalPosition: CGPoint?  // 現在の目的地
    var timeUntilNewGoal: Double = 0.0  // 新しい目的地を探すまでの時間
    var wanderAngle: Double = 0.0  // さまよう方向
    var isResting: Bool = false  // 休憩中かどうか
    var restTime: Double = 0.0  // 休憩時間
    
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
        
        var element = SeedElement(
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

        // 群れ行動の重み（個体ごとの傾向）
        element.flockAlignment = Double.random(in: 0.4...1.0)
        element.flockCohesion = Double.random(in: 0.3...1.0)
        element.flockSeparation = Double.random(in: 0.7...1.0)

        // 蛍の発光リズム: 周期4.5〜9秒の分散が部分同期（揃いかけては崩れる）の鍵
        element.pulsePhase = Double.random(in: 0...(2 * Double.pi))
        element.pulseFreq = 2 * Double.pi / Double.random(in: 4.5...9.0)

        element.displayColor = element.color
        return element
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

    // 鼓動: 中心から広がる柔らかな放射波
    var heartbeatAge: Double = 999.0  // 直近の鼓動からの経過秒（大きい = 非活性）
    var timeSinceLastHeartbeat: Double = 0.0
    var heartbeatInterval: Double = Double.random(in: 10...20)
    
    // 生成アルゴリズムの自動切り替え
    var currentGenerationAlgorithm: GenerationAlgorithm = .random
    var timeSinceLastAlgorithmChange: Double = 0.0
    var algorithmChangeInterval: Double = Double.random(in: 20...40)  // パレットよりも長い間隔
    var algorithmTransitionProgress: Double = 1.0  // 0.0-1.0: アルゴリズム間のスムーズな遷移
    
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
        // Metal engineを最初に初期化
        // 重要: randomize()より前に行わないと、初回のparticleBufferが作られず
        // シェイクで再生成されるまでGPU物理演算が無効のままになる
        if let engine = MetalParticleEngine() {
            metalEngine = engine
            useMetal = true
            print("✅ Metal GPU acceleration enabled")
        } else {
            print("⚠️ Metal not available, using CPU fallback")
        }

        // ランダムなパレットで開始
        let randomPalette = ColorPalette.allCases.randomElement()!
        targetPaletteColors = randomPalette.colors
        currentPaletteColors = randomPalette.colors
        randomize(with: randomPalette.colors)
    }
    
    func randomize(with colors: [Color]) {
        // 品質レベルに応じた粒子数
        let quality = performanceMonitor.currentQuality
        let elementCount = Int.random(in: quality.particleCountRange)
        
        seedElements = currentGenerationAlgorithm.generate(count: elementCount, colors: colors)
        refreshColorBases()


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

        // 下限を設定してanimationPhaseの完全凍結を防ぐ
        // phaseが凍結するとMetal側の擬似乱数(phase依存)が定数化し、
        // 目的地が現在位置の決定的関数となって固定ループ軌道（円軌道）が発生する
        kineticEnergy = max(0.15, kineticEnergy)
        isResting = false
        
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
        
        // 進化システムを無効化
        // 理由: 新しいランダム位置へのモーフィングが、予測不可能な移動を妨げる
        // パーティクルは完全に自由に動くべき
        
        // timeSinceLastEvolution += smoothDelta * effectiveEnergy
        // Evolution system disabled
        
        if colorTransitionProgress < 1.0 {
            colorTransitionProgress = min(1.0, colorTransitionProgress + smoothDelta * 0.6)
            updateElementColors()
        }
        
        tapRipples.removeAll { animationPhase - $0.startTime > 5.0 }
        
        // 鼓動: 10〜20秒毎にランダムな間隔で、柔らかな波を中心から放つ
        timeSinceLastHeartbeat += smoothDelta
        heartbeatAge += smoothDelta
        if timeSinceLastHeartbeat >= heartbeatInterval {
            heartbeatAge = 0.0
            heartbeatInterval = Double.random(in: 10...20)
            timeSinceLastHeartbeat = 0.0
        }

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
        
        // 自動アルゴリズム切り替えを無効化
        // 理由: 新しいアルゴリズム（フィボナッチ、同心円、曼荼羅など）は円形配置
        // これらへのモーフィングがパーティクルを円運動させる原因
        // 完全に自由な動きを維持するため、アルゴリズムはrandomで固定
        
        // timeSinceLastAlgorithmChange += smoothDelta
        // 切り替えロジックは全てコメントアウト
        
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
        
        // 対称性の遷移を進める（描画側がこの進捗でクロスフェードする）
        if symmetryTransitionProgress < 1.0 {
            symmetryTransitionProgress = min(1.0, symmetryTransitionProgress + smoothDelta * 0.3)

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
            
            // === 生命体としての独立した行動システム ===
            
            let currentTime = animationPhase
            var flowX: Double = 0.0
            var flowY: Double = 0.0
            
            // 蛍の明滅（CPU版は非結合パルスのみ — Metal版でKuramoto結合）
            element.pulsePhase = (element.pulsePhase + element.pulseFreq * smoothDelta)
                .truncatingRemainder(dividingBy: 2 * Double.pi)

            // 1. 休憩中かチェック
            if element.isResting {
                element.restTime -= smoothDelta
                if element.restTime <= 0 {
                    seedElements[i].isResting = false
                    seedElements[i].goalPosition = nil
                }
                // 休憩中は微動だにしない（または微小な揺らぎのみ）
                let tremor = 0.0001 * element.personality
                flowX = Double.random(in: -tremor...tremor)
                flowY = Double.random(in: -tremor...tremor)
            } else {
                // 2. 目的地がない、または到達したら新しい目的地を設定
                if element.goalPosition == nil || element.timeUntilNewGoal <= 0 {
                    // 完全にランダムで美しい目的地を生成
                    let rand1 = Double.random(in: 0...1)
                    let rand2 = Double.random(in: 0...1)
                    let rand3 = Double.random(in: 0...1)
                    
                    // 性格と気分の組み合わせで無数のパターン
                    let exploreFactor = element.curiosity * element.mood
                    let calmFactor = (1.0 - element.personality) * (1.0 - element.mood)
                    
                    // 完全にランダムな直線的目的地（軌道運動なし）
                    let padding = 0.05
                    
                    if exploreFactor > 0.6 {
                        // 冒険的: 画面全体を自由に探索
                        seedElements[i].goalPosition = CGPoint(
                            x: padding + rand1 * (1.0 - padding * 2),
                            y: padding + rand2 * (1.0 - padding * 2)
                        )
                    } else if calmFactor > 0.5 {
                        // 落ち着いている: 中心付近をランダムに
                        seedElements[i].goalPosition = CGPoint(
                            x: 0.35 + rand1 * 0.3,
                            y: 0.35 + rand2 * 0.3
                        )
                    } else if element.personality > 0.7 {
                        // 活発: 4つの象限をランダムに移動
                        let quadrant = Int(rand3 * 4.0)
                        switch quadrant {
                        case 0: // 左上
                            seedElements[i].goalPosition = CGPoint(x: padding + rand1 * 0.4, y: padding + rand2 * 0.4)
                        case 1: // 右上
                            seedElements[i].goalPosition = CGPoint(x: 0.5 + rand1 * 0.45, y: padding + rand2 * 0.4)
                        case 2: // 左下
                            seedElements[i].goalPosition = CGPoint(x: padding + rand1 * 0.4, y: 0.5 + rand2 * 0.45)
                        default: // 右下
                            seedElements[i].goalPosition = CGPoint(x: 0.5 + rand1 * 0.45, y: 0.5 + rand2 * 0.45)
                        }
                    } else {
                        // その他: 完全自由なランダム配置
                        seedElements[i].goalPosition = CGPoint(
                            x: padding + rand1 * (1.0 - padding * 2),
                            y: padding + rand2 * (1.0 - padding * 2)
                        )
                    }
                    
                    // 目的地変更の間隔も個性的に
                    let baseInterval = 2.0 + rand3 * 4.0
                    let curiosityModifier = (1.0 - element.curiosity) * 3.0
                    let moodModifier = element.mood * 2.0
                    seedElements[i].timeUntilNewGoal = baseInterval + curiosityModifier - moodModifier
                    
                    // さまよう角度を美しく初期化
                    seedElements[i].wanderAngle = rand1 * 2 * .pi
                }
                
                // 3. 目的地に向かって移動
                if let goal = element.goalPosition {
                    let toGoalX = goal.x - element.position.x
                    let toGoalY = goal.y - element.position.y
                    let distanceToGoal = sqrt(toGoalX * toGoalX + toGoalY * toGoalY)
                    
                    if distanceToGoal < 0.05 {
                        // 目的地に到達: 休憩するかすぐ次に向かうか
                        if element.mood < 0.3 {
                            // 疲れている: 休憩
                            seedElements[i].isResting = true
                            seedElements[i].restTime = Double.random(in: 0.5...2.0)
                        }
                        seedElements[i].goalPosition = nil
                        seedElements[i].timeUntilNewGoal = 0
                    } else {
                        // 目的地に向かう力（まっすぐではなく、少し揺らぐ）
                        let dirX = toGoalX / distanceToGoal
                        let dirY = toGoalY / distanceToGoal
                        
                        // さまよい成分（有機的で美しい揺らぎ）
                        // 各個体が異なるリズムで揺らぐ
                        let timeScale = currentTime * (0.5 + element.personality * 1.5)
                        let wobble1 = sin(timeScale * 0.7 + element.phaseOffset * 3.0)
                        let wobble2 = cos(timeScale * 1.3 + element.phaseOffset * 5.0)
                        let wobble3 = sin(timeScale * 0.4 + element.phaseOffset * 7.0)
                        
                        // dtスケールでフレームレート非依存に（120fpsで角度が高速回転し円運動化するのを防ぐ）
                        element.wanderAngle += (wobble1 * 0.3 + wobble2 * 0.2) * element.personality * smoothDelta * 60.0
                        
                        let wanderStrength = (0.2 + element.sociability * 0.4) * (1.0 - element.mood * 0.5)
                        let wanderX = cos(element.wanderAngle) * wanderStrength + wobble3 * 0.1
                        let wanderY = sin(element.wanderAngle) * wanderStrength + wobble2 * 0.1
                        
                        // 合成（目的地への力 + さまよい）
                        // 各個体が異なる速度で動く（完全にランダム）
                        let baseSpeed = 0.0008 + element.curiosity * 0.0012  // 好奇心で速度が変わる
                        let moodVariation = element.mood * 0.0008  // 気分で速度が揺らぐ
                        let personalitySpeed = element.personality * 0.0006  // 性格で速度が変わる
                        
                        let seekStrength = baseSpeed + moodVariation + personalitySpeed
                        flowX = dirX * seekStrength + wanderX * 0.0003
                        flowY = dirY * seekStrength + wanderY * 0.0003
                        
                        // 時間を減らす
                        seedElements[i].timeUntilNewGoal -= smoothDelta
                    }
                }
            }
            
            // 環境からの微弱な影響のみ（他のパーティクルは完全に無視）
            // デバイス傾きによる重力
            flowX += smoothTilt.x * 0.015
            flowY += smoothTilt.y * 0.015
            
            // 気分の変化（ランダムウォーク）
            element.mood += (Double.random(in: -0.02...0.02) * element.personality)
            element.mood = max(0.0, min(1.0, element.mood))
            
            // 生命体システム: 滑らかで美しい動き
            element.position.x += flowX * 60.0 * smoothDelta
            element.position.y += flowY * 60.0 * smoothDelta
            
            // velocityは表示用に更新（互換性のため）
            element.velocity.x = flowX * 10.0
            element.velocity.y = flowY * 10.0
            
            element.awareness = 0.0
            
            // 位置更新後にトレイルを記録
            seedElements[i].trail.append(element.position)
            if seedElements[i].trail.count > element.maxTrailLength {
                seedElements[i].trail.removeFirst()
            }
            
            // モーフィング処理を無効化
            // 理由: 円形アルゴリズムへのモーフィングが円運動を生成
            // targetPositionは使用しない
            
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
            
            // ランダムな回転変動（個性を反映）
            let rotationIntensity = 0.5 + element.mood * 0.5 + element.personality * 0.3
            let randomRotation = Double.random(in: -0.3...0.3) * rotationIntensity
            var baseRotation = randomRotation
            
            // 好奇心の強い粒子はより活発に回転
            if element.curiosity > 0.6 {
                baseRotation += Double.random(in: -0.2...0.2) * element.curiosity
            }
            
            // 傾きによる回転への影響（左右の傾きで回転速度が変化）
            let tiltRotationInfluence = smoothTilt.x * 0.35 * (1.0 - element.depth * 0.25)
            baseRotation += tiltRotationInfluence
            
            element.rotation += Angle(degrees: (element.rotationSpeed + baseRotation) * smoothDelta * 45 * rotationIntensity)

            seedElements[i] = element
            }
        }

        // 生命表現のプリコンピュート（鼓動波・蛍の明滅・生きた色彩）
        updateLivingExpression()
    }

    // フレーム毎の生命表現プリコンピュート
    // 描画は要素×対称数×2ミラー×3層で呼ばれるため、要素毎の値はここで1回だけ計算する
    private func updateLivingExpression() {
        let phi = 1.618033988749895

        // 鼓動波: ガウシアン包絡の放射波（鋭いリングではなく柔らかな膨らみ）
        let waveSpeed = 0.32                                  // 正規化距離/秒 → 約2.2秒で端へ
        let waveFront = heartbeatAge * waveSpeed
        let waveAmp = exp(-heartbeatAge * 0.85)               // 進むほど減衰、~5秒でゼロ短絡
        let waveActive = waveAmp > 0.01

        for i in seedElements.indices {
            var element = seedElements[i]

            var waveEnv = 0.0
            if waveActive {
                let dx = element.position.x - 0.5
                let dy = element.position.y - 0.5
                let radialDist = Double((dx * dx + dy * dy).squareRoot())
                let d = radialDist - waveFront
                waveEnv = exp(-(d * d) / (2.0 * 0.065 * 0.065)) * waveAmp
            }

            let pulse = 0.5 + 0.5 * Foundation.sin(element.pulsePhase)
            element.swellBoost = waveEnv * 0.16
            element.glowBoost = pulse * 0.30 + waveEnv * 0.45 + element.energy * 0.35

            // 色相のミクロドリフト: パルス連動±4.5° + 緩慢な二次ドリフト±2.5°
            // 周波数は非整合（pulseFreqは個体毎ランダム、二次は黄金比）のため反復しない
            let hueDrift = Foundation.sin(element.pulsePhase) * 0.0125 +
                           Foundation.sin(animationPhase * 0.073 * phi + element.phaseOffset * 1.7) * 0.007
            var hue = (element.hueBase + hueDrift).truncatingRemainder(dividingBy: 1.0)
            if hue < 0 { hue += 1.0 }

            let sat = min(1.0, element.satBase * (1.0 + element.energy * 0.10 - pulse * 0.04))
            let bri = min(1.0, element.briBase * (1.0 + element.glowBoost * 0.22))
            element.displayColor = Color(hue: hue, saturation: sat, brightness: bri, opacity: element.alphaBase)

            seedElements[i] = element
        }
    }

    // 色のHSBベース成分を抽出（色が変わった時のみ呼ぶ — 毎フレームの定常呼び出しは禁止）
    private func extractHSB(_ color: Color) -> (h: Double, s: Double, b: Double, a: Double) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return (Double(h), Double(s), Double(b), Double(a))
        }
        return (0, 0, 0.9, 1)  // フォールバック（白系）
    }

    private func refreshColorBases() {
        for i in seedElements.indices {
            let hsb = extractHSB(seedElements[i].color)
            seedElements[i].hueBase = hsb.h
            seedElements[i].satBase = hsb.s
            seedElements[i].briBase = hsb.b
            seedElements[i].alphaBase = hsb.a
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
            var element = SeedElement.random(colors: currentPaletteColors, colorIndex: index, depth: depth)
            // 生命体システム: 新しいパーティクルの目的地をリセット
            element.goalPosition = nil
            element.timeUntilNewGoal = 0.0
            element.wanderAngle = Double.random(in: 0...(2 * .pi))
            element.isResting = false
            element.restTime = 0.0
            return element
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
                // 生命体システム: 目的地をリセット（新しい行動を開始）
                seedElements[i].goalPosition = nil
                seedElements[i].timeUntilNewGoal = 0.0
                seedElements[i].wanderAngle = Double.random(in: 0...(2 * .pi))
                seedElements[i].isResting = false
                seedElements[i].restTime = 0.0
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

        // パレット遷移中（~1.7秒間）のみ毎フレーム再抽出される
        refreshColorBases()

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
