// DisplayLinkManager.swift
// MacOS-Dino – ProMotion + CADisplayLink + Frame Rate Yönetimi
// Apple ProMotion 120Hz senkronizasyon desteği

import AppKit
import QuartzCore

final class DisplayLinkManager {

    // MARK: - Properties

    private var displayLink: CVDisplayLink?
    private var targetFPS: Int = 60
    private var frameCallback: (() -> Void)?

    private var isActive = false
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsReportCallback: ((Double) -> Void)?

    // MARK: - Configuration

    func updatePreferredFPS(_ fps: Int) {
        targetFPS = max(1, min(fps, 120))
        // Eğer çalışıyorsa yeniden başlat
        if isActive {
            stop()
            start()
        }
    }

    func onFrame(_ callback: @escaping () -> Void) {
        self.frameCallback = callback
    }

    func onFPSReport(_ callback: @escaping (Double) -> Void) {
        self.fpsReportCallback = callback
    }

    // MARK: - Lifecycle

    func start() {
        guard !isActive else { return }

        var link: CVDisplayLink?
        let status = CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard status == kCVReturnSuccess, let displayLink = link else {
            print("❌ CVDisplayLink oluşturulamadı: \(status)")
            return
        }

        self.displayLink = displayLink

        // Display link callback
        let callback: CVDisplayLinkOutputCallback = { displayLink, inNow, inOutputTime, flagsIn, flagsOut, context in
            guard let context else { return kCVReturnSuccess }
            let manager = Unmanaged<DisplayLinkManager>.fromOpaque(context).takeUnretainedValue()
            manager.handleFrame()
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(
            displayLink,
            callback,
            Unmanaged.passUnretained(self).toOpaque()
        )

        CVDisplayLinkStart(displayLink)
        isActive = true
        lastFrameTime = CACurrentMediaTime()

        print("⏱️ DisplayLink başlatıldı – hedef \(targetFPS) FPS")
    }

    func stop() {
        guard isActive, let displayLink else { return }
        CVDisplayLinkStop(displayLink)
        self.displayLink = nil
        isActive = false
    }

    // MARK: - Frame Handling

    private func handleFrame() {
        frameCount += 1

        // Frame rate throttling
        let now = CACurrentMediaTime()
        let elapsed = now - lastFrameTime
        let targetInterval = 1.0 / Double(targetFPS)

        guard elapsed >= targetInterval else { return }

        // Frame callback
        DispatchQueue.main.async { [weak self] in
            self?.frameCallback?()
        }

        // FPS raporlama (her saniye)
        if elapsed >= 1.0 {
            let currentFPS = Double(frameCount) / elapsed
            DispatchQueue.main.async { [weak self] in
                self?.fpsReportCallback?(currentFPS)
            }
            frameCount = 0
            lastFrameTime = now
        }
    }

    // MARK: - Display Info

    /// Aktif ekranın refresh rate'ini döndürür
    static func currentRefreshRate() -> Double {
        guard let screen = NSScreen.main,
              let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return 60.0
        }

        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            return 60.0
        }

        return mode.refreshRate > 0 ? mode.refreshRate : 60.0
    }

    /// ProMotion destekli mi?
    static var isProMotionSupported: Bool {
        return currentRefreshRate() > 60.0
    }

    deinit {
        stop()
    }
}
