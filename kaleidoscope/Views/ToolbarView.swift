import SwiftUI

struct ToolbarView: View {
    let symmetryCount: Int
    let onSaveScreenshot: () -> Void
    let onIncrementSymmetry: () -> Void
    let onDecrementSymmetry: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSaveScreenshot) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.12))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: onDecrementSymmetry) {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(symmetryCount > 3 ? .white : .white.opacity(0.25))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.white.opacity(symmetryCount > 3 ? 0.12 : 0.05))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(symmetryCount <= 3)
                
                VStack(spacing: 2) {
                    Text("\(symmetryCount)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    
                    Text("folds")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(width: 50)
                
                Button(action: onIncrementSymmetry) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(symmetryCount < 12 ? .white : .white.opacity(0.25))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.white.opacity(symmetryCount < 12 ? 0.12 : 0.05))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(symmetryCount >= 12)
            }
            
            Spacer()
            
            Color.clear
                .frame(width: 48, height: 48)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ToolbarView(
        symmetryCount: 8,
        onSaveScreenshot: {},
        onIncrementSymmetry: {},
        onDecrementSymmetry: {}
    )
    .background(.black)
}
