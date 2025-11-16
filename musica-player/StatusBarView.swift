//
//  StatusBarView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct StatusBarView: View {
    @State private var currentTime = Date()
    var onAutoArrange: (() -> Void)? = nil
    var onOpenPlayer1: (() -> Void)? = nil
    var onOpenPlayer2: (() -> Void)? = nil
    
    init(onAutoArrange: (() -> Void)? = nil, onOpenPlayer1: (() -> Void)? = nil, onOpenPlayer2: (() -> Void)? = nil) {
        self.onAutoArrange = onAutoArrange
        self.onOpenPlayer1 = onOpenPlayer1
        self.onOpenPlayer2 = onOpenPlayer2
    }
    
    var body: some View {
        HStack(spacing: 30) {
            // Player 1 button
            Button(action: {
                onOpenPlayer1?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title3)
                    Text("Player 1")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Current Time and Auto-arrange button
            VStack(alignment: .center, spacing: 8) {
                Text(currentTime, style: .time)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.medium)
                
                Button(action: {
                    onAutoArrange?()
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Auto-arrange player windows")
            }
            
            Spacer()
            
            // Player 2 button
            Button(action: {
                onOpenPlayer2?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title3)
                    Text("Player 2")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 70)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
        .onAppear {
            // Update time every second
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}

#Preview {
    StatusBarView()
        .frame(width: 1000)
}

