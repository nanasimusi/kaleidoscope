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
    
    // 強い慣性（魚や鳥のように滑らかに泳ぐ・飛ぶ）
    float flowX = particle.velocity.x * 0.95;
    float flowY = particle.velocity.y * 0.95;
    
    // 各個体が独立してランダムに加速（全員バラバラに動く）
    float rand1 = fract(sin(phase * 12.9898 + particle.phaseOffset * 78.233) * 43758.5453);
    float rand2 = fract(sin(phase * 93.9898 + particle.phaseOffset * 47.593) * 21983.1253);
    float randomAccelX = (rand1 - 0.5) * 0.016 * (particle.personality + 0.3);
    float randomAccelY = (rand2 - 0.5) * 0.016 * (particle.personality + 0.3);
    flowX += randomAccelX;
    flowY += randomAccelY;
    
    // 好奇心が高い個体は大胆に動く
    if (particle.curiosity > 0.6) {
        float rand3 = fract(sin(phase * 45.1234 + particle.phaseOffset * 23.456) * 31456.7890);
        float rand4 = fract(sin(phase * 67.8901 + particle.phaseOffset * 34.567) * 54321.9876);
        float boldMoveX = (rand3 - 0.5) * 0.024 * particle.curiosity;
        float boldMoveY = (rand4 - 0.5) * 0.024 * particle.curiosity;
        flowX += boldMoveX;
        flowY += boldMoveY;
    }
    
    // 各個体が独自のタイミングでランダムに急加速
    float randTiming = fract(sin(phase * 78.4561 + particle.phaseOffset * 91.234) * 65432.1098);
    if (randTiming < 0.03) {  // 3%の確率（各個体バラバラ）
        float rand5 = fract(sin(phase * 34.5678 + particle.phaseOffset * 12.345) * 87654.3210);
        float rand6 = fract(sin(phase * 56.7890 + particle.phaseOffset * 89.012) * 98765.4321);
        float burstX = (rand5 - 0.5) * 0.05;
        float burstY = (rand6 - 0.5) * 0.05;
        flowX += burstX;
        flowY += burstY;
    }
    
    // 社交的な個体は活発に、内向的な個体は穏やか（でも止まらない）
    float socialityFactor = 0.5 + particle.sociability * 0.8;
    flowX *= socialityFactor;
    flowY *= socialityFactor;
    
    // デバイス傾きによる重力
    flowX += params.tiltX * 0.025 * params.kineticEnergy;
    flowY += params.tiltY * 0.025 * params.kineticEnergy;
    
    // タッチオフセットによる慣性
    flowX += params.touchOffsetX * 0.15 * particle.sociability;
    flowY += params.touchOffsetY * 0.15 * particle.sociability;
    
    // 衝突反発のみ（引力・Boidsは全て削除）
    float collisionForceX = 0.0;
    float collisionForceY = 0.0;
    float separationX = 0.0;
    float separationY = 0.0;
    
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
            // 衝突反発のみ
            float distance = sqrt(distanceSq);
            float angle = atan2(dy, dx);
            
            float randomAngle = sin(phase * float(id) + float(j)) * 0.3;
            angle += randomAngle;
            
            collisionForceX -= cos(angle) * baseRepulsion;
            collisionForceY -= sin(angle) * baseRepulsion;
            checkedCount++;
            
        } else if (distanceSq < 0.01) {
            // 近すぎる場合の追加反発
            float separationStrength = (0.01 - distanceSq) * 10.0;
            separationX -= dx * separationStrength;
            separationY -= dy * separationStrength;
            checkedCount++;
        }
    }
    
    // Separationを適用
    flowX += separationX * particle.personality * 0.03;
    flowY += separationY * particle.personality * 0.03;
    
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
