import SwiftUI

struct ContentView: View {
    @State private var viewModel = KaleidoscopeViewModel()
    @State private var motionManager = MotionManager()
    @State private var audioManager = AudioManager.shared
    @State private var isDragging = false
    @State private var showUI = true
    @State private var isMusicPlaying = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 万華鏡キャンバス - 全画面、120fps対応
                TimelineView(.animation(minimumInterval: 1.0/120.0, paused: false)) { timeline in
                    KaleidoscopeCanvasView(
                        state: viewModel.state,
                        size: geometry.size,
                        currentTime: timeline.date,
                        isDragging: isDragging,
                        onEvolve: { deltaTime in
                            viewModel.evolveAnimation(deltaTime: deltaTime)
                        }
                    )
                }
                .ignoresSafeArea()
                .drawingGroup()  // Metal加速でより滑らかに
                
                // UI要素レイヤー - ジェスチャー処理のために分離
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                }
                                viewModel.handleDrag(value.translation, in: geometry.size)
                                viewModel.addTapRipple(at: value.location, in: geometry.size)
                            }
                            .onEnded { _ in
                                isDragging = false
                                viewModel.handleDragEnded()
                            }
                    )
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                viewModel.handlePinch(value.magnification)
                            }
                    )
                    .simultaneousGesture(
                        RotationGesture()
                            .onChanged { value in
                                viewModel.handleRotation(value)
                            }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showUI.toggle()
                                }
                            }
                    )
                
                // 美しいUIコントロール - 全て下部に統合
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // メインツールバー
                        HStack(spacing: 24) {
                            // BGMボタン（タップで再生/停止、長押しで曲送り）
                            Button(action: {
                                isMusicPlaying.toggle()
                                if isMusicPlaying {
                                    audioManager.play()
                                } else {
                                    audioManager.stop()
                                }
                            }) {
                                Image(systemName: isMusicPlaying ? "music.note" : "music.note.slash")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(isMusicPlaying ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                                            .shadow(color: .black.opacity(0.3), radius: 8)
                                    )
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onEnded { _ in
                                        audioManager.nextTrack()
                                        if !isMusicPlaying {
                                            isMusicPlaying = true
                                        }
                                    }
                            )
                            
                            // 対称性調整
                            HStack(spacing: 16) {
                                Button(action: {
                                    viewModel.decrementSymmetry()
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                }
                                
                                Text("\(viewModel.state.symmetryCount)")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 40)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                                
                                Button(action: {
                                    viewModel.incrementSymmetry()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                }
                            }
                            
                            // スクリーンショットボタン
                            Button(action: {
                                viewModel.saveScreenshot(size: geometry.size)
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .shadow(color: .black.opacity(0.3), radius: 8)
                                    )
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : 100)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: showUI)
                    .padding(.bottom, 50)
                }
                .allowsHitTesting(showUI)
            }
            .onAppear {
                motionManager.onShake = {
                    viewModel.randomize()
                }
                motionManager.onTiltChange = { tilt in
                    viewModel.handleTiltChange(tilt)
                }
                motionManager.startMonitoring()
            }
            .onDisappear {
                motionManager.stopMonitoring()
            }
        }
    }
}

#Preview {
    ContentView()
}
