// ShaderManager.swift
// MacOS-Dino – Metal Shader Yöneticisi
// Shader derleme, parametre geçirme, MTKView oluşturma

import MetalKit
import simd

final class ShaderManager: NSObject {

    // MARK: - Properties

    private var device: MTLDevice?
    private var library: MTLLibrary?
    private var commandQueue: MTLCommandQueue?
    private var pipelineStates: [String: MTLRenderPipelineState] = [:]

    // MARK: - Shader Uniforms

    struct ShaderUniforms {
        var time: Float = 0
        var resolution: SIMD2<Float> = .zero
        var mousePosition: SIMD2<Float> = .zero
        var audioLevel: Float = 0
        var audioSpectrum: (Float, Float, Float, Float) = (0, 0, 0, 0) // bass, mid, high, peak
        var customParam1: Float = 0
        var customParam2: Float = 0
        var customParam3: Float = 0
        var customParam4: Float = 0
    }

    // MARK: - Init

    override init() {
        super.init()
        setupMetal()
    }

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Metal desteklenmiyor!")
            return
        }

        self.device = device
        self.commandQueue = device.makeCommandQueue()

        // Default shader library'yi yükle
        do {
            self.library = try device.makeDefaultLibrary(bundle: .main)
        } catch {
            self.library = device.makeDefaultLibrary()
        }

        print("🎨 Metal hazır: \(device.name)")
    }

    // MARK: - Pipeline Creation

    func createPipeline(vertexFunction: String, fragmentFunction: String) -> MTLRenderPipelineState? {
        let key = "\(vertexFunction)+\(fragmentFunction)"
        if let cached = pipelineStates[key] {
            return cached
        }

        guard let device, let library else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: vertexFunction)
        descriptor.fragmentFunction = library.makeFunction(name: fragmentFunction)
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        do {
            let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
            pipelineStates[key] = pipeline
            return pipeline
        } catch {
            print("❌ Pipeline oluşturma hatası: \(error)")
            return nil
        }
    }

    // MARK: - Shader View Factory

    func createShaderView(
        named shaderName: String,
        frame: CGRect,
        parameters: [String: Double]? = nil
    ) -> MTKView {
        let view = MTKView(frame: frame, device: device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60

        let renderer = ShaderRenderer(
            device: device!,
            shaderName: shaderName,
            manager: self,
            parameters: parameters
        )
        view.delegate = renderer
        // Renderer'ı retain etmek için associated object kullan
        objc_setAssociatedObject(view, "renderer", renderer, .OBJC_ASSOCIATION_RETAIN)

        return view
    }

    // MARK: - Available Shaders

    static let availableShaders: [(name: String, displayName: String, description: String)] = [
        ("simpleWave", "Dalga Efekti", "Sakin ve hipnotik dalga hareketi"),
        ("cursorRepel", "Fare Etkileşimi", "Fare imlecini takip eden parçacıklar"),
        ("audioReactive", "Ses Reaktif", "Müziğe tepki veren görsel dalga"),
        ("liquidGlass", "Liquid Glass", "macOS Tahoe Liquid Glass refraction efekti"),
        ("nebula", "Nebula", "Uzay nebula animasyonu"),
        ("matrix", "Matrix Rain", "Matrix film efekti yağmur"),
        ("fireflies", "Ateş Böcekleri", "Karanlıkta uçuşan ateş böcekleri"),
        ("gradient", "Canlı Gradyan", "Yavaşça dönen renk geçişleri"),
    ]
}

// MARK: - Shader Renderer (MTKViewDelegate)

final class ShaderRenderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue?
    private let pipelineState: MTLRenderPipelineState?
    private var uniforms = ShaderManager.ShaderUniforms()
    private let startTime: CFTimeInterval
    private var parameters: [String: Double]

    init(device: MTLDevice, shaderName: String, manager: ShaderManager, parameters: [String: Double]?) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.startTime = CACurrentMediaTime()
        self.parameters = parameters ?? [:]

        // Pipeline oluştur
        self.pipelineState = manager.createPipeline(
            vertexFunction: "vertex_passthrough",
            fragmentFunction: "fragment_\(shaderName)"
        )

        super.init()

        // Fare pozisyonunu takip et
        setupMouseTracking()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.resolution = SIMD2<Float>(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipeline = pipelineState else {
            return
        }

        // Uniformları güncelle
        uniforms.time = Float(CACurrentMediaTime() - startTime)
        uniforms.mousePosition = currentMousePosition(in: view)

        // Custom parametreler
        uniforms.customParam1 = Float(parameters["param1"] ?? 0)
        uniforms.customParam2 = Float(parameters["param2"] ?? 0)
        uniforms.customParam3 = Float(parameters["param3"] ?? 0)
        uniforms.customParam4 = Float(parameters["param4"] ?? 0)

        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ShaderManager.ShaderUniforms>.size, index: 0)

        // Fullscreen quad çiz
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Mouse Tracking

    private func setupMouseTracking() {
        // Global mouse location tracking
    }

    private func currentMousePosition(in view: MTKView) -> SIMD2<Float> {
        let location = NSEvent.mouseLocation
        let viewFrame = view.window?.frame ?? .zero
        let x = Float((location.x - viewFrame.origin.x) / viewFrame.width)
        let y = Float((location.y - viewFrame.origin.y) / viewFrame.height)
        return SIMD2<Float>(x, y)
    }
}
