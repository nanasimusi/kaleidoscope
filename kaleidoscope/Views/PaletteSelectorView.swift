import SwiftUI

struct PaletteSelectorView: View {
    let currentPalette: ColorPalette
    let onSelect: (ColorPalette) -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(ColorPalette.allCases) { palette in
                PaletteButton(
                    palette: palette,
                    isSelected: palette == currentPalette,
                    action: { onSelect(palette) }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PaletteButton: View {
    let palette: ColorPalette
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: palette.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: palette.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2.5)
                )
                .shadow(color: isSelected ? palette.gradientColors.first?.opacity(0.5) ?? .clear : .clear, radius: 8)
                
                Text(palette.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PaletteSelectorView(currentPalette: .dawn) { _ in }
        .background(.black)
}
