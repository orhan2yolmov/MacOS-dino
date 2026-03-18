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
    private var videoPlayerLayer: AVPlayerLayer?
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

    // MARK: - Configuration

    func configure() {
        // Pencere katmanı: Masaüstü ikonlarının ALTINDA, wallpaper'ın ÜSTÜNDE
        // kCGDesktopWindowLevel = 20 olarak tanımlı, biz 19 kullanıyoruz
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)

        // Şeffaf ve gölgesiz
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear

        // Mouse event'leri yoksay – ikonlara tıklama çalışsın
        ignoresMouseEvents = true

        // Pencere yönetim özellikleri
        canBecomeKey = false
        canBecomeMain = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false

        // Tüm Space'lerde görünsün, pencere döngüsüne girmesin
        collectionBehavior = [
            .canJoinAllSpaces,      // Tüm masaüstlerinde
            .stationary,            // Space değişiminde yerinde kalsın
            .ignoresCycle,          // Cmd+Tab'da görünmesin
            .fullScreenAuxiliary    // Fullscreen modunda yardımcı
        ]

        // Retina desteği
        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.contentsScale = displayConfig.scaleFactor
        }

        // Pencereyi ekranda göster
        orderFront(nil)
    }

    // MARK: - Content Attachment

    /// Video oynatıcı ekle (AVFoundation + CAMetalLayer render)
    func attachVideoPlayer(_ engine: VideoPlayerEngine) {
        clearContent()

        guard let player = engine.player else { return }
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = contentView?.bounds ?? frame

        // Metal-backed rendering for Apple Silicon
        playerLayer.contentsScale = displayConfig.scaleFactor

        contentView?.wantsLayer = true
        contentView?.layer?.addSublayer(playerLayer)
        self.videoPlayerLayer = playerLayer

        // Frame değişikliklerinde boyutu güncelle
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: contentView,
            queue: .main
        ) { [weak self, weak playerLayer] _ in
            playerLayer?.frame = self?.contentView?.bounds ?? .zero
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

        // Async yükle
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
        videoPlayerLayer?.removeFromSuperlayer()
        videoPlayerLayer = nil

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
