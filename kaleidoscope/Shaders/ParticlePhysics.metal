#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float rotation;
    float rotationSpeed;
    float personality;
    float curiosity;
    float sociability;
    float depth;
    float phaseOffset;
};

struct SimulationParams {
    float deltaTime;
    float phase;
    float touchX;
    float touchY;
    float touchOffsetX;
    float touchOffsetY;
    float tiltX;
    float tiltY;
    uint particleCount;
    float kineticEnergy;
};

// カオス的なノイズ関数
float chaosNoise(float phase, float offset) {
    return sin(phase * 7.3 + offset * 2.7) * cos(phase * 5.1 - offset * 1.9);
}

// ランダムウォーク
float randomWalk(float phase, float personality, float curiosity) {
    return sin(phase * personality * 8.0) * cos(phase * curiosity * 6.0);
}

kernel void updateParticles(
    device Particle* particles [[buffer(0)]],
    constant SimulationParams& params [[buffer(1)]],
    uint id [[thread_position_in_grid]]
) {
    if (id >= params.particleCount) {
        return;
    }
    
    device Particle& particle = particles[id];
    
    // 基本パラメータ
    float dt = params.deltaTime;
    float phase = params.phase;
    
    // タッチによる引力（中心からの相対位置）
    float touchAttractionX = (params.touchX - 0.5) * 0.8;
    float touchAttractionY = (params.touchY - 0.5) * 0.8;
    
    // デバイス傾きによる重力的な流れ
    float tiltFlowX = params.tiltX * 0.15;
    float tiltFlowY = params.tiltY * 0.15;
    
    // 渦巻き流れ（personality依存）
    float angle = atan2(particle.position.y, particle.position.x);
    float radius = length(particle.position);
    float vortexStrength = 0.08 * particle.personality;
    float vortexX = -sin(angle) * vortexStrength;
    float vortexY = cos(angle) * vortexStrength;
    
    // 外向き/内向きのパルス（curiosity依存）
    float pulseStrength = sin(phase * 2.0 + particle.phaseOffset) * 0.03 * particle.curiosity;
    float pulseX = particle.position.x * pulseStrength;
    float pulseY = particle.position.y * pulseStrength;
    
    // カオス的なランダムノイズ
    float turbulence = chaosNoise(phase, particle.phaseOffset) * 0.15 * particle.personality;
    
    // ランダムウォーク（curiosity > 0.5の場合）
    float randomX = 0.0;
    float randomY = 0.0;
    if (particle.curiosity > 0.5) {
        float walk = randomWalk(phase, particle.personality, particle.curiosity);
        randomX = walk * 0.001;
        randomY = walk * 0.0008;
    }
    
    // 全体の流れを統合
    float flowX = touchAttractionX + tiltFlowX + vortexX + pulseX + turbulence + randomX;
    float flowY = touchAttractionY + tiltFlowY + vortexY + pulseY + turbulence + randomY;
    
    // タッチオフセットによる慣性
    float offsetInfluence = 0.15;
    flowX += params.touchOffsetX * offsetInfluence * particle.sociability;
    flowY += params.touchOffsetY * offsetInfluence * particle.sociability;
    
    // 衝突反発力（軽量版：最大5個チェック）
    float collisionForceX = 0.0;
    float collisionForceY = 0.0;
    uint checkedCount = 0;
    const uint maxChecks = 5;
    const float collisionRadiusSq = 0.08 * 0.08;
    const float baseRepulsion = 0.4 * particle.sociability;
    
    for (uint j = 0; j < params.particleCount && checkedCount < maxChecks; j++) {
        if (j == id) continue;
        
        device Particle& other = particles[j];
        float dx = other.position.x - particle.position.x;
        float dy = other.position.y - particle.position.y;
        float distanceSq = dx * dx + dy * dy;
        
        if (distanceSq < collisionRadiusSq && distanceSq > 0.0001) {
            float distance = sqrt(distanceSq);
            float angle = atan2(dy, dx);
            
            // ランダムな角度オフセットでカオス性を加える
            float randomAngle = sin(phase * float(id) + float(j)) * 0.3;
            angle += randomAngle;
            
            collisionForceX -= cos(angle) * baseRepulsion;
            collisionForceY -= sin(angle) * baseRepulsion;
            checkedCount++;
        }
    }
    
    // 速度更新
    particle.velocity.x += (flowX + collisionForceX) * dt * params.kineticEnergy;
    particle.velocity.y += (flowY + collisionForceY) * dt * params.kineticEnergy;
    
    // 速度減衰（空気抵抗）
    float damping = 0.98;
    particle.velocity.x *= damping;
    particle.velocity.y *= damping;
    
    // 位置更新
    particle.position.x += particle.velocity.x * dt;
    particle.position.y += particle.velocity.y * dt;
    
    // 画面境界で折り返し（-1.2 〜 1.2）
    if (particle.position.x > 1.2) particle.position.x = -1.2;
    if (particle.position.x < -1.2) particle.position.x = 1.2;
    if (particle.position.y > 1.2) particle.position.y = -1.2;
    if (particle.position.y < -1.2) particle.position.y = 1.2;
    
    // 回転更新
    particle.rotation += particle.rotationSpeed * dt;
}
