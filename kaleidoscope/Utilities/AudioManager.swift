import AVFoundation
import Accelerate
import Combine

final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // 利用可能な楽曲リスト
    static let tracks: [String] = [
        "Nebula Glass Pulse",
        "Event Horizon Bloom",
        "Void Prayer",
        "Galaxy Birth Sequence",
        "Birth of Orbits"
    ]
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    
    @Published private(set) var isPlaying = false
    @Published private(set) var volume: Float = 0.5
    @Published private(set) var currentTrackIndex: Int = 0
    
    var currentTrackName: String {
        Self.tracks[currentTrackIndex]
    }
    
    // MARK: - 音楽解析データ（図形シンクロ用）
    
    /// 現在のビート強度（0.0〜1.0）- 低音のパワー
    @Published private(set) var beatIntensity: Float = 0
    
    /// 現在のメロディ強度（0.0〜1.0）- 中高音のパワー
    @Published private(set) var melodyIntensity: Float = 0
    
    /// 高音の強度（0.0〜1.0）- シンバル等
    @Published private(set) var highFrequencyIntensity: Float = 0
    
    /// 全体のエネルギー（0.0〜1.0）
    @Published private(set) var overallEnergy: Float = 0
    
    /// ビート検出フラグ
    @Published private(set) var isBeatDetected: Bool = false
    
    /// スペクトラムデータ（周波数帯域ごとのパワー）
    @Published private(set) var spectrum: [Float] = Array(repeating: 0, count: 8)
    
    // 解析用バッファ（再利用してメモリ確保を削減）
    private var fftSetup: vDSP_DFT_Setup?
    private let fftSize = 512  // 1024から512に削減（十分な精度を維持）
    private var previousBeatEnergy: Float = 0
    private var beatThreshold: Float = 0.3
    private var beatDecay: Float = 0.95
    
    // 再利用バッファ（毎回のアロケーションを回避）
    private var realInput: [Float] = []
    private var imagInput: [Float] = []
    private var realOutput: [Float] = []
    private var imagOutput: [Float] = []
    private var magnitudes: [Float] = []
    private var windowCoefficients: [Float] = []
    
    // スムージング用
    private var smoothedBeat: Float = 0
    private var smoothedMelody: Float = 0
    private var smoothedHigh: Float = 0
    private var smoothedEnergy: Float = 0
    
    // 計算頻度制限（30Hzに制限）
    private var lastFFTTime: CFAbsoluteTime = 0
    private let fftInterval: CFAbsoluteTime = 1.0 / 30.0
    
    private init() {
        setupAudioSession()
        setupFFT()
        setupBuffers()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // 実機で確実に音を出すため、mixWithOthersを外し、playbackカテゴリを使用
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session setup successful - Category: \(session.category.rawValue)")
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func setupFFT() {
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD)
    }
    
    private func setupBuffers() {
        // バッファの事前確保
        realInput = [Float](repeating: 0, count: fftSize)
        imagInput = [Float](repeating: 0, count: fftSize)
        realOutput = [Float](repeating: 0, count: fftSize)
        imagOutput = [Float](repeating: 0, count: fftSize)
        magnitudes = [Float](repeating: 0, count: fftSize / 2)
        
        // Hannウィンドウ係数の事前計算
        windowCoefficients = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&windowCoefficients, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
    
    // MARK: - BGM読み込み
    
    /// バンドル内の音声ファイル一覧を表示（デバッグ用）
    func debugPrintAvailableAudioFiles() {
        print("=== Checking Bundle for Audio Files ===")
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                let audioFiles = files.filter { 
                    $0.hasSuffix(".wav") || $0.hasSuffix(".mp3") || 
                    $0.hasSuffix(".m4a") || $0.hasSuffix(".aac")
                }
                print("Available audio files in bundle: \(audioFiles)")
                
                // 各トラックの存在確認
                for track in Self.tracks {
                    let found = audioFiles.contains { $0.hasPrefix(track) }
                    print("  Track '\(track)': \(found ? "✓ Found" : "✗ NOT FOUND")")
                }
            }
        }
        print("========================================")
    }
    
    func loadBGM(filename: String) {
        let extensions = ["wav", "mp3", "m4a", "aac"]
        
        print("Attempting to load BGM: \(filename)")
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                print("✓ Found BGM file: \(filename).\(ext)")
                print("  URL: \(url)")
                loadAudioWithAnalysis(from: url)
                return
            }
        }
        
        // デバッグ: 利用可能なリソースを表示
        print("✗ BGM file not found: \(filename)")
        debugPrintAvailableAudioFiles()
    }
    
    func loadCurrentTrack() {
        loadBGM(filename: Self.tracks[currentTrackIndex])
    }
    
    func nextTrack() {
        let wasPlaying = isPlaying
        stop()
        currentTrackIndex = (currentTrackIndex + 1) % Self.tracks.count
        loadCurrentTrack()
        if wasPlaying {
            play()
        }
    }
    
    func previousTrack() {
        let wasPlaying = isPlaying
        stop()
        currentTrackIndex = (currentTrackIndex - 1 + Self.tracks.count) % Self.tracks.count
        loadCurrentTrack()
        if wasPlaying {
            play()
        }
    }
    
    func selectTrack(at index: Int) {
        guard index >= 0 && index < Self.tracks.count else { return }
        let wasPlaying = isPlaying
        stop()
        currentTrackIndex = index
        loadCurrentTrack()
        if wasPlaying {
            play()
        }
    }
    
    private func loadAudioWithAnalysis(from url: URL) {
        // 既存のエンジンをクリーンアップ
        cleanupAudioEngine()
        
        print("Loading audio from: \(url.path)")
        
        // ファイルの存在確認
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            print("Audio file exists at path")
            if let attributes = try? fileManager.attributesOfItem(atPath: url.path) {
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("Audio file size: \(fileSize) bytes")
            }
        } else {
            print("ERROR: Audio file does not exist at path!")
            return
        }
        
        do {
            // AVAudioPlayerも保持（フォールバック用）
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = volume
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.prepareToPlay()
            print("AVAudioPlayer prepared successfully, duration: \(audioPlayer?.duration ?? 0) seconds")
            
            // AVAudioEngine でリアルタイム解析
            setupAudioEngine(with: url)
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    private func cleanupAudioEngine() {
        // 既存のタップを削除
        if let engine = audioEngine {
            engine.mainMixerNode.removeTap(onBus: 0)
            engine.stop()
        }
        playerNode?.stop()
        playerNode = nil
        audioEngine = nil
        audioFile = nil
    }
    
    private func setupAudioEngine(with url: URL) {
        do {
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            audioFile = try AVAudioFile(forReading: url)
            
            guard let engine = audioEngine,
                  let player = playerNode,
                  let file = audioFile else { return }
            
            engine.attach(player)
            
            let format = file.processingFormat
            engine.connect(player, to: engine.mainMixerNode, format: format)
            
            // リアルタイム解析用タップ
            let bufferSize: AVAudioFrameCount = AVAudioFrameCount(fftSize)
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }
            
            engine.mainMixerNode.outputVolume = volume
            
            try engine.start()
        } catch {
            print("Audio engine setup failed: \(error)")
        }
    }
    
    // MARK: - オーディオ解析
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 計算頻度を制限（30Hz）
        let currentTime = CFAbsoluteTimeGetCurrent()
        guard currentTime - lastFFTTime >= fftInterval else { return }
        lastFFTTime = currentTime
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // FFT解析
        performFFT(channelData, frameCount: frameLength)
        
        // ビート検出
        detectBeat()
    }
    
    private func performFFT(_ data: UnsafePointer<Float>, frameCount: Int) {
        let count = min(frameCount, fftSize)
        
        // バッファをリセット（ゼロフィル）
        vDSP_vclr(&realInput, 1, vDSP_Length(fftSize))
        vDSP_vclr(&imagInput, 1, vDSP_Length(fftSize))
        
        // ウィンドウ関数適用（vDSP使用で高速化）
        vDSP_vmul(data, 1, windowCoefficients, 1, &realInput, 1, vDSP_Length(count))
        
        // FFT実行
        guard let setup = fftSetup else { return }
        
        realInput.withUnsafeBufferPointer { realInPtr in
            imagInput.withUnsafeBufferPointer { imagInPtr in
                realOutput.withUnsafeMutableBufferPointer { realOutPtr in
                    imagOutput.withUnsafeMutableBufferPointer { imagOutPtr in
                        vDSP_DFT_Execute(setup,
                                       realInPtr.baseAddress!,
                                       imagInPtr.baseAddress!,
                                       realOutPtr.baseAddress!,
                                       imagOutPtr.baseAddress!)
                    }
                }
            }
        }
        
        // マグニチュード計算（vDSP使用で高速化）
        let halfSize = fftSize / 2
        var realSq = [Float](repeating: 0, count: halfSize)
        var imagSq = [Float](repeating: 0, count: halfSize)
        
        vDSP_vsq(realOutput, 1, &realSq, 1, vDSP_Length(halfSize))
        vDSP_vsq(imagOutput, 1, &imagSq, 1, vDSP_Length(halfSize))
        vDSP_vadd(realSq, 1, imagSq, 1, &magnitudes, 1, vDSP_Length(halfSize))
        
        // sqrt はスカラー演算が必要なので、近似値で代用可能だが精度のために維持
        var sqrtCount = Int32(halfSize)
        vvsqrtf(&magnitudes, magnitudes, &sqrtCount)
        
        // 周波数帯域ごとにエネルギー計算
        let binCount = halfSize
        let sampleRate: Float = 44100.0  // 一般的なサンプリングレート
        let nyquist = sampleRate / 2.0
        
        // 低音域（20-150Hz）- ビート/ベース
        let lowStart = max(0, Int(20.0 / nyquist * Float(binCount)))
        let lowEnd = min(binCount, Int(150.0 / nyquist * Float(binCount)))
        var lowEnergy: Float = 0
        if lowEnd > lowStart {
            vDSP_sve(&magnitudes + lowStart, 1, &lowEnergy, vDSP_Length(lowEnd - lowStart))
            lowEnergy /= Float(lowEnd - lowStart)
        }
        
        // 中音域（150-2000Hz）- メロディ/ボーカル
        let midStart = lowEnd
        let midEnd = min(binCount, Int(2000.0 / nyquist * Float(binCount)))
        var midEnergy: Float = 0
        if midEnd > midStart {
            vDSP_sve(&magnitudes + midStart, 1, &midEnergy, vDSP_Length(midEnd - midStart))
            midEnergy /= Float(midEnd - midStart)
        }
        
        // 高音域（2000-8000Hz）- シンバル/ハイハット
        let highStart = midEnd
        let highEnd = min(binCount, Int(8000.0 / nyquist * Float(binCount)))
        var highEnergy: Float = 0
        if highEnd > highStart {
            vDSP_sve(&magnitudes + highStart, 1, &highEnergy, vDSP_Length(highEnd - highStart))
            highEnergy /= Float(highEnd - highStart)
        }
        
        // 全体エネルギー
        var totalEnergy: Float = 0
        vDSP_sve(magnitudes, 1, &totalEnergy, vDSP_Length(binCount))
        totalEnergy /= Float(binCount)
        
        // 正規化とスムージング
        let smoothFactor: Float = 0.3
        let decayFactor: Float = 0.92
        
        let normalizedLow = min(1.0, lowEnergy * 15)
        let normalizedMid = min(1.0, midEnergy * 8)
        let normalizedHigh = min(1.0, highEnergy * 12)
        let normalizedTotal = min(1.0, totalEnergy * 5)
        
        smoothedBeat = max(smoothedBeat * decayFactor, normalizedLow * smoothFactor + smoothedBeat * (1 - smoothFactor))
        smoothedMelody = normalizedMid * smoothFactor + smoothedMelody * (1 - smoothFactor)
        smoothedHigh = normalizedHigh * smoothFactor + smoothedHigh * (1 - smoothFactor)
        smoothedEnergy = normalizedTotal * smoothFactor + smoothedEnergy * (1 - smoothFactor)
        
        // スペクトラム（8バンド）- 配列コピーを回避
        let bandSize = binCount / 8
        for i in 0..<8 {
            let start = i * bandSize
            let count = min(bandSize, binCount - start)
            var bandEnergy: Float = 0
            magnitudes.withUnsafeBufferPointer { ptr in
                vDSP_sve(ptr.baseAddress! + start, 1, &bandEnergy, vDSP_Length(count))
            }
            spectrum[i] = min(1.0, bandEnergy / Float(count) * 10)
        }
        
        // ローカル変数にキャプチャしてメインスレッドへ（weak selfを最小化）
        let beat = smoothedBeat
        let melody = smoothedMelody
        let high = smoothedHigh
        let energy = smoothedEnergy
        let spectrumCopy = spectrum
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.beatIntensity = beat
            self.melodyIntensity = melody
            self.highFrequencyIntensity = high
            self.overallEnergy = energy
            self.spectrum = spectrumCopy
        }
    }
    
    private func detectBeat() {
        let currentEnergy = smoothedBeat
        let energyDiff = currentEnergy - previousBeatEnergy
        
        // ビート検出（エネルギーの急激な上昇）
        let detected = energyDiff > beatThreshold && currentEnergy > 0.4
        
        DispatchQueue.main.async { [weak self] in
            self?.isBeatDetected = detected
        }
        
        previousBeatEnergy = currentEnergy * beatDecay
    }
    
    // MARK: - 再生制御
    
    func play() {
        // 再生前にオーディオセッションを再度アクティブ化
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated for playback")
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        if let player = playerNode, let file = audioFile, let engine = audioEngine {
            // AudioEngine経由で再生
            print("Playing via AudioEngine: \(currentTrackName)")
            
            player.scheduleFile(file, at: nil) { [weak self] in
                // ループ再生
                DispatchQueue.main.async {
                    if self?.isPlaying == true {
                        self?.play()
                    }
                }
            }
            
            if !engine.isRunning {
                do {
                    try engine.start()
                    print("Audio engine started")
                } catch {
                    print("Failed to start audio engine: \(error)")
                }
            }
            
            player.play()
            isPlaying = true
            print("PlayerNode is playing: \(player.isPlaying)")
        } else if let player = audioPlayer {
            // フォールバック
            print("Playing via AVAudioPlayer fallback: \(currentTrackName)")
            player.play()
            isPlaying = true
            startMeteringTimer()
            print("AVAudioPlayer is playing: \(player.isPlaying)")
        } else {
            print("No audio player available - loading current track")
            loadCurrentTrack()
        }
    }
    
    func pause() {
        playerNode?.pause()
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func stop() {
        playerNode?.stop()
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        
        // 解析データリセット
        beatIntensity = 0
        melodyIntensity = 0
        highFrequencyIntensity = 0
        overallEnergy = 0
        isBeatDetected = false
        spectrum = Array(repeating: 0, count: 8)
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
        audioEngine?.mainMixerNode.outputVolume = volume
    }
    
    // MARK: - フェード
    
    func fadeIn(duration: TimeInterval = 1.0) {
        // 目標音量を先に保存（setVolume(0)の前に）
        let targetVolume: Float = 0.5  // デフォルト音量
        
        print("fadeIn called - target volume: \(targetVolume)")
        
        setVolume(0)
        play()
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                let newVolume = targetVolume * Float(i) / Float(steps)
                self?.setVolume(newVolume)
                if i == steps {
                    print("fadeIn complete - final volume: \(newVolume)")
                }
            }
        }
    }
    
    func fadeOut(duration: TimeInterval = 1.0) {
        guard isPlaying else { return }
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let startVolume = volume
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                guard let self = self else { return }
                let newVolume = startVolume * Float(steps - i) / Float(steps)
                self.setVolume(newVolume)
                
                if i == steps {
                    self.stop()
                    self.setVolume(startVolume)
                }
            }
        }
    }
    
    // MARK: - フォールバック用メータリング
    
    private var meteringTimer: Timer?
    
    private func startMeteringTimer() {
        meteringTimer?.invalidate()
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateMetering()
        }
    }
    
    private func updateMetering() {
        guard let player = audioPlayer, player.isPlaying else { return }
        
        player.updateMeters()
        
        // 簡易的なレベルメーター
        let averagePower = player.averagePower(forChannel: 0)
        let normalizedPower = max(0, (averagePower + 60) / 60) // -60dB to 0dB -> 0 to 1
        
        // 簡易解析データ更新
        let smoothFactor: Float = 0.3
        smoothedEnergy = normalizedPower * smoothFactor + smoothedEnergy * (1 - smoothFactor)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.overallEnergy = self.smoothedEnergy
            self.beatIntensity = self.smoothedEnergy * 0.8
            self.melodyIntensity = self.smoothedEnergy * 0.6
        }
    }
}
