import SwiftUI

struct DroppingLiquidView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        ZStack {
            // 1. The Gooey Liquid Core
            LiquidShaderView(viewModel: viewModel)
            
            // 2. Glass Specular Highlights (The "Glossy" Look)
            // This adds the shiny white curves that make it look like a glass tube
            RoundedRectangle(cornerRadius: 40)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.6), location: 0.0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .clear, location: 0.5),
                            .init(color: .white.opacity(0.3), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .padding(2)
            
            // 3. Inner Shadow/Depth to make the liquid look contained
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .background(
            // The empty container background
            RoundedRectangle(cornerRadius: 40)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .shadow(color: viewModel.currentThemeColor.opacity(0.4), radius: 30, x: 0, y: 10)
    }
}
