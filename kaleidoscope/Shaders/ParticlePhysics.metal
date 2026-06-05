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
    
    // === 予測不可能な有機的な動き（円運動を排除） ===
    
    float baseSpeed = 0.003 * params.kineticEnergy;
    float personalityInfluence = particle.personality * 1.5 + 0.5;
    
    // ランダムウォーク（ブラウン運動）- sin/cosによる円運動を排除
    float randomAngleChange = (sin(phase * 13.7 + particle.phaseOffset * 7.3) + 
                               cos(phase * 17.3 - particle.phaseOffset * 11.1)) * 0.5;
    
    // 現在の速度方向を少しずつ変える（慣性を保ちつつランダムに曲がる）
    float currentAngle = atan2(particle.velocity.y, particle.velocity.x);
    float newAngle = currentAngle + randomAngleChange * 0.1;
    
    // ランダムな強度変化
    float speedVariation = 1.0 + sin(phase * 7.1 + particle.phaseOffset * 5.3) * 0.3;
    
    // 新しい方向へ加速（円運動にならない）
    float flowX = cos(newAngle) * baseSpeed * personalityInfluence * speedVariation;
    float flowY = sin(newAngle) * baseSpeed * personalityInfluence * speedVariation;
    
    // ランダムな衝動（突然の方向転換）
    // Metal版ではランダム関数がないので疑似ランダムを使用
    float randomImpulse = fract(sin(phase * 12.9898 + particle.phaseOffset * 78.233) * 43758.5453);
    if (randomImpulse < 0.02) {  // 2%の確率
        float impulseAngle = randomImpulse * 6.28318;  // 0 to 2*PI
        float impulseStrength = (0.002 + randomImpulse * 0.004) * particle.curiosity;
        flowX += cos(impulseAngle) * impulseStrength;
        flowY += sin(impulseAngle) * impulseStrength;
    }
    
    // 探索行動（ランダムな方向へ探索）
    float randomExplore = fract(sin(phase * 23.1406 + particle.phaseOffset * 56.789) * 19134.4521);
    if (particle.curiosity > 0.6 && randomExplore < 0.05) {
        float exploreAngle = randomExplore * 6.28318;
        float exploreStrength = 0.004 * particle.curiosity;
        flowX += cos(exploreAngle) * exploreStrength;
        flowY += sin(exploreAngle) * exploreStrength;
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
    
    // === 環境からの影響（弱く） ===
    
    // タッチ位置からの微弱な影響（引き寄せない、押し出さない、ただ少し影響を受ける程度）
    if (particle.curiosity > 0.7) {
        float touchCenterX = 0.5 + params.touchOffsetX * 0.1;
        float touchCenterY = 0.5 + params.touchOffsetY * 0.1;
        float toTouchX = touchCenterX - particle.position.x;
        float toTouchY = touchCenterY - particle.position.y;
        float distanceToTouch = length(float2(toTouchX, toTouchY));
        
        if (distanceToTouch > 0.2 && distanceToTouch < 0.5) {
            // 非常に弱い引力（好奇心が高い個体のみ、遠い場合のみ）
            float weakAttraction = 0.0001 * particle.curiosity;
            flowX += toTouchX * weakAttraction;
            flowY += toTouchY * weakAttraction;
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
