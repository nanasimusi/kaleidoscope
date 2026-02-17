import SwiftUI

struct ContentView: View {
    @State private var viewModel = KaleidoscopeViewModel()
    @State private var motionManager = MotionManager()
    @State private var isDragging = false
    @State private var showUI = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                TimelineView(.animation) { timeline in
                    KaleidoscopeCanvasView(
                        state: viewModel.state,
                        size: geometry.size,
                        currentTime: timeline.date,
                        isDragging: isDragging,
                        onEvolve: { deltaTime in
                            viewModel.state.evolve(deltaTime: deltaTime)
                            viewModel.state.decayMotion(deltaTime: deltaTime)
                        }
                    )
                }
                .gesture(dragGesture(in: geometry.size))
                .gesture(magnificationGesture)
                .simultaneousGesture(tapGesture(in: geometry.size))
                
                VStack {
                    Spacer()
                    
                    if showUI {
                        VStack(spacing: 0) {
                            PaletteSelectorView(
                                currentPalette: viewModel.currentPalette,
                                onSelect: { viewModel.selectPalette($0) }
                            )
                            
                            ToolbarView(
                                symmetryCount: viewModel.state.symmetryCount,
                                onSaveScreenshot: { saveScreenshot() },
                                onIncrementSymmetry: { viewModel.incrementSymmetry() },
                                onDecrementSymmetry: { viewModel.decrementSymmetry() }
                            )
                        }
                        .background(
                            Rectangle()
                                .fill(.black.opacity(0.3))
                                .background(.ultraThinMaterial.opacity(0.4))
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                if viewModel.showingSaveConfirmation {
                    saveConfirmationOverlay
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.showingSaveConfirmation)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            startMotionDetection()
        }
        .onDisappear {
            motionManager.stopMotionUpdates()
        }
    }
    
    private func startMotionDetection() {
        motionManager.startMotionUpdates { acceleration, intensity in
            viewModel.state.applyMotion(acceleration: acceleration, intensity: intensity)
            
            // Haptic feedback for strong shakes
            if intensity > 0.6 {
                HapticsManager.shared.playImpact(intensity: intensity)
            }
        }
    }
    
    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                viewModel.handleDrag(value.translation, in: size)
            }
            .onEnded { _ in
                isDragging = false
                viewModel.handleDragEnded()
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                viewModel.handlePinch(scale)
            }
            .onEnded { _ in
                viewModel.handlePinchStarted()
            }
    }
    
    private func tapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let position = value.location
                let normalizedPosition = CGPoint(
                    x: position.x / size.width,
                    y: position.y / size.height
                )
                viewModel.handleTap(at: position, normalizedPosition: normalizedPosition)
            }
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showUI.toggle()
                }
            }
    }
    
    private func saveScreenshot() {
        let renderer = ImageRenderer(
            content: KaleidoscopeCanvasView(
                state: viewModel.state,
                size: CGSize(width: 1080, height: 1080)
            )
            .frame(width: 1080, height: 1080)
            .background(.black)
        )
        renderer.scale = 2.0
        viewModel.saveScreenshot(from: renderer)
    }
    
    private var saveConfirmationOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: viewModel.showingSaveConfirmation)
            
            Text("Saved to Photos")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

#Preview {
    ContentView()
}
