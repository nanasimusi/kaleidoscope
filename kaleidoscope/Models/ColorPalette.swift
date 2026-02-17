import SwiftUI

enum ColorPalette: String, CaseIterable, Identifiable {
    case dawn
    case ocean
    case aurora
    case prism
    case monochrome
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dawn: return "Dawn"
        case .ocean: return "Ocean"
        case .aurora: return "Aurora"
        case .prism: return "Prism"
        case .monochrome: return "Mono"
        }
    }
    
    var iconName: String {
        switch self {
        case .dawn: return "sunrise.fill"
        case .ocean: return "water.waves"
        case .aurora: return "sparkles"
        case .prism: return "rainbow"
        case .monochrome: return "circle.lefthalf.filled"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .dawn:
            return [
                Color(.displayP3, red: 0.98, green: 0.45, blue: 0.45, opacity: 1.0),
                Color(.displayP3, red: 1.0, green: 0.62, blue: 0.48, opacity: 1.0),
                Color(.displayP3, red: 1.0, green: 0.78, blue: 0.58, opacity: 1.0),
                Color(.displayP3, red: 0.98, green: 0.88, blue: 0.72, opacity: 1.0),
                Color(.displayP3, red: 0.65, green: 0.55, blue: 0.75, opacity: 1.0),
                Color(.displayP3, red: 0.45, green: 0.45, blue: 0.7, opacity: 1.0)
            ]
        case .ocean:
            return [
                Color(.displayP3, red: 0.0, green: 0.18, blue: 0.28, opacity: 1.0),
                Color(.displayP3, red: 0.0, green: 0.35, blue: 0.5, opacity: 1.0),
                Color(.displayP3, red: 0.0, green: 0.55, blue: 0.65, opacity: 1.0),
                Color(.displayP3, red: 0.3, green: 0.75, blue: 0.8, opacity: 1.0),
                Color(.displayP3, red: 0.6, green: 0.9, blue: 0.92, opacity: 1.0),
                Color(.displayP3, red: 0.9, green: 0.98, blue: 1.0, opacity: 1.0)
            ]
        case .aurora:
            return [
                Color(.displayP3, red: 0.1, green: 0.95, blue: 0.6, opacity: 1.0),
                Color(.displayP3, red: 0.2, green: 0.85, blue: 0.75, opacity: 1.0),
                Color(.displayP3, red: 0.4, green: 0.6, blue: 0.9, opacity: 1.0),
                Color(.displayP3, red: 0.55, green: 0.35, blue: 0.85, opacity: 1.0),
                Color(.displayP3, red: 0.75, green: 0.3, blue: 0.7, opacity: 1.0),
                Color(.displayP3, red: 0.9, green: 0.4, blue: 0.55, opacity: 1.0)
            ]
        case .prism:
            return [
                Color(.displayP3, red: 1.0, green: 0.35, blue: 0.45, opacity: 1.0),
                Color(.displayP3, red: 1.0, green: 0.6, blue: 0.2, opacity: 1.0),
                Color(.displayP3, red: 1.0, green: 0.85, blue: 0.3, opacity: 1.0),
                Color(.displayP3, red: 0.35, green: 0.85, blue: 0.45, opacity: 1.0),
                Color(.displayP3, red: 0.3, green: 0.65, blue: 1.0, opacity: 1.0),
                Color(.displayP3, red: 0.65, green: 0.4, blue: 0.95, opacity: 1.0)
            ]
        case .monochrome:
            return [
                Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0),
                Color(.displayP3, red: 0.85, green: 0.85, blue: 0.88, opacity: 1.0),
                Color(.displayP3, red: 0.65, green: 0.65, blue: 0.7, opacity: 1.0),
                Color(.displayP3, red: 0.45, green: 0.45, blue: 0.5, opacity: 1.0),
                Color(.displayP3, red: 0.25, green: 0.25, blue: 0.3, opacity: 1.0),
                Color(.displayP3, red: 0.1, green: 0.1, blue: 0.15, opacity: 1.0)
            ]
        }
    }
    
    var gradientColors: [Color] {
        [colors.first ?? .white, colors.last ?? .black]
    }
}
