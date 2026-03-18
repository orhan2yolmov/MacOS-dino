// OcclusionDetector.swift
// MacOS-Dino – Akıllı Oklüzyon Motoru
// Masaüstü tamamen kapalıyken video'yu durdurarak enerji tasarrufu sağlar
// CGWindowListCopyWindowInfo + NSWindow.occlusionState kullanır

import AppKit
import CoreGraphics

final class OcclusionDetector {

    // MARK: - Callback

    var onOcclusionChanged: ((Bool) -> Void)?

    // MARK: - State

    private var timer: Timer?
    private var lastOcclusionState: Bool = false
    private let coverageThreshold: CGFloat = 0.78 // %78 kapalıysa occluded say

    // MARK: - Monitoring

    func startMonitoring(interval: TimeInterval = 1.0) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkNow()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func checkNow() {
        let isOccluded = isDesktopOccluded()
        if isOccluded != lastOcclusionState {
            lastOcclusionState = isOccluded
            onOcclusionChanged?(isOccluded)
        }
    }

    // MARK: - Occlusion Detection

    /// Masaüstünün görünür olup olmadığını kontrol eder
    /// Birden fazla yöntemi birleştirir: CGWindowList + occlusionState + fullscreen check
    func isDesktopOccluded() -> Bool {
        // Yöntem 1: Fullscreen uygulama açık mı?
        if isAnyAppFullscreen() {
            return true
        }

        // Yöntem 2: CGWindowListCopyWindowInfo ile pencere kaplamayı hesapla
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        guard let mainScreen = NSScreen.main else { return false }
        let screenArea = mainScreen.frame.width * mainScreen.frame.height

        var coveredArea: CGFloat = 0.0

        for windowInfo in windowList {
            // Sadece normal ve üstü katmanları say
            guard let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer >= 0, // Normal seviye ve üstü
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let alpha = windowInfo[kCGWindowAlpha as String] as? CGFloat,
                  alpha > 0.5 else { // Yarı-saydam pencereler saymaz
                continue
            }

            // Pencere boyutunu hesapla
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0
            coveredArea += width * height
        }

        // Toplam kaplama oranı
        let coverageRatio = coveredArea / screenArea
        return coverageRatio > coverageThreshold
    }

    /// Herhangi bir uygulama fullscreen modunda mı?
    private func isAnyAppFullscreen() -> Bool {
        for window in NSApplication.shared.windows {
            if window.styleMask.contains(.fullScreen) {
                return true
            }
        }

        // Running uygulamaların presentation'larını da kontrol et
        let options = NSApplication.shared.presentationOptions
        return options.contains(.fullScreen)
    }

    /// Belirli bir ekran için oklüzyon durumu
    func isOccluded(for screen: NSScreen) -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        let screenFrame = screen.frame
        let screenArea = screenFrame.width * screenFrame.height
        var coveredArea: CGFloat = 0.0

        for windowInfo in windowList {
            guard let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer >= 0,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }

            let windowRect = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )

            // Bu ekranla kesişen alanı hesapla
            let intersection = windowRect.intersection(screenFrame)
            if !intersection.isNull {
                coveredArea += intersection.width * intersection.height
            }
        }

        return (coveredArea / screenArea) > coverageThreshold
    }

    deinit {
        stopMonitoring()
    }
}
