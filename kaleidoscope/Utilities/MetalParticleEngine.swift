import Metal
import simd
import SwiftUI

// Metal側のParticle構造体と対応
struct MetalParticle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var rotation: Float
    var rotationSpeed: Float
    var personality: Float
    var curiosity: Float
    var sociability: Float
    var depth: Float
    var phaseOffset: Float
    var goalPosition: SIMD2<Float>
    var timeUntilNewGoal: Float
    var wanderAngle: Float
    var isResting: Bool
    var restTime: Float
    var flockAlignment: Float
    var flockCohesion: Float
    var flockSeparation: Float
    var pulsePhase: Float
    var pulseFreq: Float
    var _pad0: Float = 0  // Metal側Particleと size == stride == 96 を一致させる
}

// Metal側のSimulationParams構造体と対応
struct MetalSimulationParams {
    var deltaTime: Float
    var phase: Float
    var touchX: Float
    var touchY: Float
    var touchOffsetX: Float
    var touchOffsetY: Float
    var tiltX: Float
    var tiltY: Float
    var particleCount: UInt32
    var kineticEnergy: Float
}

class MetalParticleEngine {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    
    private var particleBuffer: MTLBuffer?
    private var paramsBuffer: MTLBuffer
    
    private let maxParticles = 200
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return nil
        }
        self.device = device

        // Metal側Particle構造体とのレイアウト一致を保証（不一致は全モーション破壊につながる）
        assert(MemoryLayout<MetalParticle>.stride == 96,
               "MetalParticle layout drifted from Metal Particle struct (stride: \(MemoryLayout<MetalParticle>.stride))")


        guard let commandQueue = device.makeCommandQueue() else {
            print("Failed to create command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        // Metalライブラリとシェーダー関数を取得
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "updateParticles") else {
            print("Failed to load Metal library or function")
            return nil
        }
        
        // コンピュートパイプラインステートを作成
        do {
            pipelineState = try device.makeComputePipelineState(function: function)
        } catch {
            print("Failed to create compute pipeline state: \(error)")
            return nil
        }
        
        // パラメータバッファを作成
        guard let paramsBuffer = device.makeBuffer(
            length: MemoryLayout<MetalSimulationParams>.stride,
            options: .storageModeShared
        ) else {
            print("Failed to create params buffer")
            return nil
        }
        self.paramsBuffer = paramsBuffer
    }
    
    // 粒子バッファを初期化
    func initializeParticles(count: Int) {
        guard count <= maxParticles else {
            print("Particle count exceeds maximum: \(count) > \(maxParticles)")
            return
        }
        
        let bufferSize = MemoryLayout<MetalParticle>.stride * count
        particleBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)
    }
    
    // SeedElementからMetalParticleにデータをコピー
    func updateParticleData(from elements: [SeedElement]) {
        guard let buffer = particleBuffer else { return }
        
        let pointer = buffer.contents().bindMemory(
            to: MetalParticle.self,
            capacity: elements.count
        )
        
        for (index, element) in elements.enumerated() {
            pointer[index] = MetalParticle(
                position: SIMD2<Float>(Float(element.x), Float(element.y)),
                velocity: SIMD2<Float>(Float(element.vx), Float(element.vy)),
                rotation: Float(element.rotation.radians),
                rotationSpeed: Float(element.rotationSpeed),
                personality: Float(element.personality),
                curiosity: Float(element.curiosity),
                sociability: Float(element.sociability),
                depth: Float(element.depth),
                phaseOffset: Float(element.phaseOffset),
                goalPosition: SIMD2<Float>(
                    Float(element.goalPosition?.x ?? 0.5),
                    Float(element.goalPosition?.y ?? 0.5)
                ),
                timeUntilNewGoal: Float(element.timeUntilNewGoal),
                wanderAngle: Float(element.wanderAngle),
                isResting: element.isResting,
                restTime: Float(element.restTime),
                flockAlignment: Float(element.flockAlignment),
                flockCohesion: Float(element.flockCohesion),
                flockSeparation: Float(element.flockSeparation),
                pulsePhase: Float(element.pulsePhase),
                pulseFreq: Float(element.pulseFreq)
            )
        }
    }
    
    // MetalParticleからSeedElementにデータをコピー
    func readParticleData(to elements: inout [SeedElement]) {
        guard let buffer = particleBuffer else { return }
        
        let pointer = buffer.contents().bindMemory(
            to: MetalParticle.self,
            capacity: elements.count
        )
        
        for index in elements.indices {
            let metalParticle = pointer[index]
            elements[index].x = Double(metalParticle.position.x)
            elements[index].y = Double(metalParticle.position.y)
            elements[index].vx = Double(metalParticle.velocity.x)
            elements[index].vy = Double(metalParticle.velocity.y)
            elements[index].rotation = Angle(radians: Double(metalParticle.rotation))
            elements[index].goalPosition = CGPoint(
                x: Double(metalParticle.goalPosition.x),
                y: Double(metalParticle.goalPosition.y)
            )
            elements[index].timeUntilNewGoal = Double(metalParticle.timeUntilNewGoal)
            elements[index].wanderAngle = Double(metalParticle.wanderAngle)
            elements[index].isResting = metalParticle.isResting
            elements[index].restTime = Double(metalParticle.restTime)
            elements[index].pulsePhase = Double(metalParticle.pulsePhase)
        }
    }
    
    // 物理演算を実行
    func simulate(
        particleCount: Int,
        deltaTime: Double,
        phase: Double,
        touchX: Double,
        touchY: Double,
        touchOffsetX: Double,
        touchOffsetY: Double,
        tiltX: Double,
        tiltY: Double,
        kineticEnergy: Double
    ) {
        guard let buffer = particleBuffer else { return }
        
        // パラメータを設定
        let paramsPointer = paramsBuffer.contents().bindMemory(
            to: MetalSimulationParams.self,
            capacity: 1
        )
        paramsPointer.pointee = MetalSimulationParams(
            deltaTime: Float(deltaTime),
            phase: Float(phase),
            touchX: Float(touchX),
            touchY: Float(touchY),
            touchOffsetX: Float(touchOffsetX),
            touchOffsetY: Float(touchOffsetY),
            tiltX: Float(tiltX),
            tiltY: Float(tiltY),
            particleCount: UInt32(particleCount),
            kineticEnergy: Float(kineticEnergy)
        )
        
        // コマンドバッファを作成
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        // エンコーダーにパイプラインとバッファを設定
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(buffer, offset: 0, index: 0)
        computeEncoder.setBuffer(paramsBuffer, offset: 0, index: 1)
        
        // スレッドグループのサイズを設定
        let threadsPerThreadgroup = MTLSize(
            width: min(pipelineState.maxTotalThreadsPerThreadgroup, particleCount),
            height: 1,
            depth: 1
        )
        let threadgroupsPerGrid = MTLSize(
            width: (particleCount + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: 1,
            depth: 1
        )
        
        // コンピュートを実行
        computeEncoder.dispatchThreadgroups(
            threadgroupsPerGrid,
            threadsPerThreadgroup: threadsPerThreadgroup
        )
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
