import SwiftUI

public struct LiquidGlassBackground: View {
    public init() {}
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.05),
                    Color.black.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

public extension View {
    func liquidGlassScreenBackground() -> some View {
        self.background(LiquidGlassBackground())
    }
    
    func liquidGlassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
}
