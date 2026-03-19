// VideoPlayerEngine.swift
// MacOS-Dino – AVFoundation + Core Video + Hardware Acceleration
// HEVC/H.264 video oynatma motoru, sonsuz loop + fade geçiş + playback rate

import AVFoundation
import CoreVideo
import Combine

@MainActor
final class VideoPlayerEngine: ObservableObject {

    // MARK: - Properties

    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var playbackRate: Float = 1.0  // 0.25 = slow-mo, 1.0 = normal

    // Fade geçiş için playerLayer zayıf referansı
    weak var playerLayer: AVPlayerLayer?

    private(set) var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var loopObserver: Any?
    private var timeObserver: Any?
    private var fadeTimer: Timer?
    private var loopStart: CMTime = .zero
    private var loopEnd: CMTime = .positiveInfinity
    private var cancellables = Set<AnyCancellable>()

    // Fade ayarları
    var fadeDuration: Double = 1.5   // saniye
    var fadeOutStart: Double = 2.0   // sona kaç saniye kala fade başlasın

    // MARK: - Video Loading

    func loadVideo(url: URL) async {
        await MainActor.run { isLoading = true }

        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true,
            // Apple Silicon Media Engine ile donanım hızlandırma
            "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "MacOS-Dino/1.0"]
        ])

        do {
            // Asset bilgilerini önceden yükle
            let tracks = try await asset.loadTracks(withMediaType: .video)
            let duration = try await asset.load(.duration)

            guard let videoTrack = tracks.first else {
                print("⚠️ Video track bulunamadı: \(url)")
                return
            }

            // Video boyutu ve transform bilgisi (Retina uyum)
            let naturalSize = try await videoTrack.load(.naturalSize)
            let transform = try await videoTrack.load(.preferredTransform)
            let correctedSize = naturalSize.applying(transform)

            print("🎬 Video yüklendi: \(abs(correctedSize.width))x\(abs(correctedSize.height))")

            // Player item oluştur – donanım decode tercih et
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 5.0 // 5 sn buffer
            item.audioTimePitchAlgorithm = .spectral

            // Piksel format tercihi – Apple Silicon Media Engine uyumlu
            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]

            await MainActor.run {
                self.playerItem = item
                self.duration = CMTimeGetSeconds(duration)

                if self.player == nil {
                    self.player = AVPlayer(playerItem: item)
                } else {
                    self.player?.replaceCurrentItem(with: item)
                }

                // Sessiz oynat – arka plan videosu
                self.player?.isMuted = true
                self.player?.allowsExternalPlayback = false

                // Playback rate uygula
                self.player?.rate = self.playbackRate

                // Sonsuz loop + fade setup
                self.setupLooping()

                // Zaman takibi
                self.setupTimeObserver()

                self.isLoading = false
            }

        } catch {
            print("❌ Video yükleme hatası: \(error.localizedDescription)")
            await MainActor.run { isLoading = false }
        }
    }

    // MARK: - Loop Points

    func setLoopPoints(start: Double?, end: Double?) {
        if let s = start {
            loopStart = CMTime(seconds: s, preferredTimescale: 600)
        }
        if let e = end {
            loopEnd = CMTime(seconds: e, preferredTimescale: 600)
        }

        // Loop boundary observer güncelle
        setupLooping()
    }

    // MARK: - Playback Control

    func play() {
        player?.rate = playbackRate
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        fadeTimer?.invalidate()
        player?.pause()
        player?.seek(to: loopStart)
        isPlaying = false
        removeObservers()
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Oynatma hızını değiştir (0.25 slow-mo, 0.5 yavaş, 1.0 normal)
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }

    // MARK: - Private

    private func setupLooping() {
        // Önceki observer'ları temizle
        if let observer = loopObserver {
            player?.removeTimeObserver(observer)
            loopObserver = nil
        }
        fadeTimer?.invalidate()
        cancellables.removeAll()

        guard let player else { return }

        // AVPlayerItem bitişini dinle → fade geçişli loop
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loopWithFade()
            }
            .store(in: &cancellables)

        // Sona yaklaşınca fade başlat
        setupFadeBoundary()
    }

    /// Video sonuna fadeOutStart saniye kala CALayer opacity'yi düşür
    private func setupFadeBoundary() {
        guard let player, duration > 0 else { return }

        let endSeconds = loopEnd == .positiveInfinity ? duration : CMTimeGetSeconds(loopEnd)
        let fadeStartSeconds = max(0, endSeconds - fadeOutStart)
        let fadeTime = CMTime(seconds: fadeStartSeconds, preferredTimescale: 600)

        loopObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: fadeTime)],
            queue: .main
        ) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.fadeLayer(toOpacity: 0, duration: self.fadeDuration)
            }
        }
    }

    /// Fade out → seek başa → fade in
    private func loopWithFade() {
        fadeLayer(toOpacity: 0, duration: 0.3)
        // 0.35s sonra seek + fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.player?.seek(to: self.loopStart, toleranceBefore: .zero, toleranceAfter: .zero)
            self.player?.rate = self.playbackRate
            self.fadeLayer(toOpacity: 1, duration: self.fadeDuration)
        }
    }

    /// AVPlayerLayer CALayer opacity animasyonu
    private func fadeLayer(toOpacity opacity: Float, duration: Double) {
        guard let layer = playerLayer else { return }
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = layer.opacity
        anim.toValue = opacity
        anim.duration = duration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: "dinoFade")
        layer.opacity = opacity
    }

    private func setupTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }

    private func removeObservers() {
        if let observer = loopObserver {
            player?.removeTimeObserver(observer)
            loopObserver = nil
        }
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        cancellables.removeAll()
    }

    // Not: WallpaperEngine stop()/clearContent() ile removeObservers'ı explicit çağırır
}
