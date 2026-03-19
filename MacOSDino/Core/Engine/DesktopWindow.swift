// DesktopWindow.swift
// MacOS-Dino – Masaüstü ikonlarının altında, wallpaper üstünde pencere
// kCGDesktopWindowLevel - 1 katmanında çalışır

import AppKit
import AVFoundation
import WebKit
import MetalKit

final class DesktopWindow: NSWindow {

    // MARK: - Properties

    let displayConfig: DisplayConfiguration
    private var videoPlayerLayerA: AVPlayerLayer?
    private var videoPlayerLayerB: AVPlayerLayer?
    private var metalView: MTKView?
    private var webView: WKWebView?
    private var imageView: NSImageView?

    // MARK: - Init

    init(display: DisplayConfiguration) {
        self.displayConfig = display
        super.init(
            contentRect: display.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
    }

    // MARK: - NSWindow Overrides

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // MARK: - Configuration

    func configure() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]

        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.contentsScale = displayConfig.scaleFactor
        }

        orderFront(nil)
    }

    // MARK: - Content Attachment

    /// Video oynatıcı ekle – İki AVPlayerLayer ile crossfade loop desteği
    func attachVideoPlayer(_ engine: VideoPlayerEngine) {
        clearContent()

        contentView?.wantsLayer = true

        // Siyah arka plan – fade/seek esnasında masaüstü görünmesin
        let blackLayer = CALayer()
        blackLayer.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        blackLayer.frame = contentView?.bounds ?? frame
        blackLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        contentView?.layer?.addSublayer(blackLayer)

        // Layer A – Birincil oynatıcı
        let layerA = AVPlayerLayer()
        layerA.videoGravity = .resizeAspectFill
        layerA.frame = contentView?.bounds ?? frame
        layerA.contentsScale = displayConfig.scaleFactor
        layerA.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layerA.opacity = 1
        contentView?.layer?.addSublayer(layerA)
        self.videoPlayerLayerA = layerA

        // Layer B – Crossfade karşılığı
        let layerB = AVPlayerLayer()
        layerB.videoGravity = .resizeAspectFill
        layerB.frame = contentView?.bounds ?? frame
        layerB.contentsScale = displayConfig.scaleFactor
        layerB.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layerB.opacity = 0
        contentView?.layer?.addSublayer(layerB)
        self.videoPlayerLayerB = layerB

        // Engine'e iki layer referansını ver
        engine.playerLayerA = layerA
        engine.playerLayerB = layerB

        // Frame değişikliklerinde boyutu güncelle
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: contentView,
            queue: .main
        ) { [weak self, weak layerA, weak layerB] _ in
            let bounds = self?.contentView?.bounds ?? .zero
            layerA?.frame = bounds
            layerB?.frame = bounds
        }
    }

    /// Metal shader view ekle
    func attachMetalView(_ view: MTKView) {
        clearContent()

        view.frame = contentView?.bounds ?? frame
        view.autoresizingMask = [.width, .height]
        view.layer?.isOpaque = false
        contentView?.addSubview(view)
        self.metalView = view
    }

    /// Web widget ekle (HTML5 saat, hava durumu vs.)
    func attachWebView(url: URL) {
        clearContent()

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let web = WKWebView(frame: contentView?.bounds ?? frame, configuration: config)
        web.autoresizingMask = [.width, .height]
        web.setValue(false, forKey: "drawsBackground")
        web.load(URLRequest(url: url))

        contentView?.addSubview(web)
        self.webView = web
    }

    /// Statik görsel ekle (Ken Burns / Parallax efektli)
    func attachStaticImage(url: URL) {
        clearContent()

        let imgView = NSImageView(frame: contentView?.bounds ?? frame)
        imgView.autoresizingMask = [.width, .height]
        imgView.imageScaling = .scaleProportionallyUpOrDown
        imgView.animates = true

        Task {
            if url.isFileURL {
                imgView.image = NSImage(contentsOf: url)
            } else {
                let (data, _) = try await URLSession.shared.data(from: url)
                imgView.image = NSImage(data: data)
            }
            applyKenBurnsAnimation(to: imgView)
        }

        contentView?.addSubview(imgView)
        self.imageView = imgView
    }

    /// Tüm içeriği temizle
    func clearContent() {
        videoPlayerLayerA?.removeFromSuperlayer()
        videoPlayerLayerA = nil
        videoPlayerLayerB?.removeFromSuperlayer()
        videoPlayerLayerB = nil

        metalView?.removeFromSuperview()
        metalView = nil

        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil

        imageView?.removeFromSuperview()
        imageView = nil
    }

    // MARK: - Ken Burns Animation

    private func applyKenBurnsAnimation(to imageView: NSImageView) {
        guard let layer = imageView.layer else { return }

        let zoomIn = CABasicAnimation(keyPath: "transform.scale")
        zoomIn.fromValue = 1.0
        zoomIn.toValue = 1.15
        zoomIn.duration = 25.0
        zoomIn.autoreverses = true
        zoomIn.repeatCount = .infinity
        zoomIn.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(zoomIn, forKey: "kenBurns")
    }

    // MARK: - Mouse Interaction (toggle)

    func setMouseInteraction(enabled: Bool) {
        ignoresMouseEvents = !enabled
    }
}
