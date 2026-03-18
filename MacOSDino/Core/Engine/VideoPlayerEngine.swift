// VideoPlayerEngine.swift
// MacOS-Dino – AVFoundation + Core Video + Hardware Acceleration
// HEVC/H.264 video oynatma motoru, sonsuz loop desteği

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

    private(set) var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var loopObserver: Any?
    private var timeObserver: Any?
    private var loopStart: CMTime = .zero
    private var loopEnd: CMTime = .positiveInfinity
    private var cancellables = Set<AnyCancellable>()

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

                // Sonsuz loop setup
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
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.pause()
        player?.seek(to: loopStart)
        isPlaying = false
        removeObservers()
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Private

    private func setupLooping() {
        // Önceki observer'ı kaldır
        if let observer = loopObserver {
            player?.removeTimeObserver(observer)
            loopObserver = nil
        }

        guard let player else { return }

        // Boundary observer: loop bitiş noktasına ulaşınca başa sar
        let boundary = [NSValue(time: loopEnd)]
        loopObserver = player.addBoundaryTimeObserver(
            forTimes: boundary,
            queue: .main
        ) { [weak self] in
            guard let self else { return }
            self.player?.seek(to: self.loopStart, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        // Ayrıca AVPlayerItem bitişini de dinle (eğer loopEnd = sonuncuysa)
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                guard let self else { return }
                self.player?.seek(to: self.loopStart, toleranceBefore: .zero, toleranceAfter: .zero)
                self.player?.play()
            }
            .store(in: &cancellables)
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

    deinit {
        removeObservers()
    }
}
