import SwiftUI
import Foundation

struct KaleidoscopeCanvasView: View {
    let state: KaleidoscopeState
    let size: CGSize
    var currentTime: Date = Date()
    var isDragging: Bool = false
    var onEvolve: ((Double) -> Void)? = nil
    
    var body: some View {
        Canvas { context, canvasSize in
            let phase = currentTime.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10000)
            drawFullScreenKaleidoscope(context: context, canvasSize: canvasSize, phase: phase)
        }
        .onChange(of: currentTime) { oldValue, newValue in
            if !isDragging {
                let deltaTime = newValue.timeIntervalSince(oldValue)
                if deltaTime > 0 && deltaTime < 1.0 {
                    onEvolve?(deltaTime)
                }
            }
        }
    }
    
    private func drawFullScreenKaleidoscope(context: GraphicsContext, canvasSize: CGSize, phase: Double) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let maxDimension = max(canvasSize.width, canvasSize.height)
        
        // Layer 1: Deep cosmic background with nebula
        drawDeepBackground(context: context, size: canvasSize, center: center, phase: phase)
        drawNebulaCloud(context: context, size: canvasSize, phase: phase)
        
        // Layer 2: Distant stardust field
        drawStardustField(context: context, size: canvasSize, phase: phase, density: 80, depth: 0.2)
        drawAmbientParticles(context: context, size: canvasSize, phase: phase, layer: 0)
        
        // Layer 3: Outermost kaleidoscope - ethereal haze
        let outerRadius = maxDimension * 0.95
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: outerRadius,
            phase: phase - 0.5,
            symmetryCount: max(3, state.symmetryCount - 3),
            rotation: state.globalRotation * 0.3,
            elements: Array(state.seedElements.suffix(15)),
            animationPhase: state.animationPhase * 0.5,
            opacity: 0.2
        )
        
        // Layer 4: Outer kaleidoscope
        let outer2Radius = maxDimension * 0.85
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: outer2Radius,
            phase: phase - 0.3,
            symmetryCount: max(3, state.symmetryCount - 2),
            rotation: state.globalRotation * 0.5,
            elements: Array(state.seedElements.suffix(20)),
            animationPhase: state.animationPhase * 0.7,
            opacity: 0.35
        )
        
        // Layer 5: Mid-outer stardust
        drawStardustField(context: context, size: canvasSize, phase: phase + 0.5, density: 60, depth: 0.4)
        
        // Layer 6: Main kaleidoscope - full complexity
        let mainRadius = maxDimension * 0.65
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: mainRadius,
            phase: phase,
            symmetryCount: state.symmetryCount,
            rotation: state.globalRotation,
            elements: state.seedElements,
            animationPhase: state.animationPhase,
            opacity: 1.0
        )
        
        // Layer 7: Micro-detail shimmer particles
        drawMicroShimmer(context: context, size: canvasSize, center: center, phase: phase)
        
        // Layer 8: Tap ripples with chromatic effect
        drawTapRipples(context: context, size: canvasSize, phase: phase)
        drawChromaticRipples(context: context, size: canvasSize, phase: phase)
        
        drawAmbientParticles(context: context, size: canvasSize, phase: phase, layer: 1)
        
        // Layer 9: Inner detail kaleidoscope
        let innerRadius = maxDimension * 0.42
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: innerRadius,
            phase: phase + 0.3,
            symmetryCount: state.symmetryCount + 2,
            rotation: -state.globalRotation * 1.2,
            elements: Array(state.seedElements.prefix(25)),
            animationPhase: state.animationPhase * 1.1,
            opacity: 0.8
        )
        
        // Layer 10: Light diffraction halo
        drawLightDiffraction(context: context, center: center, radius: maxDimension * 0.35, phase: phase)
        
        // Layer 11: Deep inner kaleidoscope
        let deepInnerRadius = maxDimension * 0.32
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: deepInnerRadius,
            phase: phase + 0.5,
            symmetryCount: state.symmetryCount + 3,
            rotation: -state.globalRotation * 1.5,
            elements: Array(state.seedElements.prefix(18)),
            animationPhase: state.animationPhase * 1.3,
            opacity: 0.7
        )
        
        // Layer 12: Core kaleidoscope
        let coreRadius = maxDimension * 0.2
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: coreRadius,
            phase: phase + 0.8,
            symmetryCount: state.symmetryCount + 5,
            rotation: state.globalRotation * 2.0,
            elements: Array(state.seedElements.prefix(12)),
            animationPhase: state.animationPhase * 1.6,
            opacity: 0.6
        )
        
        // Layer 13: Innermost nucleus
        let nucleusRadius = maxDimension * 0.1
        drawKaleidoscopeLayer(
            context: context,
            center: center,
            radius: nucleusRadius,
            phase: phase + 1.2,
            symmetryCount: state.symmetryCount + 8,
            rotation: state.globalRotation * 3.0,
            elements: Array(state.seedElements.prefix(8)),
            animationPhase: state.animationPhase * 2.0,
            opacity: 0.45
        )
        
        drawAmbientParticles(context: context, size: canvasSize, phase: phase, layer: 2)
        
        // Layer 14: Chromatic aberration overlay
        drawChromaticAberration(context: context, center: center, radius: maxDimension * 0.4, phase: phase)
        
        // Layer 15: Central luminous glow
        drawCentralGlow(context: context, center: center, radius: maxDimension * 0.12, phase: phase)
        
        // Layer 16: Floating particles and dust
        drawFloatingMotes(context: context, size: canvasSize, phase: phase)
        drawMicroDust(context: context, size: canvasSize, phase: phase)
        
        // Layer 17: Energy auras from interaction
        drawEnergyAuras(context: context, size: canvasSize, phase: phase)
        
        // Layer 18: Final sparkle overlay
        drawSparkleOverlay(context: context, size: canvasSize, phase: phase)
        
        // Layer 19: Shake energy effect
        if state.shakeEnergy > 0.05 {
            drawShakeEffect(context: context, size: canvasSize, center: center, phase: phase)
        }
    }
    
    private func drawTapRipples(context: GraphicsContext, size: CGSize, phase: Double) {
        for ripple in state.tapRipples {
            let age = state.animationPhase - ripple.startTime
            let maxAge = 4.0
            let progress = min(age / maxAge, 1.0)
            
            let easeOut = 1.0 - pow(1.0 - progress, 4)
            let maxRadius = max(size.width, size.height) * 0.5
            let radius = maxRadius * easeOut
            
            let fadeEase = pow(1.0 - progress, 2)
            let alpha = fadeEase * 0.35 * ripple.intensity
            
            for ring in 0..<3 {
                let ringDelay = Double(ring) * 0.1
                let ringProgress = max(0, min(1, (progress - ringDelay) / (1.0 - ringDelay)))
                let ringEaseOut = 1.0 - pow(1.0 - ringProgress, 3)
                let ringRadius = maxRadius * ringEaseOut * (1.0 - Double(ring) * 0.15)
                let ringAlpha = alpha * (1.0 - Double(ring) * 0.25) * (1.0 - ringProgress)
                
                if ringRadius > 5 {
                    let lineWidth = (3.0 - Double(ring) * 0.8) * (1.0 - ringProgress * 0.5)
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: ripple.position.x - ringRadius,
                            y: ripple.position.y - ringRadius,
                            width: ringRadius * 2,
                            height: ringRadius * 2
                        )),
                        with: .color(ripple.color.opacity(ringAlpha)),
                        style: StrokeStyle(lineWidth: lineWidth)
                    )
                }
            }
            
            let sparkCount = 8
            for i in 0..<sparkCount {
                let sparkDelay = Double(i) * 0.02
                let sparkProgress = max(0, min(1, (progress - sparkDelay) / 0.6))
                let sparkEase = 1.0 - pow(1.0 - sparkProgress, 2)
                
                let baseAngle = Double(i) * (Double.pi * 2 / Double(sparkCount))
                let spiralAngle = baseAngle + sparkEase * 0.5
                let sparkRadius = radius * (0.6 + sparkEase * 0.4)
                
                let sparkX = ripple.position.x + Foundation.cos(spiralAngle) * sparkRadius
                let sparkY = ripple.position.y + Foundation.sin(spiralAngle) * sparkRadius
                
                let sparkAlpha = alpha * (1.0 - sparkProgress) * 1.2
                let sparkSize = 2.5 * (1.0 - sparkProgress * 0.7)
                
                if sparkAlpha > 0.01 {
                    context.fill(
                        Path(ellipseIn: CGRect(x: sparkX - sparkSize, y: sparkY - sparkSize, width: sparkSize * 2, height: sparkSize * 2)),
                        with: .radialGradient(
                            Gradient(colors: [.white.opacity(sparkAlpha), ripple.color.opacity(sparkAlpha * 0.5), .clear]),
                            center: CGPoint(x: sparkX, y: sparkY),
                            startRadius: 0,
                            endRadius: sparkSize
                        )
                    )
                }
            }
        }
    }
    
    private func drawEnergyAuras(context: GraphicsContext, size: CGSize, phase: Double) {
        for element in state.seedElements where element.energy > 0.1 {
            let pos = CGPoint(
                x: size.width * element.position.x,
                y: size.height * element.position.y
            )
            
            let auraRadius = element.energy * 80
            let pulse = Foundation.sin(phase * 4 + element.phaseOffset) * 0.3 + 0.7
            
            let gradient = Gradient(colors: [
                element.color.opacity(element.energy * 0.4 * pulse),
                element.color.opacity(element.energy * 0.1),
                element.color.opacity(0)
            ])
            
            context.fill(
                Path(ellipseIn: CGRect(x: pos.x - auraRadius, y: pos.y - auraRadius, width: auraRadius * 2, height: auraRadius * 2)),
                with: .radialGradient(gradient, center: pos, startRadius: 0, endRadius: auraRadius)
            )
        }
    }
    
    private func drawDeepBackground(context: GraphicsContext, size: CGSize, center: CGPoint, phase: Double) {
        let colors = state.currentPaletteColors
        let color1 = colors.first ?? .black
        let color2 = colors.count > 2 ? colors[2] : .black
        let color3 = colors.count > 3 ? colors[3] : color1
        
        // Multi-frequency breathing for organic feel
        let breath1 = Foundation.sin(phase * 0.08) * 0.015 + 0.04
        let breath2 = Foundation.sin(phase * 0.12 + 1.0) * 0.01 + 0.03
        
        // Rich layered background gradient
        let bgGradient = Gradient(stops: [
            .init(color: color1.opacity(breath1 + breath2), location: 0.0),
            .init(color: color2.opacity(breath1 * 0.7), location: 0.25),
            .init(color: color3.opacity(breath2 * 0.5), location: 0.5),
            .init(color: Color(white: 0.02), location: 0.75),
            .init(color: .black, location: 1.0)
        ])
        
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                bgGradient,
                center: center,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 1.1
            )
        )
        
        // Subtle vignette for depth
        let vignetteGradient = Gradient(stops: [
            .init(color: .clear, location: 0.0),
            .init(color: .clear, location: 0.6),
            .init(color: .black.opacity(0.3), location: 0.85),
            .init(color: .black.opacity(0.6), location: 1.0)
        ])
        
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                vignetteGradient,
                center: center,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.8
            )
        )
    }
    
    private func drawKaleidoscopeLayer(
        context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        phase: Double,
        symmetryCount: Int,
        rotation: Double,
        elements: [SeedElement],
        animationPhase: Double,
        opacity: Double
    ) {
        let sectorAngle = (2.0 * Double.pi) / Double(symmetryCount)
        
        context.drawLayer { ctx in
            ctx.opacity = opacity
            
            for i in 0..<symmetryCount {
                let rotationAngle = Double(i) * sectorAngle + rotation
                
                ctx.drawLayer { sectorCtx in
                    sectorCtx.translateBy(x: center.x, y: center.y)
                    sectorCtx.rotate(by: Angle(radians: rotationAngle))
                    sectorCtx.translateBy(x: -center.x, y: -center.y)
                    
                    for element in elements {
                        drawRefinedElement(
                            element,
                            in: &sectorCtx,
                            center: center,
                            radius: radius,
                            phase: phase + animationPhase
                        )
                    }
                }
                
                ctx.drawLayer { mirrorCtx in
                    mirrorCtx.translateBy(x: center.x, y: center.y)
                    mirrorCtx.rotate(by: Angle(radians: rotationAngle))
                    mirrorCtx.scaleBy(x: -1, y: 1)
                    mirrorCtx.translateBy(x: -center.x, y: -center.y)
                    
                    for element in elements {
                        drawRefinedElement(
                            element,
                            in: &mirrorCtx,
                            center: center,
                            radius: radius,
                            phase: phase + animationPhase
                        )
                    }
                }
            }
        }
    }
    
    private func drawRefinedElement(
        _ element: SeedElement,
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        phase: Double
    ) {
        let elementPhase = phase + element.phaseOffset
        
        let flowFreq = 0.25 + element.depth * 0.15
        let flowX = Foundation.sin(elementPhase * flowFreq) * 0.08
        let flowY = Foundation.cos(elementPhase * flowFreq * 0.9) * 0.08
        
        let pos = CGPoint(
            x: center.x + (element.position.x - 0.5 + flowX) * radius,
            y: center.y + (element.position.y - 0.5 + flowY) * radius
        )
        
        let baseSize = element.size * radius
        let breatheFreq = 0.4 + element.depth * 0.2
        let breathe = 1.0 + Foundation.sin(elementPhase * breatheFreq) * 0.15
        let energyScale = 1.0 + element.energy * 0.5
        let size = baseSize * breathe * energyScale
        
        switch element.type {
        case .circle:
            drawLuminousOrb(context: &context, center: pos, radius: size, color: element.color, phase: elementPhase)
        case .curve:
            drawEtherealThread(context: &context, center: pos, radius: size, color: element.color, rotation: element.rotation, phase: elementPhase)
        case .polygon:
            drawCrystalShard(context: &context, center: pos, radius: size, color: element.color, rotation: element.rotation, phase: elementPhase)
        }
    }
    
    private func drawLuminousOrb(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        phase: Double
    ) {
        // Subtle breathing animation
        let breathe = 1.0 + Foundation.sin(phase * 0.6) * 0.08
        let adjustedRadius = radius * breathe
        
        // Outer ethereal glow layers (more gradual falloff)
        let glowLayers = 6
        for i in (0..<glowLayers).reversed() {
            let t = Double(i) / Double(glowLayers - 1)
            let r = adjustedRadius * (1.0 + t * 2.5)
            // Gaussian-like falloff
            let falloff = exp(-t * t * 2.0)
            let alpha = falloff * 0.25
            
            let gradient = Gradient(stops: [
                .init(color: color.opacity(alpha), location: 0.0),
                .init(color: color.opacity(alpha * 0.4), location: 0.5),
                .init(color: color.opacity(0), location: 1.0)
            ])
            
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: r)
            )
        }
        
        // Inner luminous core with color depth
        let coreRadius = adjustedRadius * 0.5
        let corePulse = Foundation.sin(phase * 1.2) * 0.1 + 0.9
        
        let coreGradient = Gradient(stops: [
            .init(color: .white.opacity(0.95 * corePulse), location: 0.0),
            .init(color: .white.opacity(0.7 * corePulse), location: 0.2),
            .init(color: color.opacity(0.85), location: 0.5),
            .init(color: color.opacity(0.4), location: 0.8),
            .init(color: color.opacity(0.1), location: 1.0)
        ])
        
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2)),
            with: .radialGradient(coreGradient, center: center, startRadius: 0, endRadius: coreRadius)
        )
        
        // Specular highlight
        let highlightOffset = adjustedRadius * 0.15
        let highlightRadius = adjustedRadius * 0.2
        let highlightCenter = CGPoint(x: center.x - highlightOffset, y: center.y - highlightOffset)
        let highlightAlpha = 0.4 + Foundation.sin(phase * 0.8) * 0.1
        
        context.fill(
            Path(ellipseIn: CGRect(x: highlightCenter.x - highlightRadius, y: highlightCenter.y - highlightRadius, width: highlightRadius * 2, height: highlightRadius * 2)),
            with: .radialGradient(
                Gradient(colors: [.white.opacity(highlightAlpha), .clear]),
                center: highlightCenter,
                startRadius: 0,
                endRadius: highlightRadius
            )
        )
    }
    
    private func drawEtherealThread(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        rotation: Angle,
        phase: Double
    ) {
        let segments = 32
        let length = radius * 4.0
        
        var points: [CGPoint] = []
        var widths: [CGFloat] = []
        
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let angle = rotation.radians + t * Double.pi
            
            // Multi-harmonic wave for organic flowing motion
            let wave1 = Foundation.sin(phase * 0.4 + t * Double.pi * 4) * radius * 0.4
            let wave2 = Foundation.cos(phase * 0.3 + t * Double.pi * 2.5) * radius * 0.25
            let wave3 = Foundation.sin(phase * 0.55 + t * Double.pi * 6) * radius * 0.15
            
            let perpAngle = angle + Double.pi / 2
            let offset = wave1 + wave2 + wave3
            
            // Tapered width - thicker in middle, thinner at ends
            let taper = Foundation.sin(t * Double.pi)
            widths.append(radius * 0.08 * taper + radius * 0.02)
            
            let x = center.x + Foundation.cos(angle) * length * (t - 0.5) + Foundation.cos(perpAngle) * offset
            let y = center.y + Foundation.sin(angle) * length * (t - 0.5) + Foundation.sin(perpAngle) * offset
            
            points.append(CGPoint(x: x, y: y))
        }
        
        guard points.count >= 2 else { return }
        
        // Outer glow layers with Gaussian falloff
        for layer in (0..<5).reversed() {
            let t = Double(layer) / 4.0
            let falloff = exp(-t * t * 1.5)
            let alpha = 0.06 * falloff
            let width = radius * (0.25 + t * 0.4)
            
            var path = Path()
            path.move(to: points[0])
            
            // Catmull-Rom style smooth curve
            for i in 1..<points.count - 1 {
                let p1 = points[i]
                let p2 = points[i + 1]
                
                let midX = (p1.x + p2.x) / 2
                let midY = (p1.y + p2.y) / 2
                
                path.addQuadCurve(to: CGPoint(x: midX, y: midY), control: p1)
            }
            
            if let last = points.last {
                path.addLine(to: last)
            }
            
            context.stroke(
                path,
                with: .color(color.opacity(alpha)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
        
        // Create smooth bezier path for core
        var corePath = Path()
        corePath.move(to: points[0])
        
        for i in 1..<points.count - 1 {
            let p1 = points[i]
            let p2 = points[i + 1]
            let midX = (p1.x + p2.x) / 2
            let midY = (p1.y + p2.y) / 2
            corePath.addQuadCurve(to: CGPoint(x: midX, y: midY), control: p1)
        }
        if let last = points.last {
            corePath.addLine(to: last)
        }
        
        // Luminous core with gradient
        let coreGradient = Gradient(stops: [
            .init(color: color.opacity(0.3), location: 0.0),
            .init(color: .white.opacity(0.85), location: 0.35),
            .init(color: .white.opacity(0.9), location: 0.5),
            .init(color: .white.opacity(0.85), location: 0.65),
            .init(color: color.opacity(0.3), location: 1.0)
        ])
        
        context.stroke(
            corePath,
            with: .linearGradient(
                coreGradient,
                startPoint: points.first ?? center,
                endPoint: points.last ?? center
            ),
            style: StrokeStyle(lineWidth: radius * 0.035, lineCap: .round)
        )
        
        // Inner bright core
        context.stroke(
            corePath,
            with: .linearGradient(
                Gradient(colors: [.clear, .white.opacity(0.6), .clear]),
                startPoint: points.first ?? center,
                endPoint: points.last ?? center
            ),
            style: StrokeStyle(lineWidth: radius * 0.015, lineCap: .round)
        )
    }
    
    private func drawCrystalShard(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        rotation: Angle,
        phase: Double
    ) {
        // Subtle multi-frequency shimmer
        let shimmer1 = Foundation.sin(phase * 1.5) * 0.5 + 0.5
        let shimmer2 = Foundation.sin(phase * 2.3 + 1.0) * 0.3 + 0.5
        let shimmer = shimmer1 * 0.6 + shimmer2 * 0.4
        
        // Slow, graceful rotation
        let dynamicRotation = rotation.radians + phase * 0.12
        
        // 8-pointed star for more elegant shape
        let pointCount = 8
        let points: [CGPoint] = (0..<pointCount).map { i in
            let angle = Double(i) * (Double.pi * 2 / Double(pointCount)) + dynamicRotation
            let innerOuter = i % 2 == 0 ? 1.0 : 0.45
            let r = radius * innerOuter
            return CGPoint(
                x: center.x + Foundation.cos(angle) * r,
                y: center.y + Foundation.sin(angle) * r
            )
        }
        
        // Soft outer glow with Gaussian falloff
        for layer in (0..<5).reversed() {
            let t = Double(layer) / 4.0
            let falloff = exp(-t * t * 2.0)
            let scale = 1.0 + t * 0.6
            let alpha = 0.08 * falloff
            
            var glowPath = Path()
            let scaledPoints = points.map { p in
                CGPoint(
                    x: center.x + (p.x - center.x) * scale,
                    y: center.y + (p.y - center.y) * scale
                )
            }
            
            glowPath.move(to: scaledPoints[0])
            for point in scaledPoints.dropFirst() {
                glowPath.addLine(to: point)
            }
            glowPath.closeSubpath()
            
            context.fill(glowPath, with: .color(color.opacity(alpha)))
        }
        
        // Main crystal body
        var mainPath = Path()
        mainPath.move(to: points[0])
        for point in points.dropFirst() {
            mainPath.addLine(to: point)
        }
        mainPath.closeSubpath()
        
        // Rich gradient fill with depth
        let fillGradient = Gradient(stops: [
            .init(color: .white.opacity(0.15 + shimmer * 0.2), location: 0.0),
            .init(color: color.opacity(0.35 + shimmer * 0.25), location: 0.3),
            .init(color: color.opacity(0.2 + shimmer * 0.15), location: 0.7),
            .init(color: color.opacity(0.08), location: 1.0)
        ])
        
        context.fill(
            mainPath,
            with: .linearGradient(
                fillGradient,
                startPoint: CGPoint(x: center.x - radius * 0.5, y: center.y - radius),
                endPoint: CGPoint(x: center.x + radius * 0.5, y: center.y + radius)
            )
        )
        
        // Crisp edge highlight
        context.stroke(
            mainPath,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.5 * shimmer), location: 0.0),
                    .init(color: .white.opacity(0.2), location: 0.5),
                    .init(color: .white.opacity(0.4 * shimmer), location: 1.0)
                ]),
                startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
                endPoint: CGPoint(x: center.x + radius, y: center.y + radius)
            ),
            style: StrokeStyle(lineWidth: 0.6)
        )
        
        // Primary specular highlight
        let highlightRadius = radius * 0.2
        let highlightCenter = CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.25)
        
        context.fill(
            Path(ellipseIn: CGRect(
                x: highlightCenter.x - highlightRadius,
                y: highlightCenter.y - highlightRadius,
                width: highlightRadius * 2,
                height: highlightRadius * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.7 * shimmer), location: 0.0),
                    .init(color: .white.opacity(0.3 * shimmer), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ]),
                center: highlightCenter,
                startRadius: 0,
                endRadius: highlightRadius
            )
        )
        
        // Secondary subtle highlight
        let highlight2Radius = radius * 0.12
        let highlight2Center = CGPoint(x: center.x + radius * 0.15, y: center.y + radius * 0.1)
        
        context.fill(
            Path(ellipseIn: CGRect(
                x: highlight2Center.x - highlight2Radius,
                y: highlight2Center.y - highlight2Radius,
                width: highlight2Radius * 2,
                height: highlight2Radius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [.white.opacity(0.25 * shimmer), .clear]),
                center: highlight2Center,
                startRadius: 0,
                endRadius: highlight2Radius
            )
        )
    }
    
    private func drawAmbientParticles(context: GraphicsContext, size: CGSize, phase: Double, layer: Int) {
        let particleCount = 60
        let layerOffset = Double(layer) * 1000.0
        let depthFactor = 1.0 - Double(layer) * 0.25
        
        for i in 0..<particleCount {
            let seed = Double(i) + layerOffset
            let goldenAngle = 2.399963229728653
            
            // Spiral distribution with gentle drift
            let spiralPhase = phase * 0.015 * depthFactor
            let x = fmod(seed * 0.618033988749895 + spiralPhase, 1.0) * size.width
            let y = fmod(seed * goldenAngle * 0.1 + spiralPhase * 0.8, 1.0) * size.height
            
            // Multi-frequency twinkle for more organic feel
            let twinkle1 = Foundation.sin(phase * (1.8 + seed * 0.08)) * 0.4 + 0.5
            let twinkle2 = Foundation.sin(phase * (2.5 + seed * 0.12) + seed) * 0.3 + 0.5
            let twinkle = twinkle1 * 0.6 + twinkle2 * 0.4
            
            let baseAlpha = (0.12 - Double(layer) * 0.025) * depthFactor
            let alpha = baseAlpha * twinkle
            
            // Size varies by depth and twinkle
            let baseSize = 0.8 + seed.truncatingRemainder(dividingBy: 2.5)
            let particleRadius = baseSize * depthFactor + twinkle * 1.5
            
            let colors = state.currentPaletteColors
            let colorIndex = Int(seed) % max(colors.count, 1)
            let color = colors.isEmpty ? Color.white : colors[colorIndex]
            
            // Soft glow with color depth
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - particleRadius * 1.5,
                    y: y - particleRadius * 1.5,
                    width: particleRadius * 3,
                    height: particleRadius * 3
                )),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(alpha * 0.8), location: 0.0),
                        .init(color: color.opacity(alpha * 0.6), location: 0.3),
                        .init(color: color.opacity(alpha * 0.2), location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: particleRadius * 1.5
                )
            )
        }
    }
    
    private func drawFloatingMotes(context: GraphicsContext, size: CGSize, phase: Double) {
        let moteCount = 100
        
        for i in 0..<moteCount {
            let seed = Double(i) * 7.919
            
            // Gentler, more natural drift pattern
            let baseX = fmod(seed * 0.618033988749895, 1.0) * size.width
            let baseY = fmod(seed * 0.381966011250105, 1.0) * size.height
            
            // Multi-frequency organic movement
            let driftX = Foundation.sin(phase * 0.2 + seed) * 25 +
                        Foundation.sin(phase * 0.35 + seed * 1.7) * 15
            let driftY = Foundation.cos(phase * 0.18 + seed * 1.3) * 20 +
                        Foundation.cos(phase * 0.28 + seed * 0.9) * 12 -
                        phase * 3  // Gentle upward drift
            
            var x = baseX + driftX
            var y = fmod(baseY + driftY, size.height + 60)
            if y < -30 { y += size.height + 60 }
            
            // Smooth twinkle with natural fade
            let twinklePhase = phase * (1.2 + seed * 0.04)
            let twinkle = pow(Foundation.sin(twinklePhase) * 0.5 + 0.5, 1.5)
            let alpha = 0.08 + twinkle * 0.18
            
            let moteRadius = 0.4 + twinkle * 1.2
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - moteRadius,
                    y: y - moteRadius,
                    width: moteRadius * 2,
                    height: moteRadius * 2
                )),
                with: .color(.white.opacity(alpha))
            )
        }
    }
    
    private func drawCentralGlow(context: GraphicsContext, center: CGPoint, radius: CGFloat, phase: Double) {
        let pulse = Foundation.sin(phase * 0.5) * 0.2 + 0.8
        let colors = state.currentPaletteColors
        let glowColor = colors.first ?? .white
        
        let glowGradient = Gradient(colors: [
            glowColor.opacity(0.15 * pulse),
            glowColor.opacity(0.05 * pulse),
            .clear
        ])
        
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - radius * 2,
                y: center.y - radius * 2,
                width: radius * 4,
                height: radius * 4
            )),
            with: .radialGradient(glowGradient, center: center, startRadius: 0, endRadius: radius * 2)
        )
    }
    
    // MARK: - Nebula and Cosmic Effects
    
    private func drawNebulaCloud(context: GraphicsContext, size: CGSize, phase: Double) {
        let colors = state.currentPaletteColors
        let nebulaCount = 5
        
        for i in 0..<nebulaCount {
            let seed = Double(i) * 2.718281828
            let baseX = fmod(seed * 0.618033988749895, 1.0) * size.width
            let baseY = fmod(seed * 0.381966011250105, 1.0) * size.height
            
            let drift = Foundation.sin(phase * 0.05 + seed) * 50
            let x = baseX + drift
            let y = baseY + Foundation.cos(phase * 0.04 + seed * 1.5) * 40
            
            let nebulaRadius = size.width * (0.2 + fmod(seed, 0.15))
            let rotation = phase * 0.02 + seed
            
            let colorIndex = i % max(colors.count, 1)
            let nebulaColor = colors.isEmpty ? Color.purple : colors[colorIndex]
            
            for layer in 0..<3 {
                let layerScale = 1.0 + Double(layer) * 0.3
                let layerAlpha = 0.03 - Double(layer) * 0.008
                let layerOffset = Double(layer) * 20
                
                let offsetX = Foundation.cos(rotation + Double(layer)) * layerOffset
                let offsetY = Foundation.sin(rotation + Double(layer)) * layerOffset
                
                let gradient = Gradient(colors: [
                    nebulaColor.opacity(layerAlpha),
                    nebulaColor.opacity(layerAlpha * 0.5),
                    nebulaColor.opacity(0)
                ])
                
                let r = nebulaRadius * layerScale
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: x + offsetX - r,
                        y: y + offsetY - r,
                        width: r * 2,
                        height: r * 1.5
                    )),
                    with: .radialGradient(gradient, center: CGPoint(x: x + offsetX, y: y + offsetY), startRadius: 0, endRadius: r)
                )
            }
        }
    }
    
    private func drawStardustField(context: GraphicsContext, size: CGSize, phase: Double, density: Int, depth: Double) {
        let colors = state.currentPaletteColors
        
        for i in 0..<density {
            let seed = Double(i) * 3.14159265 + depth * 1000
            let goldenRatio = 0.618033988749895
            
            let x = fmod(seed * goldenRatio, 1.0) * size.width
            let y = fmod(seed * goldenRatio * goldenRatio, 1.0) * size.height
            
            let twinkleSpeed = 1.5 + fmod(seed, 2.0)
            let twinkle = Foundation.sin(phase * twinkleSpeed + seed) * 0.5 + 0.5
            let baseAlpha = (0.1 + depth * 0.15) * twinkle
            
            let starSize = (0.3 + fmod(seed * 0.1, 1.5)) * (1.0 - depth * 0.5)
            
            let colorIndex = Int(seed) % max(colors.count, 1)
            let starColor = colors.isEmpty ? Color.white : colors[colorIndex]
            
            context.fill(
                Path(ellipseIn: CGRect(x: x - starSize, y: y - starSize, width: starSize * 2, height: starSize * 2)),
                with: .radialGradient(
                    Gradient(colors: [.white.opacity(baseAlpha * 1.5), starColor.opacity(baseAlpha), .clear]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: starSize * 2
                )
            )
            
            if twinkle > 0.7 && starSize > 0.8 {
                let sparkleLength = starSize * 4 * twinkle
                let sparkleAlpha = baseAlpha * 0.5
                
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x - sparkleLength, y: y))
                        p.addLine(to: CGPoint(x: x + sparkleLength, y: y))
                    },
                    with: .linearGradient(
                        Gradient(colors: [.clear, .white.opacity(sparkleAlpha), .clear]),
                        startPoint: CGPoint(x: x - sparkleLength, y: y),
                        endPoint: CGPoint(x: x + sparkleLength, y: y)
                    ),
                    style: StrokeStyle(lineWidth: 0.5)
                )
                
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x, y: y - sparkleLength))
                        p.addLine(to: CGPoint(x: x, y: y + sparkleLength))
                    },
                    with: .linearGradient(
                        Gradient(colors: [.clear, .white.opacity(sparkleAlpha), .clear]),
                        startPoint: CGPoint(x: x, y: y - sparkleLength),
                        endPoint: CGPoint(x: x, y: y + sparkleLength)
                    ),
                    style: StrokeStyle(lineWidth: 0.5)
                )
            }
        }
    }
    
    // MARK: - Micro Detail Effects
    
    private func drawMicroShimmer(context: GraphicsContext, size: CGSize, center: CGPoint, phase: Double) {
        let shimmerCount = 150
        let maxRadius = max(size.width, size.height) * 0.6
        let colors = state.currentPaletteColors
        
        for i in 0..<shimmerCount {
            let seed = Double(i) * 1.618033988749895
            let angle = seed * 2.399963229728653 + phase * 0.1
            let radiusFactor = fmod(seed * 0.618033988749895, 1.0)
            let r = radiusFactor * maxRadius
            
            let x = center.x + Foundation.cos(angle) * r
            let y = center.y + Foundation.sin(angle) * r
            
            let twinkle = Foundation.sin(phase * (3 + seed * 0.2) + seed) * 0.5 + 0.5
            let alpha = 0.05 + twinkle * 0.12
            let shimmerSize = 0.3 + twinkle * 0.8
            
            let colorIndex = Int(seed * 3) % max(colors.count, 1)
            let shimmerColor = colors.isEmpty ? Color.white : colors[colorIndex]
            
            context.fill(
                Path(ellipseIn: CGRect(x: x - shimmerSize, y: y - shimmerSize, width: shimmerSize * 2, height: shimmerSize * 2)),
                with: .color(shimmerColor.opacity(alpha))
            )
        }
    }
    
    private func drawMicroDust(context: GraphicsContext, size: CGSize, phase: Double) {
        let dustCount = 200
        
        for i in 0..<dustCount {
            let seed = Double(i) * 0.577215664901532
            let x = fmod(seed * 0.618033988749895 + phase * 0.005, 1.0) * size.width
            let y = fmod(seed * 0.381966011250105 + phase * 0.003, 1.0) * size.height
            
            let flicker = Foundation.sin(phase * (5 + seed * 0.3)) * 0.5 + 0.5
            let alpha = 0.02 + flicker * 0.04
            let dustSize = 0.2 + flicker * 0.3
            
            context.fill(
                Path(ellipseIn: CGRect(x: x - dustSize, y: y - dustSize, width: dustSize * 2, height: dustSize * 2)),
                with: .color(.white.opacity(alpha))
            )
        }
    }
    
    // MARK: - Light and Chromatic Effects
    
    private func drawLightDiffraction(context: GraphicsContext, center: CGPoint, radius: CGFloat, phase: Double) {
        let ringCount = 8
        
        for i in 0..<ringCount {
            let t = Double(i) / Double(ringCount)
            let ringRadius = radius * (0.5 + t * 0.8)
            let pulse = Foundation.sin(phase * 0.8 + t * Double.pi * 2) * 0.3 + 0.7
            
            let hue = fmod(t + phase * 0.02, 1.0)
            let ringColor = Color(hue: hue, saturation: 0.6, brightness: 1.0)
            
            let alpha = 0.03 * pulse * (1.0 - t * 0.5)
            let lineWidth = 1.5 - t * 0.8
            
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - ringRadius,
                    y: center.y - ringRadius,
                    width: ringRadius * 2,
                    height: ringRadius * 2
                )),
                with: .color(ringColor.opacity(alpha)),
                style: StrokeStyle(lineWidth: lineWidth)
            )
        }
    }
    
    private func drawChromaticAberration(context: GraphicsContext, center: CGPoint, radius: CGFloat, phase: Double) {
        let offset = 3.0 + Foundation.sin(phase * 0.3) * 2.0
        let alpha = 0.06
        
        let redCenter = CGPoint(x: center.x + offset, y: center.y)
        context.fill(
            Path(ellipseIn: CGRect(
                x: redCenter.x - radius * 0.3,
                y: redCenter.y - radius * 0.3,
                width: radius * 0.6,
                height: radius * 0.6
            )),
            with: .radialGradient(
                Gradient(colors: [Color.red.opacity(alpha), .clear]),
                center: redCenter,
                startRadius: 0,
                endRadius: radius * 0.3
            )
        )
        
        let blueCenter = CGPoint(x: center.x - offset, y: center.y)
        context.fill(
            Path(ellipseIn: CGRect(
                x: blueCenter.x - radius * 0.3,
                y: blueCenter.y - radius * 0.3,
                width: radius * 0.6,
                height: radius * 0.6
            )),
            with: .radialGradient(
                Gradient(colors: [Color.blue.opacity(alpha), .clear]),
                center: blueCenter,
                startRadius: 0,
                endRadius: radius * 0.3
            )
        )
        
        let cyanCenter = CGPoint(x: center.x, y: center.y - offset * 0.7)
        context.fill(
            Path(ellipseIn: CGRect(
                x: cyanCenter.x - radius * 0.25,
                y: cyanCenter.y - radius * 0.25,
                width: radius * 0.5,
                height: radius * 0.5
            )),
            with: .radialGradient(
                Gradient(colors: [Color.cyan.opacity(alpha * 0.7), .clear]),
                center: cyanCenter,
                startRadius: 0,
                endRadius: radius * 0.25
            )
        )
    }
    
    private func drawChromaticRipples(context: GraphicsContext, size: CGSize, phase: Double) {
        for ripple in state.tapRipples {
            let age = state.animationPhase - ripple.startTime
            let maxAge = 5.0
            let progress = min(age / maxAge, 1.0)
            
            if progress < 0.8 {
                let easeOut = 1.0 - pow(1.0 - progress, 3)
                let maxRadius = max(size.width, size.height) * 0.4
                let radius = maxRadius * easeOut
                
                let fadeEase = pow(1.0 - progress, 2.5)
                let baseAlpha = fadeEase * 0.08 * ripple.intensity
                
                let chromaticOffset = 4.0 + progress * 8.0
                
                let redRadius = radius + chromaticOffset
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: ripple.position.x - redRadius,
                        y: ripple.position.y - redRadius,
                        width: redRadius * 2,
                        height: redRadius * 2
                    )),
                    with: .color(Color.red.opacity(baseAlpha)),
                    style: StrokeStyle(lineWidth: 1.0)
                )
                
                let blueRadius = radius - chromaticOffset
                if blueRadius > 5 {
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: ripple.position.x - blueRadius,
                            y: ripple.position.y - blueRadius,
                            width: blueRadius * 2,
                            height: blueRadius * 2
                        )),
                        with: .color(Color.blue.opacity(baseAlpha)),
                        style: StrokeStyle(lineWidth: 1.0)
                    )
                }
            }
        }
    }
    
    // MARK: - Sparkle Overlay
    
    private func drawSparkleOverlay(context: GraphicsContext, size: CGSize, phase: Double) {
        let sparkleCount = 30
        
        for i in 0..<sparkleCount {
            let seed = Double(i) * 11.0
            let x = fmod(seed * 0.618033988749895, 1.0) * size.width
            let y = fmod(seed * 0.381966011250105, 1.0) * size.height
            
            let sparklePhase = fmod(phase * 0.5 + seed, 3.0)
            let sparkleVisible = sparklePhase < 0.5
            
            if sparkleVisible {
                let intensity = Foundation.sin(sparklePhase * Double.pi * 2)
                let alpha = max(0, intensity * 0.6)
                let sparkleSize = 1.5 + intensity * 2.0
                
                let armLength = sparkleSize * 3
                
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x - armLength, y: y))
                        p.addLine(to: CGPoint(x: x + armLength, y: y))
                    },
                    with: .linearGradient(
                        Gradient(colors: [.clear, .white.opacity(alpha), .clear]),
                        startPoint: CGPoint(x: x - armLength, y: y),
                        endPoint: CGPoint(x: x + armLength, y: y)
                    ),
                    style: StrokeStyle(lineWidth: 1.0)
                )
                
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x, y: y - armLength))
                        p.addLine(to: CGPoint(x: x, y: y + armLength))
                    },
                    with: .linearGradient(
                        Gradient(colors: [.clear, .white.opacity(alpha), .clear]),
                        startPoint: CGPoint(x: x, y: y - armLength),
                        endPoint: CGPoint(x: x, y: y + armLength)
                    ),
                    style: StrokeStyle(lineWidth: 1.0)
                )
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x - sparkleSize, y: y - sparkleSize, width: sparkleSize * 2, height: sparkleSize * 2)),
                    with: .radialGradient(
                        Gradient(colors: [.white.opacity(alpha), .clear]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: sparkleSize
                    )
                )
            }
        }
    }
    
    // MARK: - Shake Effect
    
    private func drawShakeEffect(context: GraphicsContext, size: CGSize, center: CGPoint, phase: Double) {
        let energy = state.shakeEnergy
        let maxDimension = max(size.width, size.height)
        
        // Screen edge glow pulse
        let pulseAlpha = energy * 0.15
        let colors = state.currentPaletteColors
        let glowColor = colors.randomElement() ?? .white
        
        // Edge glow based on motion direction
        let dirX = state.motionDirection.x
        let dirY = state.motionDirection.y
        
        // Left/Right edge glow
        if abs(dirX) > 0.1 {
            let edgeX = dirX > 0 ? 0.0 : size.width
            let gradient = Gradient(colors: [
                glowColor.opacity(pulseAlpha * abs(dirX)),
                .clear
            ])
            context.fill(
                Path(CGRect(x: edgeX - 50, y: 0, width: 100, height: size.height)),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: edgeX, y: size.height / 2),
                    endPoint: CGPoint(x: dirX > 0 ? edgeX + 100 : edgeX - 100, y: size.height / 2)
                )
            )
        }
        
        // Top/Bottom edge glow
        if abs(dirY) > 0.1 {
            let edgeY = dirY > 0 ? size.height : 0.0
            let gradient = Gradient(colors: [
                glowColor.opacity(pulseAlpha * abs(dirY)),
                .clear
            ])
            context.fill(
                Path(CGRect(x: 0, y: edgeY - 50, width: size.width, height: 100)),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: size.width / 2, y: edgeY),
                    endPoint: CGPoint(x: size.width / 2, y: dirY > 0 ? edgeY - 100 : edgeY + 100)
                )
            )
        }
        
        // Burst particles from shake
        let burstCount = Int(energy * 40)
        for i in 0..<burstCount {
            let seed = Double(i) * 2.718281828 + phase
            let angle = seed * 2.399963229728653
            let distance = fmod(seed * 0.618033988749895, 1.0) * maxDimension * 0.5 * energy
            
            let x = center.x + Foundation.cos(angle) * distance
            let y = center.y + Foundation.sin(angle) * distance
            
            let particleAlpha = energy * 0.4 * (1.0 - distance / (maxDimension * 0.5))
            let particleSize = 1.0 + energy * 3.0
            
            let colorIndex = i % max(colors.count, 1)
            let particleColor = colors.isEmpty ? Color.white : colors[colorIndex]
            
            context.fill(
                Path(ellipseIn: CGRect(x: x - particleSize, y: y - particleSize, width: particleSize * 2, height: particleSize * 2)),
                with: .radialGradient(
                    Gradient(colors: [particleColor.opacity(particleAlpha), .clear]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: particleSize * 2
                )
            )
        }
        
        // Central energy burst
        let burstRadius = maxDimension * 0.3 * energy
        let burstGradient = Gradient(colors: [
            .white.opacity(energy * 0.2),
            glowColor.opacity(energy * 0.1),
            .clear
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - burstRadius, y: center.y - burstRadius, width: burstRadius * 2, height: burstRadius * 2)),
            with: .radialGradient(burstGradient, center: center, startRadius: 0, endRadius: burstRadius)
        )
    }
}

#Preview {
    let state = KaleidoscopeState()
    GeometryReader { geo in
        KaleidoscopeCanvasView(state: state, size: geo.size)
    }
    .ignoresSafeArea()
    .background(.black)
}
