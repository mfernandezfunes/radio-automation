//
//  KnobView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct KnobView: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    let unit: String
    
    @State private var isDragging: Bool = false
    @State private var startValue: Float = 0
    @State private var startY: CGFloat = 0
    
    // Ángulo de rotación: -150° a 150° (300° total)
    private var rotationAngle: Double {
        let normalized = Double((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return -150.0 + (normalized * 300.0) // -150° a 150°
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                // Fondo de la perilla
                Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(NSColor.controlBackgroundColor),
                                    Color(NSColor.controlBackgroundColor).opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Borde exterior
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                
                // Marcas de escala
                ForEach(0..<11) { index in
                    let angle = -150.0 + (Double(index) * 30.0)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2, height: index % 5 == 0 ? 8 : 4)
                        .offset(y: -36)
                        .rotationEffect(.degrees(angle))
                }
                
                // Indicador de posición (puntero)
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 30)
                    .offset(y: -25)
                    .rotationEffect(.degrees(rotationAngle))
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 2)
                
                // Centro de la perilla
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 20
                        )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            startValue = value
                            startY = gesture.startLocation.y
                        }
                        
                        // Calcular cambio basado en movimiento vertical
                        // Arrastrar hacia arriba aumenta el valor, hacia abajo lo disminuye
                        let deltaY = startY - gesture.location.y
                        let sensitivity: CGFloat = 2.0 // Sensibilidad: 2 unidades por píxel
                        let valueRange = range.upperBound - range.lowerBound
                        // Normalizar el movimiento vertical a un cambio proporcional del rango
                        let deltaValue = Float(deltaY * sensitivity) * (valueRange / 240.0) // 240px = altura típica de arrastre
                        
                        let newValue = startValue + deltaValue
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .frame(width: 80, height: 80)
            
            // Valor actual
            Text(String(format: "%.1f %@", value, unit))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .monospacedDigit()
                .frame(height: 16)
        }
        .frame(width: 100)
    }
}

#Preview {
    HStack(spacing: 30) {
        KnobView(
            value: .constant(0.0),
            range: -12...12,
            label: "Bajos",
            unit: "dB"
        )
        
        KnobView(
            value: .constant(3.5),
            range: -12...12,
            label: "Medios",
            unit: "dB"
        )
        
        KnobView(
            value: .constant(-2.0),
            range: -12...12,
            label: "Agudos",
            unit: "dB"
        )
    }
    .padding()
}

