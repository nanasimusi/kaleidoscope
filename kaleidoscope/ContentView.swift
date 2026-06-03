import SwiftUI

struct ContentView: View {
    @State private var viewModel = KaleidoscopeViewModel()
    @State private var motionManager = MotionManager()
    @State private var isDragging = false
    @State private var showUI = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TimelineView(.animation) { timeline in
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
                
                VStack {
                    HStack {
                        Spacer()
                        
                        PaletteSelectorView(
                            currentPalette: viewModel.currentPalette,
                            onSelect: { palette in
                                viewModel.changePalette(to: palette)
                            }
                        )
                        .opacity(showUI ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showUI)
                        .padding()
                    }
                    
                    Spacer()
                    
                    ToolbarView(
                        symmetryCount: viewModel.state.symmetryCount,
                        onSaveScreenshot: {
                            viewModel.saveScreenshot(size: geometry.size)
                        },
                        onIncrementSymmetry: {
                            viewModel.incrementSymmetry()
                        },
                        onDecrementSymmetry: {
                            viewModel.decrementSymmetry()
                        }
                    )
                    .opacity(showUI ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showUI)
                    .padding(.bottom, 40)
                }
            }
            .onTapGesture {
                showUI.toggle()
            }
            .onAppear {
                motionManager.onShake = {
                    viewModel.randomize()
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
