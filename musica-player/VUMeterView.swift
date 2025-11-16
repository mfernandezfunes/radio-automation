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
    
    private var normalizedLeft: Float {
        min(max(leftLevel, 0), 1)
    }
    
    private var normalizedRight: Float {
        min(max(rightLevel, 0), 1)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Left channel - vertical bars
            VStack(spacing: 1) {
                ForEach((0..<barCount).reversed(), id: \.self) { index in
                    Rectangle()
                        .fill(barColor(for: index, level: normalizedLeft))
                        .frame(width: 8, height: 4)
                }
            }
            .frame(width: 8)
            
            // Right channel - vertical bars
            VStack(spacing: 1) {
                ForEach((0..<barCount).reversed(), id: \.self) { index in
                    Rectangle()
                        .fill(barColor(for: index, level: normalizedRight))
                        .frame(width: 8, height: 4)
                }
            }
            .frame(width: 8)
        }
    }
    
    private func barColor(for index: Int, level: Float) -> Color {
        let threshold = Float(index) / Float(barCount)
        if level < threshold {
            return Color.gray.opacity(0.3)
        }
        
        // Color gradient: green -> yellow -> red
        let position = Float(index) / Float(barCount)
        if position < 0.6 {
            return Color.green
        } else if position < 0.85 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
}

#Preview {
    VUMeterView(leftLevel: 0.7, rightLevel: 0.5)
        .padding()
}

