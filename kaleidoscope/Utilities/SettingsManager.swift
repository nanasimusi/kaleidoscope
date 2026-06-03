import SwiftUI
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Keys
    private enum Keys {
        static let selectedPalette = "selectedPalette"
        static let symmetryCount = "symmetryCount"
        static let isAutoModeEnabled = "isAutoModeEnabled"
        static let isShakeRandomEnabled = "isShakeRandomEnabled"
        static let lastTrackIndex = "lastTrackIndex"
        static let bgmVolume = "bgmVolume"
    }
    
    // MARK: - Properties
    
    @Published var selectedPaletteIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedPaletteIndex, forKey: Keys.selectedPalette)
        }
    }
    
    @Published var symmetryCount: Int {
        didSet {
            UserDefaults.standard.set(symmetryCount, forKey: Keys.symmetryCount)
        }
    }
    
    @Published var isAutoModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutoModeEnabled, forKey: Keys.isAutoModeEnabled)
        }
    }
    
    @Published var isShakeRandomEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShakeRandomEnabled, forKey: Keys.isShakeRandomEnabled)
        }
    }
    
    @Published var lastTrackIndex: Int {
        didSet {
            UserDefaults.standard.set(lastTrackIndex, forKey: Keys.lastTrackIndex)
        }
    }
    
    @Published var bgmVolume: Float {
        didSet {
            UserDefaults.standard.set(bgmVolume, forKey: Keys.bgmVolume)
        }
    }
    
    // MARK: - Init
    
    private init() {
        // デフォルト値を設定
        let defaults = UserDefaults.standard
        
        // 初回起動時のデフォルト値を登録
        defaults.register(defaults: [
            Keys.selectedPalette: 0,
            Keys.symmetryCount: 6,
            Keys.isAutoModeEnabled: false,
            Keys.isShakeRandomEnabled: false,
            Keys.lastTrackIndex: 0,
            Keys.bgmVolume: 0.5
        ])
        
        // 保存された値を読み込み
        self.selectedPaletteIndex = defaults.integer(forKey: Keys.selectedPalette)
        self.symmetryCount = defaults.integer(forKey: Keys.symmetryCount)
        self.isAutoModeEnabled = defaults.bool(forKey: Keys.isAutoModeEnabled)
        self.isShakeRandomEnabled = defaults.bool(forKey: Keys.isShakeRandomEnabled)
        self.lastTrackIndex = defaults.integer(forKey: Keys.lastTrackIndex)
        self.bgmVolume = defaults.float(forKey: Keys.bgmVolume)
        
        // symmetryCountの範囲チェック
        if self.symmetryCount < 3 || self.symmetryCount > 24 {
            self.symmetryCount = 6
        }
        
        // trackIndexの範囲チェック
        if self.lastTrackIndex < 0 || self.lastTrackIndex >= AudioManager.tracks.count {
            self.lastTrackIndex = 0
        }
    }
}
