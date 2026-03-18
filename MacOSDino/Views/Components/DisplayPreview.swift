// DisplayPreview.swift
// MacOS-Dino – Çoklu Monitör Önizleme Bileşeni
// Sağ paneldeki display structure preview

import SwiftUI

struct DisplayPreview: View {
    let displays: [DisplayConfiguration]
    @Binding var selectedDisplayID: CGDirectDisplayID?

    var body: some View {
        GeometryReader { geo in
            let layout = calculateLayout(in: geo.size)

            ZStack {
                // Arka plan
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)

                // Her monitör
                ForEach(displays) { display in
                    let rect = layout[display.displayID] ?? .zero

                    Button {
                        selectedDisplayID = display.displayID
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedDisplayID == display.displayID
                                      ? .blue.opacity(0.3)
                                      : .secondary.opacity(0.2))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(
                                            selectedDisplayID == display.displayID ? .blue : .secondary,
                                            lineWidth: selectedDisplayID == display.displayID ? 2 : 1
                                        )
                                }

                            VStack(spacing: 2) {
                                Text(display.isBuiltIn ? "Built-in Retina\nDisplay" : display.name)
                                    .font(.system(size: 7))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.origin.x, y: rect.origin.y)
                }
            }
        }
    }

    /// Monitör pozisyonlarını önizleme alanına ölçekle
    private func calculateLayout(in size: CGSize) -> [CGDirectDisplayID: CGRect] {
        guard !displays.isEmpty else { return [:] }

        // Tüm ekranların bounding box'ını bul
        var minX: CGFloat = .infinity, minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity, maxY: CGFloat = -.infinity

        for d in displays {
            minX = min(minX, d.frame.origin.x)
            minY = min(minY, d.frame.origin.y)
            maxX = max(maxX, d.frame.maxX)
            maxY = max(maxY, d.frame.maxY)
        }

        let totalWidth = maxX - minX
        let totalHeight = maxY - minY

        guard totalWidth > 0, totalHeight > 0 else { return [:] }

        let padding: CGFloat = 16
        let availableWidth = size.width - padding * 2
        let availableHeight = size.height - padding * 2
        let scale = min(availableWidth / totalWidth, availableHeight / totalHeight) * 0.85

        var result: [CGDirectDisplayID: CGRect] = [:]
        for d in displays {
            let x = (d.frame.origin.x - minX) * scale + padding
            let y = (d.frame.origin.y - minY) * scale + padding
            let w = d.frame.width * scale
            let h = d.frame.height * scale
            result[d.displayID] = CGRect(x: x, y: y, width: w, height: h)
        }

        return result
    }
}
