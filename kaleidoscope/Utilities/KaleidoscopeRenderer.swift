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
        case .circle:
            drawSoftOrb(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                animationPhase: animationPhase + element.rotation.radians
            )
            
        case .curve:
            drawFlowingRibbon(
                context: &context,
                center: elementCenter,
                radius: elementRadius,
                color: element.color,
                rotation: element.rotation,
                animationPhase: animationPhase
            )
            
        case .polygon:
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
}
