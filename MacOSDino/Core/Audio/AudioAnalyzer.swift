// AudioAnalyzer.swift
// MacOS-Dino – Ses Analiz Motoru
// AVAudioEngine + FFT ile gerçek zamanlı ses frekans analizi

import AVFoundation
import Accelerate

@MainActor
final class AudioAnalyzer: ObservableObject {

    // MARK: - Published

    @Published var audioLevel: Float = 0
    @Published var bass: Float = 0      // 20-250 Hz
    @Published var mid: Float = 0       // 250-4000 Hz
    @Published var high: Float = 0      // 4000-20000 Hz
    @Published var peak: Float = 0
    @Published var isListening = false

    // MARK: - Audio Engine

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let bufferSize: AVAudioFrameCount = 1024
    private let sampleRate: Double = 44100.0

    // FFT
    private var fftSetup: vDSP_DFT_Setup?
    private var fftMagnitudes: [Float] = []

    // MARK: - Start/Stop

    func startListening() {
        guard !isListening else { return }

        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }

        inputNode = engine.inputNode
        guard let input = inputNode else { return }

        let format = input.outputFormat(forBus: 0)

        // FFT setup
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(bufferSize),
            .FORWARD
        )

        // Audio tap
        input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }

        do {
            try engine.start()
            isListening = true
            print("🎵 AudioAnalyzer dinlemeye başladı")
        } catch {
            print("❌ Audio engine başlatılamadı: \(error)")
        }
    }

    func stopListening() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        isListening = false

        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
            fftSetup = nil
        }
    }

    // MARK: - Audio Processing

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // RMS seviye hesapla
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))

        // Peak seviye
        var peakVal: Float = 0
        vDSP_maxv(channelData, 1, &peakVal, vDSP_Length(frameLength))

        // FFT analizi
        performFFT(channelData, frameLength: frameLength)

        // Frekans bantlarını hesapla
        let bassRange = frequencyBandPower(lowFreq: 20, highFreq: 250)
        let midRange = frequencyBandPower(lowFreq: 250, highFreq: 4000)
        let highRange = frequencyBandPower(lowFreq: 4000, highFreq: 20000)

        // Ana thread'de güncelle
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Smoothing (EMA - Exponential Moving Average)
            let smoothing: Float = 0.3
            self.audioLevel = self.audioLevel * (1 - smoothing) + rms * smoothing
            self.bass = self.bass * (1 - smoothing) + bassRange * smoothing
            self.mid = self.mid * (1 - smoothing) + midRange * smoothing
            self.high = self.high * (1 - smoothing) + highRange * smoothing
            self.peak = max(self.peak * 0.95, peakVal) // Yavaş düşüş
        }
    }

    private func performFFT(_ data: UnsafeMutablePointer<Float>, frameLength: Int) {
        guard let fftSetup else { return }

        let count = Int(bufferSize)
        var realInput = [Float](repeating: 0, count: count)
        var imagInput = [Float](repeating: 0, count: count)
        var realOutput = [Float](repeating: 0, count: count)
        var imagOutput = [Float](repeating: 0, count: count)

        // Giriş verisini kopyala
        for i in 0..<min(frameLength, count) {
            realInput[i] = data[i]
        }

        // Hanning penceresi uygula
        var window = [Float](repeating: 0, count: count)
        vDSP_hann_window(&window, vDSP_Length(count), Int32(vDSP_HANN_NORM))
        vDSP_vmul(realInput, 1, window, 1, &realInput, 1, vDSP_Length(count))

        // FFT hesapla
        vDSP_DFT_Execute(fftSetup, realInput, imagInput, &realOutput, &imagOutput)

        // Magnitude hesapla
        fftMagnitudes = [Float](repeating: 0, count: count / 2)
        for i in 0..<count/2 {
            fftMagnitudes[i] = sqrt(realOutput[i] * realOutput[i] + imagOutput[i] * imagOutput[i])
        }
    }

    private func frequencyBandPower(lowFreq: Float, highFreq: Float) -> Float {
        guard !fftMagnitudes.isEmpty else { return 0 }

        let binCount = fftMagnitudes.count
        let freqPerBin = Float(sampleRate) / Float(bufferSize)

        let lowBin = max(0, Int(lowFreq / freqPerBin))
        let highBin = min(binCount - 1, Int(highFreq / freqPerBin))

        guard lowBin < highBin else { return 0 }

        var sum: Float = 0
        for i in lowBin...highBin {
            sum += fftMagnitudes[i]
        }

        return sum / Float(highBin - lowBin + 1)
    }

    // Not: WallpaperEngine stopListening()'i lifecycle'da explicit çağırır
}
