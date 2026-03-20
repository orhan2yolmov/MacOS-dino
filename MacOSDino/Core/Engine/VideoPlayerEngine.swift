// VideoPlayerEngine.swift
// MacOS-Dino – AVFoundation Seamless Loop Engine
// AVQueuePlayer + AVPlayerLooper: crash-free infinite looping
// Crossfade opacity pulse on each loop transition

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

    // Layer references (LayerA = active, LayerB kept for API compat but unused)
    weak var playerLayerA: AVPlayerLayer?
    weak var playerLayerB: AVPlayerLayer?

    var player: AVPlayer? { queuePlayer }
    var playerLayer: AVPlayerLayer? {
        get { playerLayerA }
        set { playerLayerA = newValue }
    }

    // MARK: - Private

    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var crossfadeTask: Task<Void, Never>?

    // Crossfade settings
    var crossfadeDuration: Double = 2.5
    var crossfadeStartBefore: Double = 3.0  // API compat only

    // MARK: - Video Loading

    func loadVideo(url: URL) async {
        isLoading = true

        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        do {
            let dur = try await asset.load(.duration)

            teardown()  // always teardown before setting new asset

            let templateItem = AVPlayerItem(asset: asset)
            templateItem.preferredForwardBufferDuration = 5.0
            templateItem.audioTimePitchAlgorithm = .spectral

            let player = AVQueuePlayer()
            player.isMuted = true
            player.allowsExternalPlayback = false
            player.automaticallyWaitsToMinimizeStalling = false

            // AVPlayerLooper creates seamless looping — no boundary observers, no Tasks
            let looper = AVPlayerLooper(player: player, templateItem: templateItem)

            self.queuePlayer = player
            self.playerLooper = looper
            self.duration = CMTimeGetSeconds(dur)

            // Wire layer A; layer B is invisible
            playerLayerA?.player = player
            playerLayerB?.opacity = 0

            // Start playback
            player.rate = playbackRate
            isPlaying = true

            setupTimeObserver()
            setupLoopCrossfade(player: player)

            isLoading = false
            print("🎬 AVPlayerLooper ready – \(duration.rounded())s @ \(playbackRate)×")

        } catch {
            print("❌ Video load error: \(error.localizedDescription)")
            isLoading = false
        }
    }

    // MARK: - Loop Crossfade

    private func setupLoopCrossfade(player: AVQueuePlayer) {
        // AVPlayerLooper posts AVPlayerItemDidPlayToEndTime for each loop
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerCrossfadePulse()
            }
            .store(in: &cancellables)
    }

    private func triggerCrossfadePulse() {
        crossfadeTask?.cancel()
        crossfadeTask = Task { @MainActor in
            let half = crossfadeDuration / 2.0
            // Fade out
            animateOpacity(layer: playerLayerA, from: 1, to: 0, duration: half)
            try? await Task.sleep(nanoseconds: UInt64(half * 1_000_000_000))
            guard !Task.isCancelled else { return }
            // Fade in
            animateOpacity(layer: playerLayerA, from: 0, to: 1, duration: half)
        }
    }

    // MARK: - Playback Control

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

    // MARK: - Opacity Animation

    private func animateOpacity(layer: CALayer?, from: Float, to: Float, duration: Double) {
        guard let layer else { return }
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = from
        anim.toValue = to
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: "crossfade")
        layer.opacity = to
    }

    func fadeIn(duration: Double? = nil) {
        animateOpacity(layer: playerLayerA, from: 0, to: 1, duration: duration ?? crossfadeDuration)
    }

    func fadeOut(duration: Double? = nil) {
        animateOpacity(layer: playerLayerA, from: 1, to: 0, duration: duration ?? crossfadeDuration)
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        if let obs = timeObserver { queuePlayer?.removeTimeObserver(obs) }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = queuePlayer?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
    }

    // MARK: - Teardown

    private func teardown() {
        crossfadeTask?.cancel()
        crossfadeTask = nil
        if let obs = timeObserver {
            queuePlayer?.removeTimeObserver(obs)
            timeObserver = nil
        }
        cancellables.removeAll()
        playerLooper?.disableLooping()
        queuePlayer?.pause()
        queuePlayer = nil
        playerLooper = nil
    }

    deinit {
        queuePlayer?.pause()
    }
}
