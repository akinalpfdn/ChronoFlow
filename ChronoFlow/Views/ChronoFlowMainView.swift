import SwiftUI

struct ChronoFlowMainView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var isSelectionActive = false
    
    var body: some View {
        ZStack {
            // 1. Deep Background (Required for Glass refraction)
            Color.black.ignoresSafeArea()
            
            // 2. Liquid Physics Background
            LiquidBackgroundView(progress: $viewModel.progress, color: viewModel.currentThemeColor)
                .ignoresSafeArea()
                .opacity(isSelectionActive ? 0.3 : 1.0) // Dim liquid when selecting
                .animation(.easeInOut, value: isSelectionActive)
            
            // 3. Floating Interface
            VStack {
                Spacer()
                
                // Combined Time Display + Selector
                GearTimeSelector(
                    totalTime: Binding(
                        get: { viewModel.currentTime }, // Read current time for animation
                        set: { viewModel.updateTotalTime($0) } // Set total time on interaction
                    ),
                    isSelectionActive: $isSelectionActive
                )
                
                if !isSelectionActive {
                    Text(viewModel.statusText)
                        .font(.caption)
                        .tracking(8)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
                
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
