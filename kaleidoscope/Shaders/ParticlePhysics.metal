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
    
    // === 完全に自由な生物的動き ===
    
    // 基本となる慣性の力（現在の速度を維持しようとする）
    float flowX = particle.velocity.x * 0.5;
    float flowY = particle.velocity.y * 0.5;
    
    // ランダムな力を常に加える（ブラウン運動）
    // Metal版では疑似ランダムを使用
    float rand1 = fract(sin(phase * 12.9898 + particle.phaseOffset * 78.233) * 43758.5453);
    float rand2 = fract(sin(phase * 93.9898 + particle.phaseOffset * 47.593) * 21983.1253);
    float randomForceX = (rand1 - 0.5) * 0.002 * particle.personality;
    float randomForceY = (rand2 - 0.5) * 0.002 * particle.personality;
    flowX += randomForceX;
    flowY += randomForceY;
    
    // 好奇心が高い個体はより活発に動く
    if (particle.curiosity > 0.5) {
        float rand3 = fract(sin(phase * 45.1234 + particle.phaseOffset * 23.456) * 31456.7890);
        float rand4 = fract(sin(phase * 67.8901 + particle.phaseOffset * 34.567) * 54321.9876);
        float activeForceX = (rand3 - 0.5) * 0.004 * particle.curiosity;
        float activeForceY = (rand4 - 0.5) * 0.004 * particle.curiosity;
        flowX += activeForceX;
        flowY += activeForceY;
    }
    
    // 時々大きく方向転換（魚が急に向きを変えるような動き）
    float randTurn = fract(sin(phase * 78.4561 + particle.phaseOffset * 91.234) * 65432.1098);
    if (randTurn < 0.01) {
        float rand5 = fract(sin(phase * 34.5678 + particle.phaseOffset * 12.345) * 87654.3210);
        float rand6 = fract(sin(phase * 56.7890 + particle.phaseOffset * 89.012) * 98765.4321);
        float turnX = (rand5 - 0.5) * 0.02;
        float turnY = (rand6 - 0.5) * 0.02;
        flowX += turnX;
        flowY += turnY;
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
