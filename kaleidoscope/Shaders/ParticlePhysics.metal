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
    
    // === 予測不可能な有機的な動き ===
    
    float baseSpeed = 0.0015 * params.kineticEnergy;
    float personalityInfluence = particle.personality * 2.0 + 0.5;
    
    // パーリンノイズ風の複雑な動き
    float noiseX1 = sin(phase * 1.3 + particle.phaseOffset) * cos(phase * 0.7 + particle.personality * 10.0);
    float noiseX2 = sin(phase * 2.1 - particle.phaseOffset * 0.5) * cos(phase * 1.9 + particle.curiosity * 15.0);
    float noiseX3 = sin(phase * 0.5 + particle.sociability * 8.0) * cos(phase * 3.2 - particle.phaseOffset);
    
    float noiseY1 = cos(phase * 1.5 - particle.phaseOffset) * sin(phase * 0.9 + particle.personality * 12.0);
    float noiseY2 = cos(phase * 1.8 + particle.phaseOffset * 0.7) * sin(phase * 2.3 - particle.curiosity * 18.0);
    float noiseY3 = cos(phase * 0.7 - particle.sociability * 9.0) * sin(phase * 2.9 + particle.phaseOffset);
    
    // レヴィフライト（突発的な大きな移動）
    float levyFlight = sin(phase * 0.3 + particle.phaseOffset * 3.0);
    float jumpMultiplier = (levyFlight > 0.95) ? 5.0 : 1.0;
    
    // フラクタルノイズ
    float flowX = (noiseX1 * 0.4 + noiseX2 * 0.3 + noiseX3 * 0.3) * baseSpeed * personalityInfluence * jumpMultiplier;
    float flowY = (noiseY1 * 0.4 + noiseY2 * 0.3 + noiseY3 * 0.3) * baseSpeed * personalityInfluence * jumpMultiplier;
    
    // 探索行動
    if (particle.curiosity > 0.6) {
        float exploreAngle = phase * particle.curiosity * 2.0 + particle.phaseOffset;
        float exploreRadius = sin(phase * 0.4 + particle.curiosity * 5.0) * 0.002;
        flowX += cos(exploreAngle) * exploreRadius * particle.curiosity;
        flowY += sin(exploreAngle) * exploreRadius * particle.curiosity;
    }
    
    // 内向的な粒子の静止
    if (particle.personality < 0.3) {
        float pauseProbability = sin(phase * 0.8 + particle.phaseOffset * 2.0);
        if (pauseProbability > 0.7) {
            flowX *= 0.1;
            flowY *= 0.1;
        }
    }
    
    // デバイス傾きによる重力
    flowX += params.tiltX * 0.025 * params.kineticEnergy;
    flowY += params.tiltY * 0.025 * params.kineticEnergy;
    
    // タッチオフセットによる慣性
    flowX += params.touchOffsetX * 0.15 * particle.sociability;
    flowY += params.touchOffsetY * 0.15 * particle.sociability;
    
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
    
    // 生物的な自由な躍動
    float touchCenterX = 0.5 + params.touchOffsetX * 0.1;
    float touchCenterY = 0.5 + params.touchOffsetY * 0.1;
    float toTouchX = touchCenterX - particle.position.x;
    float toTouchY = touchCenterY - particle.position.y;
    float distanceToTouch = length(float2(toTouchX, toTouchY));
    
    if (distanceToTouch > 0.01) {
        // 好奇心が高い個体は近づく、低い個体は避ける
        float approachOrAvoid = (particle.curiosity - 0.5) * 2.0;  // -1.0 to 1.0
        float touchInfluence = 0.0003 * approachOrAvoid / (distanceToTouch + 0.5);
        flowX += toTouchX * touchInfluence;
        flowY += toTouchY * touchInfluence;
        
        // 時々タッチ位置の周りを泳ぐような動き
        if (particle.curiosity > 0.6) {
            float swimAngle = atan2(toTouchY, toTouchX) + sin(phase + particle.phaseOffset) * 1.5;
            float swimStrength = 0.0004 * particle.curiosity;
            flowX += cos(swimAngle) * swimStrength;
            flowY += sin(swimAngle) * swimStrength;
        }
    }
    
    // 各個体が独自の「目的地」を持ち、そこへ向かう
    float targetX = 0.3 + sin(particle.phaseOffset * 2.0 + phase * 0.1) * 0.4;
    float targetY = 0.3 + cos(particle.phaseOffset * 3.0 + phase * 0.15) * 0.4;
    float toTargetX = targetX - particle.position.x;
    float toTargetY = targetY - particle.position.y;
    float targetDistance = length(float2(toTargetX, toTargetY));
    
    if (targetDistance > 0.05) {
        // 目的地へ向かう力
        float targetSeekingStrength = 0.0002 * particle.personality;
        flowX += toTargetX * targetSeekingStrength;
        flowY += toTargetY * targetSeekingStrength;
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
