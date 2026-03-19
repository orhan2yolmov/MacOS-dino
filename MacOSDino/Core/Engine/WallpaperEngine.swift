// WallpaperEngine.swift
// MacOS-Dino – Ana Motor Koordinatörü
// Tüm wallpaper oynatma, oklüzyon, çoklu monitör yönetimi

import AppKit
import Combine
import AVFoundation

@MainActor
final class WallpaperEngine: ObservableObject {

    static let shared = WallpaperEngine()

    // MARK: - Published State

    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentWallpaper: Wallpaper?
    @Published var activeDisplays: [DisplayConfiguration] = []
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var fps: Double = 0.0

    // MARK: - Sub-Engines

    private(set) var desktopWindows: [CGDirectDisplayID: DesktopWindow] = [:]
    private(set) var videoPlayers: [CGDirectDisplayID: VideoPlayerEngine] = [:]
    private let occlusionDetector = OcclusionDetector()
    private let displayLinkManager = DisplayLinkManager()
    private let multiMonitorManager = MultiMonitorManager()
    private let performanceMonitor = PerformanceMonitor()
    private let shaderManager = ShaderManager()

    // MARK: - Internal State

    private var cancellables = Set<AnyCancellable>()
    private var isInitialized = false

    // MARK: - Settings

    @Published var preferredFPS: Int = 60 {
        didSet {
            displayLinkManager.updatePreferredFPS(preferredFPS)
        }
    }
    @Published var enableMouseInteraction: Bool = true
    @Published var enableAudioReactive: Bool = false
    @Published var pauseOnBattery: Bool = true
    @Published var pauseWhenOccluded: Bool = true
    @Published var activeShaderName: String? = nil

    private init() {}

    // MARK: - Lifecycle

    func initialize() async {
        guard !isInitialized else { return }
        isInitialized = true

        // Monitörleri keşfet
        await refreshDisplays()

        // Her monitör için desktop window oluştur
        for display in activeDisplays {
            await setupDesktopWindow(for: display)
        }

        // Oklüzyon dedektörünü başlat
        setupOcclusionDetection()

        // Performans izlemeyi başlat
        setupPerformanceMonitoring()

        // Kayıtlı wallpaper'ı yükle
        await loadSavedWallpaper()

        isRunning = true
        print("🦕 WallpaperEngine hazır – \(activeDisplays.count) monitör aktif")
    }

    func shutdown() {
        isRunning = false
        stopAllPlayback()
        desktopWindows.values.forEach { $0.close() }
        desktopWindows.removeAll()
        videoPlayers.removeAll()
        displayLinkManager.stop()
        cancellables.removeAll()
        isInitialized = false
    }

    // MARK: - Display Management

    func refreshDisplays() async {
        activeDisplays = multiMonitorManager.detectDisplays()
    }

    func handleScreenChange() async {
        // Monitör eklendi/çıkarıldı – yeniden kurulum
        let oldDisplays = Set(desktopWindows.keys)
        await refreshDisplays()
        let newDisplayIDs = Set(activeDisplays.map { $0.displayID })

        // Kaldırılan monitörleri temizle
        for removedID in oldDisplays.subtracting(newDisplayIDs) {
            desktopWindows[removedID]?.close()
            desktopWindows.removeValue(forKey: removedID)
            videoPlayers.removeValue(forKey: removedID)
        }

        // Yeni monitörlere window ekle
        for display in activeDisplays where !oldDisplays.contains(display.displayID) {
            await setupDesktopWindow(for: display)
            if let wallpaper = currentWallpaper {
                await setWallpaper(wallpaper, for: display.displayID)
            }
        }
    }

    func handleSpaceChange() {
        // Space değiştiğinde wallpaper'ın görünürlüğünü kontrol et
        if pauseWhenOccluded {
            occlusionDetector.checkNow()
        }
    }

    // MARK: - Wallpaper Control

    func setWallpaper(_ wallpaper: Wallpaper, for displayID: CGDirectDisplayID? = nil) async {
        currentWallpaper = wallpaper

        let targetDisplays: [CGDirectDisplayID]
        if let specificID = displayID {
            targetDisplays = [specificID]
        } else {
            targetDisplays = Array(desktopWindows.keys)
        }

        for id in targetDisplays {
            guard let window = desktopWindows[id] else { continue }

            switch wallpaper.contentType {
            case .video:
                let player = VideoPlayerEngine()
                window.attachVideoPlayer(player)
                videoPlayers[id] = player
                await player.loadVideo(url: wallpaper.localURL ?? wallpaper.remoteURL)

            case .metalShader:
                if let shaderName = wallpaper.shaderName {
                    let metalView = shaderManager.createShaderView(
                        named: shaderName,
                        frame: window.frame,
                        parameters: wallpaper.shaderParameters
                    )
                    window.attachMetalView(metalView)
                }

            case .htmlWidget:
                // WKWebView ile HTML5 live widget
                window.attachWebView(url: wallpaper.remoteURL)

            case .staticImage:
                // Statik ama parallax/ken-burns efektli
                window.attachStaticImage(url: wallpaper.localURL ?? wallpaper.remoteURL)
            }
        }

        // Tercihi kaydet
        saveCurrentWallpaper(wallpaper)

        // Analytics
        Task {
            await AnalyticsService.shared.trackEvent(.wallpaperApplied, properties: [
                "wallpaper_id": wallpaper.id.uuidString,
                "type": wallpaper.contentType.rawValue
            ])
        }
    }

    func removeWallpaper(for displayID: CGDirectDisplayID? = nil) {
        let targetDisplays: [CGDirectDisplayID]
        if let specificID = displayID {
            targetDisplays = [specificID]
        } else {
            targetDisplays = Array(desktopWindows.keys)
        }

        for id in targetDisplays {
            videoPlayers[id]?.stop()
            videoPlayers.removeValue(forKey: id)
            desktopWindows[id]?.clearContent()
        }

        if displayID == nil {
            currentWallpaper = nil
        }
    }

    func pause() {
        guard !isPaused else { return }
        isPaused = true
        videoPlayers.values.forEach { $0.pause() }
        displayLinkManager.stop()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        videoPlayers.values.forEach { $0.play() }
        displayLinkManager.start()
    }

    func stopAllPlayback() {
        videoPlayers.values.forEach { $0.stop() }
        displayLinkManager.stop()
    }

    // MARK: - Private Setup

    private func setupDesktopWindow(for display: DisplayConfiguration) async {
        let window = DesktopWindow(display: display)
        window.configure()
        desktopWindows[display.displayID] = window

        // Pencere görünürlüğü değişince pause/resume
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self, weak window] _ in
            guard let self, self.pauseWhenOccluded, let win = window else { return }
            let visible = win.occlusionState.contains(.visible)
            if visible {
                self.videoPlayers.values.forEach { $0.play() }
            } else {
                self.videoPlayers.values.forEach { $0.pause() }
            }
        }
    }

    private func setupOcclusionDetection() {
        occlusionDetector.onOcclusionChanged = { [weak self] isOccluded in
            Task { @MainActor in
                guard let self, self.pauseWhenOccluded else { return }
                if isOccluded {
                    self.videoPlayers.values.forEach { $0.pause() }
                } else {
                    self.videoPlayers.values.forEach { $0.play() }
                }
            }
        }
        occlusionDetector.startMonitoring()
    }

    private func setupPerformanceMonitoring() {
        performanceMonitor.onUpdate = { [weak self] cpu, memory, currentFPS in
            Task { @MainActor in
                self?.cpuUsage = cpu
                self?.memoryUsage = memory
                self?.fps = currentFPS
            }
        }
        performanceMonitor.startMonitoring(interval: 2.0)
    }

    private func saveCurrentWallpaper(_ wallpaper: Wallpaper) {
        if let data = try? JSONEncoder().encode(wallpaper) {
            UserDefaults.standard.set(data, forKey: "MacOSDino.currentWallpaper")
        }
    }

    private func loadSavedWallpaper() async {
        guard let data = UserDefaults.standard.data(forKey: "MacOSDino.currentWallpaper"),
              let wallpaper = try? JSONDecoder().decode(Wallpaper.self, from: data) else {
            return
        }
        await setWallpaper(wallpaper)
    }
}
