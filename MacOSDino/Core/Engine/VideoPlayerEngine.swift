// VideoPlayerEngine.swift
// MacOS-Dino – AVFoundation seamless loop motoru
// AVQueuePlayer + AVPlayerLooper → boşluksuz, flash'sız döngü
// Default: 0.4x slow-motion (macOS Aerial benzeri)

import AVFoundation
import CoreVideo
import Combine

@MainActor
final class VideoPlayerEngine: ObservableObject {

    // MARK: - Published State

    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var playbackRate: Float = 0.4  // macOS Aerial gibi yavaş

    // Fade için playerLayer referansı
    weak var playerLayer: AVPlayerLayer?

    // AVQueuePlayer + Looper = seamless, flash'sız döngü
    private(set) var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var templateItem: AVPlayerItem?

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    var fadeDuration: Double = 1.2

    // MARK: - Video Loading

    func loadVideo(url: URL) async {
        await MainActor.run { isLoading = true }

        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            let dur    = try await asset.load(.duration)

            guard let firstTrack = tracks.first else {
                print("⚠️ Video track yok: \(url)")
                await MainActor.run { isLoading = false }
                return
            }

            let naturalSize = try await firstTrack.load(.naturalSize)
            let transform   = try await firstTrack.load(.preferredTransform)
            let corrected   = naturalSize.applying(transform)
            print("🎬 Video: \(abs(corrected.width).rounded())×\(abs(corrected.height).rounded())")

            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 5.0
            item.audioTimePitchAlgorithm = .spectral

            await MainActor.run {
                self.templateItem = item
                self.duration = CMTimeGetSeconds(dur)

                self.teardown()

                let qp = AVQueuePlayer()
                qp.isMuted = true
                qp.allowsExternalPlayback = false

                // AVPlayerLooper – seamless sonsuz döngü (flash yok)
                let looper = AVPlayerLooper(player: qp, templateItem: item)
                self.queuePlayer = qp
                self.playerLooper = looper

                // playerLayer varsa yeni player'ı bağla
                self.playerLayer?.player = qp

                qp.rate = self.playbackRate
                self.isPlaying = true

                self.setupTimeObserver()
                self.isLoading = false
            }

        } catch {
            print("❌ Video yükleme hatası: \(error.localizedDescription)")
            await MainActor.run { isLoading = false }
        }
    }

    // MARK: - Playback Control

    /// player'a dışarıdan erişim gereken yerler için (DesktopWindow)
    var player: AVQueuePlayer? { queuePlayer }

    func play() {
        queuePlayer?.rate = playbackRate
        isPlaying = true
    }

    func pause() {
        queuePlayer?.pause()
        isPlaying = false
    }

    func stop() {
        teardown()
        isPlaying = false
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        queuePlayer?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying { queuePlayer?.rate = rate }
    }

    // MARK: - Fade (giriş/çıkış görsel efekti)

    func fadeIn(duration: Double? = nil) {
        fadeLayer(toOpacity: 1, duration: duration ?? fadeDuration)
    }

    func fadeOut(duration: Double? = nil) {
        fadeLayer(toOpacity: 0, duration: duration ?? fadeDuration)
    }

    private func fadeLayer(toOpacity opacity: Float, duration: Double) {
        guard let layer = playerLayer else { return }
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = layer.opacity
        anim.toValue   = opacity
        anim.duration  = duration
        anim.fillMode  = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: "dinoFade")
        layer.opacity = opacity
    }

    // MARK: - Private

    private func setupTimeObserver() {
        if let observer = timeObserver {
            queuePlayer?.removeTimeObserver(observer)
        }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = queuePlayer?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }

    private func teardown() {
        if let observer = timeObserver {
            queuePlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        playerLooper?.disableLooping()
        playerLooper = nil
        queuePlayer?.pause()
        queuePlayer = nil
        templateItem = nil
        cancellables.removeAll()
    }

    deinit {
        playerLooper?.disableLooping()
        queuePlayer?.pause()
    }
}
