import SwiftUI
import Foundation

enum ElementType: CaseIterable {
    case circle
    case curve
    case polygon
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
    
    static func random(colors: [Color], colorIndex: Int, depth: Double) -> SeedElement {
        let types: [ElementType] = [.circle, .circle, .circle, .circle, .curve, .curve, .curve, .polygon]
        
        let sizeVariation = depth < 0.3 ? CGFloat.random(in: 0.003...0.025) :
                           depth < 0.7 ? CGFloat.random(in: 0.008...0.045) :
                                        CGFloat.random(in: 0.015...0.07)
        
        return SeedElement(
            position: CGPoint(
                x: CGFloat.random(in: 0.02...0.98),
                y: CGFloat.random(in: 0.02...0.98)
            ),
            size: sizeVariation,
            color: colors[colorIndex % colors.count],
            rotation: Angle(degrees: Double.random(in: 0...360)),
            type: types.randomElement()!,
            velocity: CGPoint(
                x: CGFloat.random(in: -0.002...0.002),
                y: CGFloat.random(in: -0.002...0.002)
            ),
            rotationSpeed: Double.random(in: -4...4),
            sizeOscillation: Double.random(in: 0.15...0.5),
            phaseOffset: Double.random(in: 0...Double.pi * 2),
            colorIndex: colorIndex,
            depth: depth
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
        // Gradually slow down over time (like a spinning top)
        let decayRate = 0.015  // How fast energy decays (lower = slower decay)
        kineticEnergy *= (1.0 - decayRate * smoothDelta * 60)
        
        // Clamp to minimum threshold
        if kineticEnergy < 0.001 {
            kineticEnergy = 0
            isResting = true
        } else {
            isResting = false
        }
        
        // Rotation velocity also decays
        rotationVelocity *= (1.0 - decayRate * 0.8 * smoothDelta * 60)
        if rotationVelocity < 0.0005 {
            rotationVelocity = 0
        }
        
        // Apply kinetic energy to animation speed
        let effectiveEnergy = kineticEnergy * kineticEnergy  // Quadratic for smoother stop
        
        // Animation phase advances based on kinetic energy
        let basePhaseSpeed = 0.3 + Foundation.sin(animationPhase * 0.1) * 0.05
        animationPhase += smoothDelta * basePhaseSpeed * effectiveEnergy
        
        // Rotation with energy-based speed
        let breathCycle = Foundation.sin(animationPhase * 0.15) * 0.008
        targetGlobalRotation += smoothDelta * rotationVelocity * effectiveEnergy
        
        // Critically damped spring for rotation
        let omega = 3.0
        let rotationDiff = targetGlobalRotation - globalRotation
        let springForce = omega * omega * rotationDiff
        globalRotation += springForce * smoothDelta * (0.3 + effectiveEnergy * 0.7)
        
        // Exponential smoothing for touch
        let touchDecay = exp(-8.0 * smoothDelta)
        smoothTouchOffset.x = touchOffset.x + (smoothTouchOffset.x - touchOffset.x) * touchDecay
        smoothTouchOffset.y = touchOffset.y + (smoothTouchOffset.y - touchOffset.y) * touchDecay
        
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
            
            // Energy decay with kinetic influence
            let energyDecay = exp(-2.0 * smoothDelta)
            element.energy *= energyDecay
            if element.energy < 0.001 { element.energy = 0 }
            
            let phase = animationPhase + element.phaseOffset
            let energyBoost = 1.0 + element.energy * 1.5
            
            // Flow is scaled by kinetic energy
            let flowScale = effectiveEnergy * 0.002 * energyBoost
            let freq1 = 0.12 + element.depth * 0.05
            let freq2 = 0.23 + element.depth * 0.08
            let freq3 = 0.07 + element.depth * 0.03
            
            let flowX = (Foundation.sin(phase * freq1) * 0.4 +
                        Foundation.sin(phase * freq2 + element.phaseOffset) * 0.3 +
                        Foundation.sin(phase * freq3 + 2.5) * 0.3) * flowScale
            
            let flowY = (Foundation.cos(phase * freq1 * 0.9) * 0.4 +
                        Foundation.cos(phase * freq2 * 1.1 + element.phaseOffset) * 0.3 +
                        Foundation.cos(phase * freq3 * 0.8 + 1.7) * 0.3) * flowScale
            
            // Velocity decay is faster when kinetic energy is low
            let velocityDecayRate = 3.5 + (1.0 - effectiveEnergy) * 5.0
            let velocityDecay = exp(-velocityDecayRate * smoothDelta)
            element.velocity.x *= velocityDecay
            element.velocity.y *= velocityDecay
            
            // Position integration scaled by energy
            let responsiveness = (0.92 - element.depth * 0.15) * effectiveEnergy
            let positionDecay = exp(-6.0 * smoothDelta * max(0.1, responsiveness))
            
            let targetX = element.position.x + (element.velocity.x + flowX) * 25
            let targetY = element.position.y + (element.velocity.y + flowY) * 25
            
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
            
            // Organic rotation with varying speed
            let rotationDecay = exp(-2.0 * smoothDelta)
            element.rotationSpeed *= rotationDecay
            
            let baseRotation = Foundation.sin(phase * 0.3 + element.phaseOffset) * 0.5
            element.rotation += Angle(degrees: (element.rotationSpeed + baseRotation) * smoothDelta * 60)
            
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
