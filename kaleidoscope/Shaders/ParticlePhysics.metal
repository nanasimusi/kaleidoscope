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
    float flockAlignment;
    float flockCohesion;
    float flockSeparation;
    float pulsePhase;      // 蛍の同期発光（Kuramoto振動子）の位相 [rad]
    float pulseFreq;       // 固有周波数 [rad/s]
    float _pad0;           // size == stride == 96 をSwift側と一致させる明示パディング
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
    
    // === 群れ: 近傍スキャン（boids + 蛍の位相結合を1ループで） ===
    // 注: in-place更新のため近傍は前/今フレームの値が混在するが、
    // 位置変化は毎フレーム ~0.0002 以下で力の大きさに対し誤差は桁違いに小さく許容
    float2 cohesionSum = float2(0.0);
    float2 alignSum = float2(0.0);
    float2 sepSum = float2(0.0);
    float phaseSum = 0.0;
    int neighborCount = 0;
    const float neighborRadius = 0.22;  // 正規化空間での知覚半径
    const float sepRadius = 0.055;      // これより近いと離れたくなる

    for (uint j = 0; j < params.particleCount; j++) {
        if (j == id) continue;
        float2 diff = particles[j].position - particle.position;
        float d = length(diff);
        if (d < neighborRadius && d > 1e-5) {
            cohesionSum += diff;
            alignSum += particles[j].velocity / 10.0;  // 他者のflow（velocityはflow×10形式）
            if (d < sepRadius) {
                sepSum -= (diff / d) * (1.0 - d / sepRadius);
            }
            phaseSum += sin(particles[j].pulsePhase - particle.pulsePhase);
            neighborCount++;
        }
    }

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
            // 複数の擬似ランダム値を生成（美しい多様性のため）
            float rand1 = fract(sin(phase * 12.9898 + particle.phaseOffset * 78.233) * 43758.5453);
            float rand2 = fract(sin(phase * 45.164 + particle.position.x * 93241.3141) * 28411.8234);
            float rand3 = fract(sin(phase * 67.891 + particle.position.y * 12345.6789) * 56789.1234);
            
            // 性格の組み合わせで無数のパターン
            float exploreFactor = particle.curiosity * particle.sociability;
            float calmFactor = (1.0 - particle.personality) * (1.0 - particle.curiosity);
            
            // 完全にランダムな直線的目的地（軌道運動なし）
            float padding = 0.05;
            
            if (exploreFactor > 0.6) {
                // 冒険的: 画面全体を自由に探索
                particle.goalPosition = float2(
                    padding + rand1 * (1.0 - padding * 2.0),
                    padding + rand2 * (1.0 - padding * 2.0)
                );
            } else if (calmFactor > 0.5) {
                // 落ち着いている: 中心付近をランダムに
                particle.goalPosition = float2(
                    0.35 + rand1 * 0.3,
                    0.35 + rand2 * 0.3
                );
            } else if (particle.personality > 0.7) {
                // 活発: 4つの象限をランダムに移動
                float quadrant = fmod(rand3 * 4.0, 4.0);
                if (quadrant < 1.0) {
                    // 左上
                    particle.goalPosition = float2(padding + rand1 * 0.4, padding + rand2 * 0.4);
                } else if (quadrant < 2.0) {
                    // 右上
                    particle.goalPosition = float2(0.5 + rand1 * 0.45, padding + rand2 * 0.4);
                } else if (quadrant < 3.0) {
                    // 左下
                    particle.goalPosition = float2(padding + rand1 * 0.4, 0.5 + rand2 * 0.45);
                } else {
                    // 右下
                    particle.goalPosition = float2(0.5 + rand1 * 0.45, 0.5 + rand2 * 0.45);
                }
            } else {
                // その他: 完全自由なランダム配置
                particle.goalPosition = float2(
                    padding + rand1 * (1.0 - padding * 2.0),
                    padding + rand2 * (1.0 - padding * 2.0)
                );
            }
            
            // 目的地変更の間隔も個性的に
            float baseInterval = 2.0 + rand3 * 4.0;
            float curiosityModifier = (1.0 - particle.curiosity) * 3.0;
            float moodModifier = particle.sociability * 2.0;
            particle.timeUntilNewGoal = baseInterval + curiosityModifier - moodModifier;
            
            particle.wanderAngle = rand1 * 6.28318;
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
            
            // さまよい成分（有機的で美しい揺らぎ）
            float timeScale = phase * (0.5 + particle.personality * 1.5);
            float wobble1 = sin(timeScale * 0.7 + particle.phaseOffset * 3.0);
            float wobble2 = cos(timeScale * 1.3 + particle.phaseOffset * 5.0);
            float wobble3 = sin(timeScale * 0.4 + particle.phaseOffset * 7.0);
            
            // dtスケールでフレームレート非依存に（CPU版と同一）
            particle.wanderAngle += (wobble1 * 0.3 + wobble2 * 0.2) * particle.personality * dt * 60.0;
            
            float wanderStrength = (0.2 + particle.sociability * 0.4) * (1.0 - particle.curiosity * 0.5);
            float2 wander = float2(
                cos(particle.wanderAngle) * wanderStrength + wobble3 * 0.1,
                sin(particle.wanderAngle) * wanderStrength + wobble2 * 0.1
            );
            
            // 合成（各個体が異なる速度で動く）
            float baseSpeed = 0.0008 + particle.curiosity * 0.0012;
            float moodVariation = particle.sociability * 0.0008;  // Metal版はmoodがないのでsociabilityで代用
            float personalitySpeed = particle.personality * 0.0006;
            
            float seekStrength = baseSpeed + moodVariation + personalitySpeed;

            // 到着減速: 目的地に近づくとふわっと減速し、優雅に到着する
            // （最低25%は維持し、完全には止まらない）
            float arrival = 0.25 + 0.75 * smoothstep(0.05, 0.25, distanceToGoal);
            seekStrength *= arrival;

            flowX = direction.x * seekStrength + wander.x * 0.0003;
            flowY = direction.y * seekStrength + wander.y * 0.0003;
            
            particle.timeUntilNewGoal -= dt;
        }
    }

    // === 群れの力: 目標追従+ゆらぎに重ねる微弱な二次層 ===
    // いずれも非周期的な力のため閉軌道は生まない。下流のヘディング慣性が滑らかに平滑化する
    if (neighborCount > 0 && !particle.isResting) {
        float invN = 1.0 / float(neighborCount);
        float soc = particle.sociability;

        // 結合: 仲間の重心へ緩やかに引かれる（seek力 0.0008-0.0026 の ~8-25% 上限）
        float2 cohesionDir = cohesionSum * invN;
        float cohesionLen = length(cohesionDir);
        if (cohesionLen > 1e-5) {
            flowX += (cohesionDir.x / cohesionLen) * 0.00020 * particle.flockCohesion * soc;
            flowY += (cohesionDir.y / cohesionLen) * 0.00020 * particle.flockCohesion * soc;
        }

        // 整列: 速度を加算せず「方向のみ」を近傍平均へ弱くブレンド（速度感を変えないため）
        float2 avgFlow = alignSum * invN;
        flowX += (avgFlow.x - flowX) * 0.12 * particle.flockAlignment * soc;
        flowY += (avgFlow.y - flowY) * 0.12 * particle.flockAlignment * soc;

        // 分離: 重なり回避（sociability非依存 — 個体の本能）
        flowX += sepSum.x * 0.00045 * particle.flockSeparation;
        flowY += sepSum.y * 0.00045 * particle.flockSeparation;
    }

    // ヘディング慣性: 前フレームの流れと目標方向を指数ブレンドし、
    // 方向転換が瞬間スナップではなく滑らかな曲線を描くようにする
    // （タップで velocity に加わった力もここでふわっと伝わり、優雅に減衰する）
    float2 prevFlow = particle.velocity / 10.0;
    float2 targetFlow = float2(flowX, flowY);
    float turnBlend = 1.0 - exp(-3.0 * dt);
    float2 flow = mix(prevFlow, targetFlow, turnBlend);

    // velocityには自発的な流れのみを保存（次フレームの慣性の基準。flow*10形式を維持）
    particle.velocity = flow * 10.0;

    // 環境からの微弱な影響（デバイス傾きによる重力）は位置にのみ作用させる
    // 慣性ブレンドのループに含めると傾きが蓄積・増幅されてしまうため
    flow.x += params.tiltX * 0.015;
    flow.y += params.tiltY * 0.015;

    // 生命体システム: 滑らかで美しい動き
    particle.position.x += flow.x * 60.0 * dt;
    particle.position.y += flow.y * 60.0 * dt;
    
    // 画面境界で折り返し（-1.2 〜 1.2）
    if (particle.position.x > 1.2) particle.position.x = -1.2;
    if (particle.position.x < -1.2) particle.position.x = 1.2;
    if (particle.position.y > 1.2) particle.position.y = -1.2;
    if (particle.position.y < -1.2) particle.position.y = 1.2;
    
    // 回転更新（CPU版と同一仕様: 減衰 + 度数法スケール）
    // 旧実装はrotationSpeed(±6〜12)をラジアン/秒として無減衰で積分していたため
    // 毎秒1〜2回転の高速自転が永続し「円軌道」に見えていた
    particle.rotationSpeed *= exp(-1.4 * dt);

    float rotationIntensity = 0.5 + particle.sociability * 0.5 + particle.personality * 0.3;

    // 有機的な微回転（CPU版のrandomRotation相当）
    float organicRotation = chaosNoise(phase, particle.phaseOffset) * 0.3 * rotationIntensity;

    // 傾きによる回転への影響（CPU版と同一）
    float tiltRotation = params.tiltX * 0.35 * (1.0 - particle.depth * 0.25);

    float degreesPerSecond = (particle.rotationSpeed + organicRotation + tiltRotation) * 45.0 * rotationIntensity;
    particle.rotation += degreesPerSecond * dt * (M_PI_F / 180.0);

    // === 蛍の発光同期（Kuramoto振動子）: 休憩中も明滅は続く ===
    // 弱結合 K と固有周波数の分散により部分同期になる
    // （近傍内で揃いかけては崩れる、全体メトロノーム化はしない）
    float coupling = 0.0;
    if (neighborCount > 0) {
        float K = 0.55 * particle.sociability;
        coupling = K * phaseSum / float(neighborCount);
    }
    particle.pulsePhase = fmod(particle.pulsePhase + (particle.pulseFreq + coupling) * dt, 6.2831853);
    if (particle.pulsePhase < 0.0) particle.pulsePhase += 6.2831853;
}
