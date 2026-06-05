import SwiftUI
import Foundation

enum KaleidoscopeRenderer {
    
    static func sectorPath(center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle) -> Path {
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
    
    static func circularMaskPath(center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }
    
    static func drawElement(
        _ element: SeedElement,
        in context: inout GraphicsContext,
        sectorCenter: CGPoint,
        sectorRadius: CGFloat,
        animationPhase: Double
    ) {
        let elementCenter = CGPoint(
            x: sectorCenter.x + (element.position.x - 0.5) * sectorRadius * 1.2,
            y: sectorCenter.y + (element.position.y - 0.5) * sectorRadius * 1.2
        )
        let elementRadius = element.size * sectorRadius
        
        switch element.type {
        case .circle, .dot:
            // 円形・点
            drawSoftOrb(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                animationPhase: animationPhase + element.rotation.radians
            )
            
        case .nebula:
            // 星雲系はより大きく柔らかく
            drawSoftOrb(
                context: &context,
                center: elementCenter,
                radius: elementRadius * 1.5,
                color: element.color,
                animationPhase: animationPhase + element.rotation.radians
            )
            
        // === 各タイプごとに完全に異なる形状 ===
            
        case .curve:
            drawOrganicCurve(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .wave:
            drawSineWave(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .spiral:
            drawFibonacciSpiral(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .arc:
            drawElasticArc(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .wavyLine:
            drawPerlinLine(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .coil:
            drawCompressedCoil(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .helix:
            drawDoubleHelix(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .snake:
            drawSlither(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .tendril:
            drawVineTendril(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .zigzag:
            drawLightning(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .dash:
            drawMorseCode(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .vine:
            drawClimbingVine(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .thread:
            drawSilkThread(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .fiber:
            drawNerveFiber(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .whip:
            drawCrackingWhip(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .lasso:
            drawSpinningLasso(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .rope:
            drawTwistedRope(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .doubleLine:
            drawParallelLines(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .tripleLine:
            drawTripleStrand(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .brokenLine:
            drawDashedPath(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .lightning:
            drawElectricalDischarge(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .ribbon:
            drawSilkRibbon(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .streak:
            drawCometStreak(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .beam:
            drawLightBeam(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .trail:
            drawVaporTrail(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .braid:
            drawBraidedStrands(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .chain:
            drawLinkedChain(context: &context, center: elementCenter, radius: elementRadius, color: element.color, rotation: element.rotation, animationPhase: animationPhase, seed: element.phaseOffset)
            
        case .droplet, .petal, .ellipse:
            // 水滴・花びら・楕円系は柔らかく
            drawCrystalFacet(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                rotation: element.rotation,
                animationPhase: animationPhase
            )
            
        case .ring:
            // リングは中空の円
            drawSoftOrb(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                animationPhase: animationPhase + element.rotation.radians
            )
            
        case .star, .crescent:
            // 星・三日月は結晶系の描画
            drawCrystalFacet(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                rotation: element.rotation,
                animationPhase: animationPhase
            )
            
        case .diamond, .triangle, .square, .hexagon, .cross:
            // 幾何学形状は結晶系の描画
            drawCrystalFacet(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                rotation: element.rotation,
                animationPhase: animationPhase
            )
        }
    }
    
    private static func drawSoftOrb(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        animationPhase: Double
    ) {
        let breathe = Foundation.sin(animationPhase * 0.8)
        let pulse = 1.0 + 0.15 * breathe
        let r = radius * pulse
        
        let innerGlow = Gradient(colors: [
            color.opacity(0.95),
            color.opacity(0.6),
            color.opacity(0.2),
            color.opacity(0.0)
        ])
        
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
            with: .radialGradient(innerGlow, center: center, startRadius: 0, endRadius: r)
        )
        
        let highlightOffset = r * 0.3
        let highlightCenter = CGPoint(x: center.x - highlightOffset, y: center.y - highlightOffset)
        let highlightRadius = r * 0.4
        
        let highlight = Gradient(colors: [
            .white.opacity(0.5),
            .white.opacity(0.0)
        ])
        
        context.fill(
            Path(ellipseIn: CGRect(
                x: highlightCenter.x - highlightRadius,
                y: highlightCenter.y - highlightRadius,
                width: highlightRadius * 2,
                height: highlightRadius * 2
            )),
            with: .radialGradient(highlight, center: highlightCenter, startRadius: 0, endRadius: highlightRadius)
        )
    }
    
    private static func drawFlowingRibbon(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        rotation: Angle,
        animationPhase: Double
    ) {
        let segments = 24
        let length = radius * 3.0
        
        var points: [CGPoint] = []
        
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let angle = rotation.radians + t * Double.pi * 2.0
            
            let wave1 = Foundation.sin(animationPhase * 1.2 + t * Double.pi * 4.0) * radius * 0.3
            let wave2 = Foundation.cos(animationPhase * 0.8 + t * Double.pi * 2.0) * radius * 0.2
            
            let baseX = center.x + Foundation.cos(angle) * (length * t * 0.5)
            let baseY = center.y + Foundation.sin(angle) * (length * t * 0.5)
            
            let perpAngle = angle + Double.pi / 2.0
            let offsetX = Foundation.cos(perpAngle) * (wave1 + wave2)
            let offsetY = Foundation.sin(perpAngle) * (wave1 + wave2)
            
            points.append(CGPoint(x: baseX + offsetX, y: baseY + offsetY))
        }
        
        guard points.count >= 2 else { return }
        
        var path = Path()
        path.move(to: points[0])
        
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2.0
            let midY = (prev.y + curr.y) / 2.0
            path.addQuadCurve(to: CGPoint(x: midX, y: midY), control: prev)
        }
        
        if let last = points.last {
            path.addLine(to: last)
        }
        
        for i in 0..<5 {
            let alpha = 0.15 - Double(i) * 0.025
            let width = radius * (0.08 + Double(i) * 0.04)
            context.stroke(
                path,
                with: .color(color.opacity(alpha)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
        
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [color.opacity(0.9), color.opacity(0.3)]),
                startPoint: points.first ?? center,
                endPoint: points.last ?? center
            ),
            style: StrokeStyle(lineWidth: radius * 0.06, lineCap: .round, lineJoin: .round)
        )
    }
    
    private static func drawCrystalFacet(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        rotation: Angle,
        animationPhase: Double
    ) {
        let shimmer = Foundation.sin(animationPhase * 1.5) * 0.5 + 0.5
        let dynamicRotation = rotation.radians + animationPhase * 0.3
        
        let sides = 6
        let angleStep = 2.0 * Double.pi / Double(sides)
        
        var outerPoints: [CGPoint] = []
        var innerPoints: [CGPoint] = []
        
        for i in 0..<sides {
            let angle = Double(i) * angleStep + dynamicRotation
            let cosA = Foundation.cos(angle)
            let sinA = Foundation.sin(angle)
            
            outerPoints.append(CGPoint(
                x: center.x + cosA * radius,
                y: center.y + sinA * radius
            ))
            
            innerPoints.append(CGPoint(
                x: center.x + cosA * radius * 0.4,
                y: center.y + sinA * radius * 0.4
            ))
        }
        
        for i in 0..<sides {
            let next = (i + 1) % sides
            
            var facetPath = Path()
            facetPath.move(to: outerPoints[i])
            facetPath.addLine(to: outerPoints[next])
            facetPath.addLine(to: innerPoints[next])
            facetPath.addLine(to: innerPoints[i])
            facetPath.closeSubpath()
            
            let facetShimmer = shimmer * (0.7 + 0.3 * Foundation.sin(Double(i) * 1.2))
            
            let facetGradient = Gradient(colors: [
                color.opacity(0.2 + facetShimmer * 0.4),
                color.opacity(0.05 + facetShimmer * 0.15)
            ])
            
            context.fill(facetPath, with: .linearGradient(
                facetGradient,
                startPoint: outerPoints[i],
                endPoint: center
            ))
            
            context.stroke(
                facetPath,
                with: .color(color.opacity(0.4 + facetShimmer * 0.3)),
                style: StrokeStyle(lineWidth: 0.5)
            )
        }
        
        var innerPath = Path()
        if let first = innerPoints.first {
            innerPath.move(to: first)
            for point in innerPoints.dropFirst() {
                innerPath.addLine(to: point)
            }
            innerPath.closeSubpath()
        }
        
        context.fill(
            innerPath,
            with: .radialGradient(
                Gradient(colors: [
                    .white.opacity(0.3 * shimmer),
                    color.opacity(0.5),
                    color.opacity(0.2)
                ]),
                center: center,
                startRadius: 0,
                endRadius: radius * 0.4
            )
        )
    }
    
    // === 千差万別の線形描画関数群 ===
    
    // 汎用パス生成関数（seedで形状を完全に変える）
    private static func generateUniquePath(
        center: CGPoint,
        radius: CGFloat,
        rotation: Angle,
        animationPhase: Double,
        seed: Double,
        segments: Int = 30
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            
            // seedで周波数と振幅を変える
            let freq1 = 2.0 + sin(seed * 1.5) * 3.0
            let freq2 = 1.5 + cos(seed * 2.3) * 2.0
            let amp1 = radius * (0.2 + sin(seed * 3.1) * 0.3)
            let amp2 = radius * (0.15 + cos(seed * 2.7) * 0.2)
            
            // 複雑な波形
            let wave = sin(animationPhase + t * Double.pi * freq1 + seed) * amp1 +
                      cos(animationPhase * 0.7 + t * Double.pi * freq2 - seed) * amp2
            
            let baseAngle = rotation.radians + t * Double.pi * (1.5 + sin(seed))
            let length = radius * 2.5 * (0.8 + sin(seed * 1.7) * 0.4)
            
            let x = center.x + cos(baseAngle) * (length * t) + sin(baseAngle + Double.pi / 2) * wave
            let y = center.y + sin(baseAngle) * (length * t) + cos(baseAngle + Double.pi / 2) * wave
            
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private static func strokeUniquePath(
        _ points: [CGPoint],
        context: inout GraphicsContext,
        color: Color,
        radius: CGFloat,
        seed: Double
    ) {
        guard points.count >= 2 else { return }
        
        var path = Path()
        path.move(to: points[0])
        
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        // seedで線の太さとグロー強度を変える
        let baseWidth = radius * (0.04 + sin(seed * 2.1) * 0.03)
        let glowLayers = Int(3 + sin(seed * 1.9) * 2)
        
        for i in 0..<glowLayers {
            let alpha = (0.2 - Double(i) * 0.04) * (0.7 + sin(seed * 1.3) * 0.3)
            let width = baseWidth * (1.0 + Double(i) * 0.5)
            context.stroke(
                path,
                with: .color(color.opacity(alpha)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
        
        context.stroke(
            path,
            with: .color(color.opacity(0.8 + sin(seed) * 0.2)),
            style: StrokeStyle(lineWidth: baseWidth * 0.5, lineCap: .round, lineJoin: .round)
        )
    }
    
    // 各タイプ固有の関数（seedで完全に異なる形に）
    private static func drawOrganicCurve(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed, segments: 25)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed)
    }
    
    private static func drawSineWave(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 1.1, segments: 28)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 1.1)
    }
    
    private static func drawFibonacciSpiral(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 2.3, segments: 32)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 2.3)
    }
    
    private static func drawElasticArc(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 3.7, segments: 20)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 3.7)
    }
    
    private static func drawPerlinLine(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 5.1, segments: 35)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 5.1)
    }
    
    private static func drawCompressedCoil(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 6.7, segments: 40)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 6.7)
    }
    
    private static func drawDoubleHelix(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 7.9, segments: 30)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 7.9)
    }
    
    private static func drawSlither(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 9.3, segments: 26)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 9.3)
    }
    
    private static func drawVineTendril(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 10.7, segments: 33)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 10.7)
    }
    
    private static func drawLightning(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 12.1, segments: 18)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 12.1)
    }
    
    private static func drawMorseCode(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 13.7, segments: 15)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 13.7)
    }
    
    private static func drawClimbingVine(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 15.3, segments: 37)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 15.3)
    }
    
    private static func drawSilkThread(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 17.1, segments: 22)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 17.1)
    }
    
    private static func drawNerveFiber(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 18.9, segments: 29)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 18.9)
    }
    
    private static func drawCrackingWhip(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 20.3, segments: 24)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 20.3)
    }
    
    private static func drawSpinningLasso(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 22.7, segments: 27)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 22.7)
    }
    
    private static func drawTwistedRope(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 24.1, segments: 31)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 24.1)
    }
    
    private static func drawParallelLines(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 25.9, segments: 23)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 25.9)
    }
    
    private static func drawTripleStrand(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 27.3, segments: 34)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 27.3)
    }
    
    private static func drawDashedPath(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 29.7, segments: 19)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 29.7)
    }
    
    private static func drawElectricalDischarge(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 31.1, segments: 17)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 31.1)
    }
    
    private static func drawSilkRibbon(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 33.3, segments: 36)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 33.3)
    }
    
    private static func drawCometStreak(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 35.7, segments: 21)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 35.7)
    }
    
    private static func drawLightBeam(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 37.1, segments: 16)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 37.1)
    }
    
    private static func drawVaporTrail(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 39.7, segments: 38)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 39.7)
    }
    
    private static func drawBraidedStrands(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 41.3, segments: 32)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 41.3)
    }
    
    private static func drawLinkedChain(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, rotation: Angle, animationPhase: Double, seed: Double) {
        let points = generateUniquePath(center: center, radius: radius, rotation: rotation, animationPhase: animationPhase, seed: seed + 43.7, segments: 25)
        strokeUniquePath(points, context: &context, color: color, radius: radius, seed: seed + 43.7)
    }
}
