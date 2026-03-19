// VideoPlayerEngine.swift
// MacOS-Dino – AVFoundation Crossfade Loop Motoru
// İki AVPlayer arasında crossfade yaparak kesintisiz, yumuşak döngü
// Default: 0.35x slow-motion (macOS Aerial benzeri akıcı hareket)

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
    @Published var playbackRate: Float = 0.35

    // İki AVPlayerLayer → crossfade
    weak var playerLayerA: AVPlayerLayer?
    weak var playerLayerB: AVPlayerLayer?

    // Dışarıdan erişim (DesktopWindow)
    var player: AVPlayer? { activePlayer }
    var playerLayer: AVPlayerLayer? {
        get { playerLayerA }
        set { playerLayerA = newValue }
    }

    private var activePlayer: AVPlayer?
    private var standbyPlayer: AVPlayer?
    private var videoAsset: AVURLAsset?
    private var timeObserver: Any?
    private var boundaryObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isLayerA = true  // hangi layer aktif

    // Crossfade ayarları – kullanıcı değiştirebilir
    var crossfadeDuration: Double = 2.5  // saniye – yavaş, yumuşak geçiş
    var crossfadeStartBefore: Double = 3.0  // sona kaç sn kala crossfade başlasın

    // MARK: - Video Loading

    func loadVideo(url: URL) async {
        await MainActor.run { isLoading = true }

        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            let dur = try await asset.load(.duration)

            guard let firstTrack = tracks.first else {
                print("⚠️ Video track yok: \(url)")
                await MainActor.run { isLoading = false }
                return
            }

            let naturalSize = try await firstTrack.load(.naturalSize)
            let transform = try await firstTrack.load(.preferredTransform)
            let corrected = naturalSize.applying(transform)
            print("🎬 Video: \(abs(corrected.width).rounded())×\(abs(corrected.height).rounded())")

            await MainActor.run {
                self.duration = CMTimeGetSeconds(dur)
                self.teardown()         // teardown videoAsset'i siliyor – ondan SONRA set et
                self.videoAsset = asset // ← doğru sıra

                // İki player oluştur
                let itemA = AVPlayerItem(asset: asset)
                itemA.preferredForwardBufferDuration = 5.0
                itemA.audioTimePitchAlgorithm = .spectral

                let playerA = AVPlayer(playerItem: itemA)
                playerA.isMuted = true
                playerA.allowsExternalPlayback = false

                self.activePlayer = playerA
                self.isLayerA = true

                // Layer'a bağla
                self.playerLayerA?.player = playerA

                // Oynat
                playerA.rate = self.playbackRate
                self.isPlaying = true

                // Crossfade boundary kur
                self.setupCrossfadeBoundary()
                self.setupTimeObserver()
                self.isLoading = false
            }

        } catch {
            print("❌ Video yükleme hatası: \(error.localizedDescription)")
            await MainActor.run { isLoading = false }
        }
    }

    // MARK: - Playback Control

    func play() {
        activePlayer?.rate = playbackRate
        isPlaying = true
    }

    func pause() {
        activePlayer?.pause()
        standbyPlayer?.pause()
        isPlaying = false
    }

    func stop() {
        teardown()
        isPlaying = false
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        activePlayer?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            activePlayer?.rate = rate
        }
    }

    // MARK: - Crossfade Loop

    private func setupCrossfadeBoundary() {
        // Önceki observer temizle
        if let obs = boundaryObserver {
            activePlayer?.removeTimeObserver(obs)
            boundaryObserver = nil
        }

        guard let player = activePlayer, duration > crossfadeStartBefore + 1 else {
            // Video çok kısa – basit loop
            setupSimpleLoop()
            return
        }

        let fadeStart = duration - crossfadeStartBefore
        let fadeTime = CMTime(seconds: fadeStart, preferredTimescale: 600)

        boundaryObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: fadeTime)],
            queue: .main
        ) { [weak self] in
            Task { @MainActor in
                self?.performCrossfade()
            }
        }

        // Failsafe: video sona gelirse (crossfade tetiklenmediyse) sıfırdan başlat
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.activePlayer === player else { return }
                    print("⚠️ Failsafe loop tetiklendi")
                    self.activePlayer?.seek(to: .zero) { _ in
                        self.activePlayer?.rate = self.playbackRate
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Basit loop (kısa videolar için – AVPlayerLooper)
    private func setupSimpleLoop() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: activePlayer?.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.activePlayer?.seek(to: .zero)
                self?.activePlayer?.rate = self?.playbackRate ?? 0.35
            }
            .store(in: &cancellables)
    }

    /// Asıl crossfade – standby player hazırla, iki layer'ı aynı anda fade et
    private func performCrossfade() {
        guard let asset = videoAsset else { return }

        // Standby player oluştur – baştan başlayacak
        let newItem = AVPlayerItem(asset: asset)
        newItem.preferredForwardBufferDuration = 5.0
        newItem.audioTimePitchAlgorithm = .spectral

        let newPlayer = AVPlayer(playerItem: newItem)
        newPlayer.isMuted = true
        newPlayer.allowsExternalPlayback = false

        // Hangi layer standby?
        let standbyLayer = isLayerA ? playerLayerB : playerLayerA
        let activeLayer = isLayerA ? playerLayerA : playerLayerB

        standbyLayer?.player = newPlayer
        standbyLayer?.opacity = 0

        // Yeni player'ı başlat
        newPlayer.rate = playbackRate
        self.standbyPlayer = newPlayer

        // Crossfade animasyonu
        let dur = crossfadeDuration

        // Standby layer fade-in
        animateOpacity(layer: standbyLayer, from: 0, to: 1, duration: dur)
        // Active layer fade-out
        animateOpacity(layer: activeLayer, from: 1, to: 0, duration: dur)

        // Crossfade bittikten sonra player'ları swap et
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((dur + 0.1) * 1_000_000_000))
            guard !Task.isCancelled else { return }

            // Eski observer'ı temizle
            if let obs = self.boundaryObserver {
                self.activePlayer?.removeTimeObserver(obs)
                self.boundaryObserver = nil
            }
            self.cancellables.removeAll()  // eski failsafe subscription temizle

            // Eski player'ı durdur
            self.activePlayer?.pause()

            // Swap
            self.activePlayer = newPlayer
            self.standbyPlayer = nil
            self.isLayerA.toggle()

            // Yeni crossfade boundary kur
            self.setupCrossfadeBoundary()
            self.setupTimeObserver()
        }
    }

    private func animateOpacity(layer: CALayer?, from: Float, to: Float, duration: Double) {
        guard let layer else { return }
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = from
        anim.toValue = to
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: "crossfade_\(to)")
        layer.opacity = to
    }

    // MARK: - Convenience fade

    func fadeIn(duration: Double? = nil) {
        animateOpacity(layer: isLayerA ? playerLayerA : playerLayerB, from: 0, to: 1, duration: duration ?? crossfadeDuration)
    }

    func fadeOut(duration: Double? = nil) {
        animateOpacity(layer: isLayerA ? playerLayerA : playerLayerB, from: 1, to: 0, duration: duration ?? crossfadeDuration)
    }

    // MARK: - Private

    private func setupTimeObserver() {
        if let obs = timeObserver {
            activePlayer?.removeTimeObserver(obs)
        }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = activePlayer?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
    }

    private func teardown() {
        if let obs = boundaryObserver {
            activePlayer?.removeTimeObserver(obs)
            boundaryObserver = nil
        }
        if let obs = timeObserver {
            activePlayer?.removeTimeObserver(obs)
            timeObserver = nil
        }
        activePlayer?.pause()
        standbyPlayer?.pause()
        activePlayer = nil
        standbyPlayer = nil
        videoAsset = nil
        cancellables.removeAll()
    }

    deinit {
        activePlayer?.pause()
        standbyPlayer?.pause()
    }
}
