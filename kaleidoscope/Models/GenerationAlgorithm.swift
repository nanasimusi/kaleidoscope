import Foundation
import SwiftUI

enum GenerationAlgorithm: CaseIterable {
    case random           // ランダム配置（現在の方式）
    case fibonacciSpiral  // フィボナッチスパイラル（黄金比）
    case fractalBranch    // フラクタル分岐
    case voronoi          // ボロノイ図
    case concentricRings  // 同心円リング
    case hexGrid          // 六角格子
    case goldenRatio      // 黄金比配置
    case mandala          // 曼荼羅パターン
    
    var name: String {
        switch self {
        case .random: return "Random Chaos"
        case .fibonacciSpiral: return "Fibonacci Spiral"
        case .fractalBranch: return "Fractal Branch"
        case .voronoi: return "Voronoi"
        case .concentricRings: return "Concentric Rings"
        case .hexGrid: return "Hex Grid"
        case .goldenRatio: return "Golden Ratio"
        case .mandala: return "Mandala"
        }
    }
    
    // 各アルゴリズムで粒子を生成
    func generate(
        count: Int,
        colors: [Color]
    ) -> [SeedElement] {
        switch self {
        case .random:
            return generateRandom(count: count, colors: colors)
        case .fibonacciSpiral:
            return generateFibonacciSpiral(count: count, colors: colors)
        case .fractalBranch:
            return generateFractalBranch(count: count, colors: colors)
        case .voronoi:
            return generateVoronoi(count: count, colors: colors)
        case .concentricRings:
            return generateConcentricRings(count: count, colors: colors)
        case .hexGrid:
            return generateHexGrid(count: count, colors: colors)
        case .goldenRatio:
            return generateGoldenRatio(count: count, colors: colors)
        case .mandala:
            return generateMandala(count: count, colors: colors)
        }
    }
    
    // MARK: - Random (既存の方式)
    
    private func generateRandom(count: Int, colors: [Color]) -> [SeedElement] {
        return (0..<count).map { index in
            let depth = Double(index) / Double(count)
            return SeedElement.random(colors: colors, colorIndex: index, depth: depth)
        }
    }
    
    // MARK: - Fibonacci Spiral (黄金比の螺旋)
    
    private func generateFibonacciSpiral(count: Int, colors: [Color]) -> [SeedElement] {
        let goldenAngle = Double.pi * (3.0 - sqrt(5.0))  // ≈ 137.5°
        
        return (0..<count).map { index in
            let i = Double(index)
            let angle = i * goldenAngle
            let radius = sqrt(i / Double(count)) * 0.45  // 0-0.45の範囲
            
            let x = 0.5 + radius * cos(angle)
            let y = 0.5 + radius * sin(angle)
            
            return createSeedElement(
                x: x, y: y,
                index: index,
                count: count,
                colors: colors
            )
        }
    }
    
    // MARK: - Fractal Branch (フラクタル分岐)
    
    private func generateFractalBranch(count: Int, colors: [Color]) -> [SeedElement] {
        var points: [(x: Double, y: Double, depth: Double)] = []
        
        // 中心から再帰的に分岐
        func branch(x: Double, y: Double, angle: Double, length: Double, depth: Int, maxDepth: Int) {
            if depth > maxDepth || points.count >= count {
                return
            }
            
            let endX = x + cos(angle) * length
            let endY = y + sin(angle) * length
            
            points.append((endX, endY, Double(depth) / Double(maxDepth)))
            
            if depth < maxDepth {
                // 左右に分岐（黄金角）
                let branchAngle1 = angle - Double.pi / 5.0
                let branchAngle2 = angle + Double.pi / 5.0
                let newLength = length * 0.7
                
                branch(x: endX, y: endY, angle: branchAngle1, length: newLength, depth: depth + 1, maxDepth: maxDepth)
                branch(x: endX, y: endY, angle: branchAngle2, length: newLength, depth: depth + 1, maxDepth: maxDepth)
            }
        }
        
        let maxDepth = Int(log2(Double(count)))
        branch(x: 0.5, y: 0.5, angle: -Double.pi / 2, length: 0.2, depth: 0, maxDepth: maxDepth)
        
        return points.prefix(count).enumerated().map { index, point in
            createSeedElement(
                x: point.x, y: point.y,
                index: index,
                count: count,
                colors: colors,
                depth: point.depth
            )
        }
    }
    
    // MARK: - Voronoi Diagram (ボロノイ図)
    
    private func generateVoronoi(count: Int, colors: [Color]) -> [SeedElement] {
        // ランダムなシード点を生成
        let seedPoints = (0..<Int(sqrt(Double(count)))).map { _ in
            (x: Double.random(in: 0.1...0.9), y: Double.random(in: 0.1...0.9))
        }
        
        var elements: [SeedElement] = []
        
        // グリッド上の各点で最も近いシード点を見つける
        let gridSize = Int(sqrt(Double(count)))
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                let x = Double(i) / Double(gridSize - 1)
                let y = Double(j) / Double(gridSize - 1)
                
                // 最も近いシード点を見つける
                var minDist = Double.infinity
                var nearestIndex = 0
                
                for (index, seed) in seedPoints.enumerated() {
                    let dx = x - seed.x
                    let dy = y - seed.y
                    let dist = sqrt(dx * dx + dy * dy)
                    
                    if dist < minDist {
                        minDist = dist
                        nearestIndex = index
                    }
                }
                
                elements.append(createSeedElement(
                    x: x, y: y,
                    index: elements.count,
                    count: count,
                    colors: colors,
                    colorIndex: nearestIndex % colors.count
                ))
                
                if elements.count >= count { break }
            }
            if elements.count >= count { break }
        }
        
        return elements
    }
    
    // MARK: - Concentric Rings (同心円)
    
    private func generateConcentricRings(count: Int, colors: [Color]) -> [SeedElement] {
        let rings = Int(sqrt(Double(count)))
        var elements: [SeedElement] = []
        
        for ring in 0..<rings {
            let radius = (Double(ring) + 1.0) / Double(rings) * 0.45
            let pointsInRing = max(6, ring * 6)
            
            for i in 0..<pointsInRing {
                if elements.count >= count { break }
                
                let angle = Double(i) / Double(pointsInRing) * 2.0 * Double.pi
                let x = 0.5 + radius * cos(angle)
                let y = 0.5 + radius * sin(angle)
                
                elements.append(createSeedElement(
                    x: x, y: y,
                    index: elements.count,
                    count: count,
                    colors: colors
                ))
            }
            if elements.count >= count { break }
        }
        
        return elements
    }
    
    // MARK: - Hex Grid (六角格子)
    
    private func generateHexGrid(count: Int, colors: [Color]) -> [SeedElement] {
        let gridSize = Int(sqrt(Double(count)))
        var elements: [SeedElement] = []
        
        let hexWidth = 1.0 / Double(gridSize)
        let hexHeight = hexWidth * sqrt(3.0) / 2.0
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if elements.count >= count { break }
                
                let offsetX = (row % 2 == 0) ? 0.0 : hexWidth * 0.5
                let x = Double(col) * hexWidth + offsetX + 0.1
                let y = Double(row) * hexHeight + 0.1
                
                if x < 0.9 && y < 0.9 {
                    elements.append(createSeedElement(
                        x: x, y: y,
                        index: elements.count,
                        count: count,
                        colors: colors
                    ))
                }
            }
            if elements.count >= count { break }
        }
        
        return elements
    }
    
    // MARK: - Golden Ratio (黄金比配置)
    
    private func generateGoldenRatio(count: Int, colors: [Color]) -> [SeedElement] {
        let phi = (1.0 + sqrt(5.0)) / 2.0  // 黄金比
        
        return (0..<count).map { index in
            let i = Double(index)
            
            // 黄金比に基づく配置
            let x = (i * phi).truncatingRemainder(dividingBy: 1.0)
            let y = (i / Double(count))
            
            // 中心からの螺旋配置
            let angle = i * 2.0 * Double.pi / phi
            let radius = sqrt(y) * 0.45
            
            let finalX = 0.5 + radius * cos(angle)
            let finalY = 0.5 + radius * sin(angle)
            
            return createSeedElement(
                x: finalX, y: finalY,
                index: index,
                count: count,
                colors: colors
            )
        }
    }
    
    // MARK: - Mandala (曼荼羅パターン)
    
    private func generateMandala(count: Int, colors: [Color]) -> [SeedElement] {
        let layers = Int(sqrt(Double(count)))
        var elements: [SeedElement] = []
        
        for layer in 0..<layers {
            let radius = (Double(layer) + 1.0) / Double(layers) * 0.45
            let symmetry = 8  // 8方向対称
            let pointsPerSymmetry = max(1, layer + 1)
            
            for sym in 0..<symmetry {
                for point in 0..<pointsPerSymmetry {
                    if elements.count >= count { break }
                    
                    let baseAngle = Double(sym) / Double(symmetry) * 2.0 * Double.pi
                    let offset = Double(point) / Double(pointsPerSymmetry) * (2.0 * Double.pi / Double(symmetry))
                    let angle = baseAngle + offset
                    
                    let x = 0.5 + radius * cos(angle)
                    let y = 0.5 + radius * sin(angle)
                    
                    elements.append(createSeedElement(
                        x: x, y: y,
                        index: elements.count,
                        count: count,
                        colors: colors
                    ))
                }
                if elements.count >= count { break }
            }
            if elements.count >= count { break }
        }
        
        return elements
    }
    
    // MARK: - Helper
    
    private func createSeedElement(
        x: Double,
        y: Double,
        index: Int,
        count: Int,
        colors: [Color],
        depth: Double? = nil,
        colorIndex: Int? = nil
    ) -> SeedElement {
        let finalDepth = depth ?? (Double(index) / Double(count))
        let finalColorIndex = colorIndex ?? index
        
        // 線形パターンを大量に
        let types: [ElementType] = [
            .curve, .curve, .curve, .curve, .curve,
            .tendril, .tendril, .tendril, .tendril,
            .wave, .wave, .wave,
            .spiral, .spiral, .spiral,
            .doubleLine, .doubleLine,
            .tripleLine, .tripleLine,
            .brokenLine, .wavyLine,
            .coil, .lightning,
            .vine, .vine, .vine,
            .ribbon, .thread, .fiber,
            .streak, .beam, .trail,
            .whip, .lasso, .snake,
            .helix, .braid, .chain, .rope,
            .arc, .zigzag, .dash,
            .circle, .dot, .star,
            .droplet, .petal, .crescent,
            .diamond, .triangle, .square,
            .cross, .ellipse, .hexagon,
            .ring, .nebula
        ]
        
        let sizeCategory = Int.random(in: 0...4)
        let sizeVariation: CGFloat
        switch sizeCategory {
        case 0: sizeVariation = CGFloat.random(in: 0.0008...0.003)
        case 1: sizeVariation = CGFloat.random(in: 0.002...0.008)
        case 2: sizeVariation = CGFloat.random(in: 0.005...0.015)
        case 3: sizeVariation = CGFloat.random(in: 0.010...0.025)
        default: sizeVariation = CGFloat.random(in: 0.015...0.040)
        }
        
        let personality = Double.random(in: 0...1)
        let curiosity = Double.random(in: 0...1)
        let sociability = Double.random(in: 0...1)
        
        let speedFactor = Double.random(in: 0.3...1.5)
        let isErratic = Bool.random()
        let isExtreme = Double.random(in: 0...1) > 0.85
        
        let baseColor = colors[finalColorIndex % colors.count]
        
        return SeedElement(
            position: CGPoint(x: x, y: y),
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
            phaseOffset: Double.random(in: 0...Double.pi * 4),
            colorIndex: finalColorIndex,
            depth: finalDepth,
            personality: isExtreme ? (Bool.random() ? 0.0 : 1.0) : personality,
            curiosity: isExtreme ? Double.random(in: 0.8...1.0) : curiosity,
            sociability: sociability,
            mood: Double.random(in: 0.2...0.8)
        )
    }
}
