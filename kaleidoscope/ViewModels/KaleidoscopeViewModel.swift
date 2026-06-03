import SwiftUI
import Photos

@Observable
final class KaleidoscopeViewModel {
    var state: KaleidoscopeState
    var currentPalette: ColorPalette = .dawn
    var baseSymmetryForPinch: Int = 6
    var showingSaveConfirmation = false
    var saveError: String?
    
    private let hapticsManager = HapticsManager.shared
    
    init() {
        state = KaleidoscopeState()
    }
    
    func handleDrag(_ translation: CGSize, in size: CGSize) {
        let normalizedX = translation.width / size.width
        let normalizedY = translation.height / size.height
        state.touchOffset = CGPoint(x: normalizedX, y: normalizedY)
    }
    
    func handleDragEnded() {
        withAnimation(.easeOut(duration: 0.5)) {
            state.touchOffset = .zero
        }
    }
    
    func handlePinchStarted() {
        baseSymmetryForPinch = state.symmetryCount
    }
    
    func handlePinch(_ scale: CGFloat) {
        let previousSymmetry = state.symmetryCount
        state.setSymmetryFromPinch(scale: scale, baseSymmetry: baseSymmetryForPinch)
        if state.symmetryCount != previousSymmetry {
            hapticsManager.lightTap()
        }
    }
    
    func handleRotation(_ rotation: Angle) {
        state.globalRotation = rotation.radians * 0.5
    }
    
    func randomize() {
        hapticsManager.patternChange()
        state.randomize(with: currentPalette.colors)
    }
    
    func addTapRipple(at position: CGPoint, in size: CGSize) {
        hapticsManager.lightTap()
        let normalizedPosition = CGPoint(
            x: position.x / size.width,
            y: position.y / size.height
        )
        state.addTapRipple(at: position, normalizedPosition: normalizedPosition)
    }
    
    func changePalette(to palette: ColorPalette) {
        guard palette != currentPalette else { return }
        hapticsManager.mediumTap()
        currentPalette = palette
        state.updatePalette(palette)
    }
    
    func incrementSymmetry() {
        if state.symmetryCount < 12 {
            state.symmetryCount += 1
            hapticsManager.lightTap()
        }
    }
    
    func decrementSymmetry() {
        if state.symmetryCount > 3 {
            state.symmetryCount -= 1
            hapticsManager.lightTap()
        }
    }
    
    func evolveAnimation(deltaTime: Double) {
        state.evolve(deltaTime: deltaTime)
    }
    
    @MainActor
    func saveScreenshot(size: CGSize) {
        let renderer = ImageRenderer(content:
            KaleidoscopeCanvasView(
                state: state,
                size: size,
                currentTime: Date()
            )
        )
        renderer.scale = 3.0
        
        guard let uiImage = renderer.uiImage else {
            saveError = "Failed to render image"
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    self?.saveError = "Photo library access denied"
                    return
                }
                
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                self?.hapticsManager.mediumTap()
                self?.showingSaveConfirmation = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.showingSaveConfirmation = false
                }
            }
        }
    }
}
