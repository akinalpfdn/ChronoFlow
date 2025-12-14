import SwiftUI

struct ChronoFlowMainView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        ZStack {
            // 1. Deep Background (Required for Glass refraction)
            Color.black.ignoresSafeArea()
            
            // 2. Liquid Physics Background
            LiquidBackgroundView(progress: $viewModel.progress, color: viewModel.currentThemeColor)
                .ignoresSafeArea()
            
            // 3. Floating Interface
            VStack {
                Spacer()
                
                // NATIVE API: Text with glass material
                Text(viewModel.timeFormatted)
                    .font(.system(size: 130, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                Text(viewModel.statusText)
                    .font(.caption)
                    .tracking(8)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 4. NATIVE GLASS BUTTONS
                HStack(spacing: 60) {
                    Button(action: viewModel.resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                    }
                    .buttonStyle(.glass) // Native iOS 26 style
                    
                    Button(action: viewModel.toggleTimer) {
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                            .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.glassProminent) // Native "Prominent" glass style
                }
                .padding(.bottom, 60)
            }
        }
    }
}
