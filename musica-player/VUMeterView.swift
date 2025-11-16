//
//  VUMeterView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct VUMeterView: View {
    let leftLevel: Float
    let rightLevel: Float
    let barCount: Int = 20
    var orientation: Orientation = .vertical
    
    enum Orientation {
        case vertical
        case horizontal
    }
    
    private var normalizedLeft: Float {
        min(max(leftLevel, 0), 1)
    }
    
    private var normalizedRight: Float {
        min(max(rightLevel, 0), 1)
    }
    
    var body: some View {
        if orientation == .horizontal {
            // Horizontal layout
            VStack(spacing: 8) {
                // Left channel - horizontal LED style
                HStack(spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { index in
                        Circle()
                            .fill(barColor(for: index, level: normalizedLeft))
                            .frame(width: 6, height: 6)
                            .shadow(color: barColor(for: index, level: normalizedLeft).opacity(0.6), radius: normalizedLeft >= Float(index) / Float(barCount) ? 3 : 0)
                    }
                }
                
                // Right channel - horizontal LED style
                HStack(spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { index in
                        Circle()
                            .fill(barColor(for: index, level: normalizedRight))
                            .frame(width: 6, height: 6)
                            .shadow(color: barColor(for: index, level: normalizedRight).opacity(0.6), radius: normalizedRight >= Float(index) / Float(barCount) ? 3 : 0)
                    }
                }
            }
        } else {
            // Vertical layout (default)
            HStack(spacing: 6) {
                // Left channel - LED style
                VStack(spacing: 2) {
                    ForEach((0..<barCount).reversed(), id: \.self) { index in
                        Circle()
                            .fill(barColor(for: index, level: normalizedLeft))
                            .frame(width: 6, height: 6)
                            .shadow(color: barColor(for: index, level: normalizedLeft).opacity(0.6), radius: normalizedLeft >= Float(index) / Float(barCount) ? 3 : 0)
                    }
                }
                
                // Right channel - LED style
                VStack(spacing: 2) {
                    ForEach((0..<barCount).reversed(), id: \.self) { index in
                        Circle()
                            .fill(barColor(for: index, level: normalizedRight))
                            .frame(width: 6, height: 6)
                            .shadow(color: barColor(for: index, level: normalizedRight).opacity(0.6), radius: normalizedRight >= Float(index) / Float(barCount) ? 3 : 0)
                    }
                }
            }
        }
    }
    
    private func barColor(for index: Int, level: Float) -> Color {
        let threshold = Float(index) / Float(barCount)
        if level < threshold {
            return Color.gray.opacity(0.2)
        }
        
        // Color gradient: green -> yellow -> red (LED style)
        let position = Float(index) / Float(barCount)
        if position < 0.6 {
            return Color.green.opacity(0.9)
        } else if position < 0.85 {
            return Color.yellow.opacity(0.9)
        } else {
            return Color.red.opacity(0.9)
        }
    }
}

#Preview {
    VUMeterView(leftLevel: 0.7, rightLevel: 0.5)
        .padding()
}

