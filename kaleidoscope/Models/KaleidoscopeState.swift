import SwiftUI
import Foundation

enum ElementType: CaseIterable {
    case circle      // 発光する球体
    case curve       // 流れる曲線
    case nebula      // 星雲のようなぼんやりした形
    case tendril     // 触手・蔓のような有機的な形
    case droplet     // 水滴・しずく形
    case petal       // 花びら形
    
    // 新しいパターンを大量追加（バリエーション豊富に）
    case spiral      // 螺旋
    case wave        // 波形
    case zigzag      // ジグザグ
    case ring        // リング
    case star        // 星形（小さな点）
    case crescent    // 三日月
    case diamond     // ダイヤモンド形
    case triangle    // 三角形
    case square      // 四角形
    case cross       // 十字
    case arc         // 弧
    case dot         // 微小な点
    case dash        // ダッシュ（短線）
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
    
    static func random(colors: [Color], colorIndex: Int, depth: Double) -> SeedElement {
        // 極めて多様なパターン（ユーザーを飽きさせない）
        let types: [ElementType] = [
            // 線系（多め）
            .curve, .curve, .curve, .curve,
            .tendril, .tendril, .tendril,
            .wave, .wave,
            .spiral, .spiral,
            .arc, .arc,
            .zigzag,
            
            // 点系
            .circle, .circle,
            .dot, .dot, .dot,
            .star,
            
            // 形系
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
            .dash,
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
        
        // 個性に基づいた初期速度（内向的な粒子はゆっくり）
        let speedFactor = 0.5 + personality * 0.5
        
        // 色のバリエーション（基本色から少しずらす）
        let baseColor = colors[colorIndex % colors.count]
        let colorVariation = Double.random(in: -0.15...0.15)  // 色相を少し変化
        let brightnessVariation = Double.random(in: 0.7...1.3)  // 明るさを変化
        
        return SeedElement(
            position: CGPoint(
                x: CGFloat.random(in: 0.02...0.98),
                y: CGFloat.random(in: 0.02...0.98)
            ),
            size: sizeVariation,
            color: baseColor.opacity(Double.random(in: 0.6...1.0)),  // 透明度も変化
            rotation: Angle(degrees: Double.random(in: 0...360)),
            type: types.randomElement()!,
            velocity: CGPoint(
                x: CGFloat.random(in: -0.002...0.002) * speedFactor,
                y: CGFloat.random(in: -0.002...0.002) * speedFactor
            ),
            rotationSpeed: Double.random(in: -3.5...3.5) * speedFactor,
            sizeOscillation: Double.random(in: 0.15...0.45),
            phaseOffset: Double.random(in: 0...Double.pi * 2),
            colorIndex: colorIndex,
            depth: depth,
            personality: personality,
            curiosity: curiosity,
            sociability: sociability,
            mood: 0.3 + Double.random(in: 0...0.4)
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
    
    init() {
        let initialPalette = ColorPalette.dawn
        targetPaletteColors = initialPalette.colors
        currentPaletteColors = initialPalette.colors
        randomize(with: initialPalette.colors)
    }
    
    func randomize(with colors: [Color]) {
        // 無数の粒子が生き物のように動く
        let elementCount = Int.random(in: 40...60)
        seedElements = (0..<elementCount).map { index in
            let depth = Double(index) / Double(elementCount)
            return SeedElement.random(colors: colors, colorIndex: index, depth: depth)
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
        
        for i in seedElements.indices {
            var element = seedElements[i]
            
            // Energy decay with kinetic influence - より緩やかに
            let energyDecay = exp(-1.5 * smoothDelta)
            element.energy *= energyDecay
            if element.energy < 0.001 { element.energy = 0 }
            
            let phase = animationPhase + element.phaseOffset
            let energyBoost = 1.0 + element.energy * 1.5
            
            // 生命のような複雑な有機的フロー - 呼吸する海流のイメージ
            let flowScale = effectiveEnergy * 0.002 * energyBoost
            
            // 各エレメントごとに異なる周波数（個性を持たせる）
            let freq1 = 0.11 + element.depth * 0.04 + Foundation.sin(element.phaseOffset) * 0.02
            let freq2 = 0.22 + element.depth * 0.07 + Foundation.cos(element.phaseOffset * 1.3) * 0.03
            let freq3 = 0.06 + element.depth * 0.025 + Foundation.sin(element.phaseOffset * 0.7) * 0.015
            let freq4 = 0.15 + element.depth * 0.055 + Foundation.cos(element.phaseOffset * 1.7) * 0.025
            
            // 多層的な波の重ね合わせ（海の波のように）
            var flowX = (Foundation.sin(phase * freq1) * 0.35 +
                        Foundation.sin(phase * freq2 + element.phaseOffset) * 0.28 +
                        Foundation.sin(phase * freq3 + 2.5) * 0.22 +
                        Foundation.sin(phase * freq4 + 1.8) * 0.15) * flowScale
            
            var flowY = (Foundation.cos(phase * freq1 * 0.88) * 0.35 +
                        Foundation.cos(phase * freq2 * 1.12 + element.phaseOffset) * 0.28 +
                        Foundation.cos(phase * freq3 * 0.76 + 1.7) * 0.22 +
                        Foundation.cos(phase * freq4 * 1.25 + 0.9) * 0.15) * flowScale
            
            // デバイス傾きによる重力効果（目に見える自然な影響）
            // 深度によって傾きへの反応性を変える（奥のものほど遅く動く）
            let tiltResponsiveness = (1.0 - element.depth * 0.3) * effectiveEnergy
            let tiltStrength = 0.025 * tiltResponsiveness  // より明確な影響
            
            // 傾きに基づく重力的な力を加える（重力のように働く）
            flowX += smoothTilt.x * tiltStrength * energyBoost
            flowY += smoothTilt.y * tiltStrength * energyBoost
            
            // === 生き物としての知性と感情に基づく動き ===
            
            // 気分の変化（ランダムウォーク）
            element.mood += (Double.random(in: -0.02...0.02) * element.personality)
            element.mood = max(0.0, min(1.0, element.mood))
            
            // 周囲の粒子を感知（sociabilityが高いほど広範囲）
            var nearbyCount = 0
            var attractionX: Double = 0
            var attractionY: Double = 0
            let awarenessRadius = 0.15 * element.sociability
            
            for j in seedElements.indices where j != i {
                let other = seedElements[j]
                let dx = other.position.x - element.position.x
                let dy = other.position.y - element.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < awarenessRadius && distance > 0.001 {
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
                }
            }
            
            element.awareness = Double(nearbyCount) / 10.0
            
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
