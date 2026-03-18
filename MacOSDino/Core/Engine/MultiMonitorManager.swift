// MultiMonitorManager.swift
// MacOS-Dino – Çoklu Monitör Yönetimi
// Her monitöre bağımsız wallpaper atama, hot-plug desteği

import AppKit
import CoreGraphics

final class MultiMonitorManager {

    // MARK: - Display Detection

    /// Sistemdeki tüm aktif ekranları tespit eder
    func detectDisplays() -> [DisplayConfiguration] {
        var displays: [DisplayConfiguration] = []

        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? CGDirectDisplayID else {
                continue
            }

            let isMain = screen == NSScreen.main
            let isBuiltIn = CGDisplayIsBuiltin(screenNumber) != 0
            let refreshRate = getRefreshRate(for: screenNumber)
            let scaleFactor = screen.backingScaleFactor

            // Ekran adını al
            let name = getDisplayName(for: screenNumber, isBuiltIn: isBuiltIn)

            let config = DisplayConfiguration(
                displayID: screenNumber,
                name: name,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                scaleFactor: scaleFactor,
                refreshRate: refreshRate,
                isMain: isMain,
                isBuiltIn: isBuiltIn,
                isRetina: scaleFactor >= 2.0,
                resolution: DisplayResolution(
                    width: Int(screen.frame.width * scaleFactor),
                    height: Int(screen.frame.height * scaleFactor)
                )
            )

            displays.append(config)
        }

        return displays.sorted { $0.isMain && !$1.isMain }
    }

    // MARK: - Display Info Helpers

    private func getRefreshRate(for displayID: CGDirectDisplayID) -> Double {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            return 60.0
        }
        return mode.refreshRate > 0 ? mode.refreshRate : 60.0
    }

    private func getDisplayName(for displayID: CGDirectDisplayID, isBuiltIn: Bool) -> String {
        if isBuiltIn {
            return "Built-in Retina Display"
        }

        // CGDisplayModelNumber ve vendor kullanarak isim oluştur
        let vendorID = CGDisplayVendorNumber(displayID)
        let modelID = CGDisplayModelNumber(displayID)

        // Bilinen vendor'lar
        let vendorNames: [UInt32: String] = [
            1552: "Samsung",
            16652: "Dell",
            30553: "LG",
            4268: "Philips",
            7789: "BenQ",
            3725: "ASUS",
            4137: "Acer",
            5765: "ViewSonic",
            1262: "Apple"
        ]

        let vendorName = vendorNames[vendorID] ?? "External Display"
        return "\(vendorName) (\(modelID))"
    }

    // MARK: - Space Management

    /// Ekranların ayrı Space'leri var mı?
    var screensHaveSeparateSpaces: Bool {
        return NSScreen.screensHaveSeparateSpaces
    }

    /// Belirli bir display için en uygun çözünürlüğü döndür
    func optimalResolution(for displayID: CGDirectDisplayID) -> DisplayResolution {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            return DisplayResolution(width: 1920, height: 1080)
        }
        return DisplayResolution(
            width: mode.pixelWidth,
            height: mode.pixelHeight
        )
    }
}
