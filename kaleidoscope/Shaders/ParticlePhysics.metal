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
    float2 goalPosition;
    float timeUntilNewGoal;
    float wanderAngle;
    bool isResting;
    float restTime;
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
    
    // === 生命体としての独立した行動システム ===
    
    float flowX = 0.0;
    float flowY = 0.0;
    
    // 1. 休憩中かチェック
    if (particle.isResting) {
        particle.restTime -= dt;
        if (particle.restTime <= 0) {
            particle.isResting = false;
            particle.timeUntilNewGoal = 0;
        }
        // 休憩中は微小な揺らぎのみ
        float tremor = 0.0001 * particle.personality;
        flowX = (sin(phase * particle.phaseOffset * 10.0) - 0.5) * tremor;
        flowY = (cos(phase * particle.phaseOffset * 10.0) - 0.5) * tremor;
    } else {
        // 2. 目的地がないまたは時間切れなら新しい目的地を設定
        if (particle.timeUntilNewGoal <= 0) {
            // 好奇心旺盛: 遠くを目指す
            if (particle.curiosity > 0.7) {
                float angle = particle.phaseOffset * 6.28318; // 0-2π
                float distance = 0.5 + particle.curiosity * 0.3;
                particle.goalPosition = float2(
                    0.5 + cos(angle) * distance,
                    0.5 + sin(angle) * distance
                );
            } 
            // 外向的: 端を目指す
            else if (particle.personality > 0.6) {
                float edge = fmod(particle.phaseOffset * 4.0, 4.0);
                if (edge < 1.0) {
                    particle.goalPosition = float2(particle.personality, 0.1);
                } else if (edge < 2.0) {
                    particle.goalPosition = float2(0.9, particle.personality);
                } else if (edge < 3.0) {
                    particle.goalPosition = float2(particle.personality, 0.9);
                } else {
                    particle.goalPosition = float2(0.1, particle.personality);
                }
            }
            // 内向的: 中央付近を目指す
            else {
                particle.goalPosition = float2(
                    0.4 + particle.personality * 0.3,
                    0.4 + particle.sociability * 0.3
                );
            }
            
            particle.timeUntilNewGoal = (1.0 - particle.curiosity) * 5.0 + 2.0;
            particle.wanderAngle = particle.phaseOffset * 6.28318;
        }
        
        // 3. 目的地に向かって移動
        float2 toGoal = particle.goalPosition - particle.position;
        float distanceToGoal = length(toGoal);
        
        if (distanceToGoal < 0.05) {
            // 到達: 休憩するか次へ
            if (particle.sociability < 0.3) {
                particle.isResting = true;
                particle.restTime = 1.0 + particle.personality;
            }
            particle.timeUntilNewGoal = 0;
        } else {
            // 目的地へ向かう
            float2 direction = toGoal / distanceToGoal;
            
            // さまよい成分
            particle.wanderAngle += (sin(phase * particle.personality * 10.0) - 0.5) * particle.personality;
            float wanderStrength = 0.3 * (1.0 - particle.sociability);
            float2 wander = float2(
                cos(particle.wanderAngle) * wanderStrength,
                sin(particle.wanderAngle) * wanderStrength
            );
            
            // 合成
            float seekStrength = 0.005 * (0.5 + particle.curiosity * 0.5);
            flowX = direction.x * seekStrength + wander.x * 0.001;
            flowY = direction.y * seekStrength + wander.y * 0.001;
            
            particle.timeUntilNewGoal -= dt;
        }
    }
    
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
