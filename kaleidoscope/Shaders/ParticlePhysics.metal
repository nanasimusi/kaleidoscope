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
    
    // 衝突反発力 + Boids群れ行動（軽量版：最大5個チェック）
    float collisionForceX = 0.0;
    float collisionForceY = 0.0;
    
    // Boids用
    float avgVelocityX = 0.0;
    float avgVelocityY = 0.0;
    float centerX = 0.0;
    float centerY = 0.0;
    float separationX = 0.0;
    float separationY = 0.0;
    uint nearbyCount = 0;
    
    uint checkedCount = 0;
    const uint maxChecks = 5;
    const float collisionRadiusSq = 0.08 * 0.08;
    const float baseRepulsion = 0.4 * particle.sociability;
    const float awarenessRadiusSq = 0.15 * 0.15 * particle.sociability;
    
    for (uint j = 0; j < params.particleCount && checkedCount < maxChecks; j++) {
        if (j == id) continue;
        
        device Particle& other = particles[j];
        float dx = other.position.x - particle.position.x;
        float dy = other.position.y - particle.position.y;
        float distanceSq = dx * dx + dy * dy;
        
        if (distanceSq < collisionRadiusSq && distanceSq > 0.0001) {
            // 衝突反発
            float distance = sqrt(distanceSq);
            float angle = atan2(dy, dx);
            
            float randomAngle = sin(phase * float(id) + float(j)) * 0.3;
            angle += randomAngle;
            
            collisionForceX -= cos(angle) * baseRepulsion;
            collisionForceY -= sin(angle) * baseRepulsion;
            checkedCount++;
            
        } else if (distanceSq < awarenessRadiusSq && distanceSq > 0.001) {
            // Boids群れ行動
            nearbyCount++;
            
            // Alignment: 速度を集計
            avgVelocityX += other.velocity.x;
            avgVelocityY += other.velocity.y;
            
            // Cohesion: 位置を集計
            centerX += other.position.x;
            centerY += other.position.y;
            
            // Separation: 近すぎる場合の反発
            if (distanceSq < 0.01) {
                float separationStrength = (0.01 - distanceSq) * 10.0;
                separationX -= dx * separationStrength;
                separationY -= dy * separationStrength;
            }
            
            checkedCount++;
        }
    }
    
    // Boids力を適用
    if (nearbyCount > 0) {
        // Alignment
        avgVelocityX /= float(nearbyCount);
        avgVelocityY /= float(nearbyCount);
        float alignmentStrength = particle.sociability * 0.05;
        flowX += (avgVelocityX - particle.velocity.x) * alignmentStrength;
        flowY += (avgVelocityY - particle.velocity.y) * alignmentStrength;
        
        // Cohesion
        centerX /= float(nearbyCount);
        centerY /= float(nearbyCount);
        float cohesionStrength = particle.sociability * 0.0003;
        flowX += (centerX - particle.position.x) * cohesionStrength;
        flowY += (centerY - particle.position.y) * cohesionStrength;
        
        // Separation
        float separationStrength = particle.personality * 0.02;
        flowX += separationX * separationStrength;
        flowY += separationY * separationStrength;
    }
    
    // 磁場のような力場
    float touchCenterX = 0.5 + params.touchOffsetX * 0.1;
    float touchCenterY = 0.5 + params.touchOffsetY * 0.1;
    float toTouchX = touchCenterX - particle.position.x;
    float toTouchY = touchCenterY - particle.position.y;
    float distanceToTouch = length(float2(toTouchX, toTouchY));
    
    if (distanceToTouch > 0.01) {
        // 渦巻き力
        float vortexAngle = atan2(toTouchY, toTouchX) + 3.14159 / 2.0;
        float vortexStrength = (1.0 / (distanceToTouch + 0.1)) * 0.0008 * particle.curiosity;
        flowX += cos(vortexAngle) * vortexStrength;
        flowY += sin(vortexAngle) * vortexStrength;
        
        // 引力/斥力
        float magneticStrength = sin(phase * 0.5) * 0.0005;
        flowX += toTouchX * magneticStrength;
        flowY += toTouchY * magneticStrength;
    }
    
    // 中心からの呼吸
    float toCenterX = 0.5 - particle.position.x;
    float toCenterY = 0.5 - particle.position.y;
    float breathe = sin(phase * 0.3 + particle.phaseOffset) * 0.0002;
    flowX += toCenterX * breathe;
    flowY += toCenterY * breathe;
    
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
