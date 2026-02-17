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
        
        animationPhase += smoothDelta * 0.4
        
        targetGlobalRotation += smoothDelta * 0.02
        let rotationLerp = 1.0 - pow(0.05, smoothDelta)
        globalRotation += (targetGlobalRotation - globalRotation) * rotationLerp
        
        let touchLerp = 1.0 - pow(0.001, smoothDelta)
        smoothTouchOffset.x += (touchOffset.x - smoothTouchOffset.x) * touchLerp
        smoothTouchOffset.y += (touchOffset.y - smoothTouchOffset.y) * touchLerp
        
        timeSinceLastEvolution += smoothDelta
        if timeSinceLastEvolution >= evolutionInterval && !isTransitioning {
            startEvolution()
        }
        
        if isTransitioning {
            transitionProgress += smoothDelta * 0.25
            if transitionProgress >= 1.0 {
                completeEvolution()
            } else {
                updateTransition()
            }
        }
        
        if colorTransitionProgress < 1.0 {
            colorTransitionProgress = min(1.0, colorTransitionProgress + smoothDelta * 0.8)
            updateElementColors()
        }
        
        tapRipples.removeAll { animationPhase - $0.startTime > 4.0 }
        
        for i in seedElements.indices {
            var element = seedElements[i]
            
            let energyDecay = 1.0 - smoothDelta * 1.5
            element.energy *= energyDecay
            if element.energy < 0.005 { element.energy = 0 }
            
            let phase = animationPhase + element.phaseOffset
            let energyBoost = 1.0 + element.energy * 2.0
            
            let flowFreqX = 0.2 + element.depth * 0.1
            let flowFreqY = 0.15 + element.depth * 0.08
            let flowX = Foundation.sin(phase * flowFreqX) * 0.0015 * energyBoost
            let flowY = Foundation.cos(phase * flowFreqY) * 0.0015 * energyBoost
            
            let velocityDamping = 1.0 - smoothDelta * 0.8
            element.velocity.x *= velocityDamping
            element.velocity.y *= velocityDamping
            
            let positionLerp = 1.0 - pow(0.3, smoothDelta)
            let targetX = element.position.x + (element.velocity.x + flowX) * 30
            let targetY = element.position.y + (element.velocity.y + flowY) * 30
            element.position.x += (targetX - element.position.x) * positionLerp
            element.position.y += (targetY - element.position.y) * positionLerp
            
            let touchInfluence = 0.1 * (1.0 - element.depth * 0.3)
            element.position.x += smoothTouchOffset.x * touchInfluence * smoothDelta
            element.position.y += smoothTouchOffset.y * touchInfluence * smoothDelta
            
            let boundary: Double = 0.08
            if element.position.x < boundary {
                element.velocity.x = abs(element.velocity.x) * 0.3
                element.position.x = boundary + (boundary - element.position.x) * 0.5
            } else if element.position.x > 1.0 - boundary {
                element.velocity.x = -abs(element.velocity.x) * 0.3
                element.position.x = (1.0 - boundary) - (element.position.x - (1.0 - boundary)) * 0.5
            }
            if element.position.y < boundary {
                element.velocity.y = abs(element.velocity.y) * 0.3
                element.position.y = boundary + (boundary - element.position.y) * 0.5
            } else if element.position.y > 1.0 - boundary {
                element.velocity.y = -abs(element.velocity.y) * 0.3
                element.position.y = (1.0 - boundary) - (element.position.y - (1.0 - boundary)) * 0.5
            }
            
            let rotationDamping = 1.0 - smoothDelta * 0.5
            element.rotationSpeed *= rotationDamping
            element.rotation += Angle(degrees: element.rotationSpeed * smoothDelta)
            
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
        
        // Accumulate shake energy
        shakeEnergy = min(1.0, shakeEnergy + intensity * 0.3)
        
        // Apply force to all elements based on acceleration
        let forceMultiplier = intensity * 0.15
        
        for i in seedElements.indices {
            // Apply directional force
            seedElements[i].velocity.x += acceleration.x * forceMultiplier * (1.0 - seedElements[i].depth * 0.5)
            seedElements[i].velocity.y += acceleration.y * forceMultiplier * (1.0 - seedElements[i].depth * 0.5)
            
            // Add rotation based on shake
            seedElements[i].rotationSpeed += Double.random(in: -15...15) * intensity
            
            // Boost energy
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
