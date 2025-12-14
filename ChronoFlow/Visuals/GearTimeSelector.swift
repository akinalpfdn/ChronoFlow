import SwiftUI

struct GearTimeSelector: View {
    @Binding var totalTime: Double
    @Binding var isSelectionActive: Bool // To hide other UI elements while selecting
    
    // Config
    let minRadius: CGFloat = 120
    let secRadius: CGFloat = 175
    
    var body: some View {
        ZStack {
            // Background blur to separate from liquid (Optional visual reinforcement)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: secRadius * 2.5, height: secRadius * 2.5)
                .opacity(isSelectionActive ? 1 : 0)
                .scaleEffect(isSelectionActive ? 1 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelectionActive)
            
            // Central Time Display
            // Note: We use bindings inline for the text to ensure it updates with the gears
            let m = Int(totalTime) / 60
            let s = Int(totalTime) % 60
            
            VStack(spacing: 0) {
                Text(String(format: "%02d:%02d", m, s))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                if isSelectionActive {
                    Text("MIN       SEC")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .tracking(4)
                        .transition(.opacity)
                }
            }
            .zIndex(1) 
            
            // 1. Minutes Gear (Inner)
            SingleGear(
                radius: minRadius,
                color: .cyan,
                visibleTicks: 60,
                totalRange: 60,
                value: Binding(get: {
                    Double(Int(totalTime) / 60)
                }, set: { newVal in
                    let s = Int(totalTime) % 60
                    totalTime = Double(Int(newVal) * 60 + s)
                }),
                onInteract: { active in isSelectionActive = active }
            )
            
            // 2. Seconds Gear (Outer)
            SingleGear(
                radius: secRadius,
                color: .orange,
                visibleTicks: 60,
                totalRange: 60,
                value: Binding(get: {
                    Double(Int(totalTime) % 60)
                }, set: { newVal in
                    let m = Int(totalTime) / 60
                    totalTime = Double(m * 60 + Int(newVal))
                }),
                onInteract: { active in isSelectionActive = active }
            )
        }
    }
}

struct SingleGear: View {
    let radius: CGFloat
    let color: Color
    let visibleTicks: Int
    let totalRange: Double
    @Binding var value: Double
    var onInteract: (Bool) -> Void
    
    @State private var rotation: Double = 0
    @State private var isDragging: Bool = false
    
    // Computed property to center the coordinate system for drag math
    private var center: CGPoint {
        CGPoint(x: radius + 30, y: radius + 30)
    }
    
    var body: some View {
        ZStack {
            // Ticks
            ForEach(0..<visibleTicks, id: \.self) { index in
                ZStack {
                    // Tick Mark
                    Rectangle()
                        .fill(index % 5 == 0 ? color : color.opacity(0.3))
                        .frame(width: index % 5 == 0 ? 3 : 1.5, height: index % 5 == 0 ? 15 : 8)
                        .offset(y: -radius)
                    
                    // Number (every 5)
                    if index % 5 == 0 {
                        Text("\(Int(Double(index) / Double(visibleTicks) * totalRange))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                            .rotationEffect(.degrees(-Double(index) / Double(visibleTicks) * 360)) // Counter-rotate text
                            .offset(y: -(radius - 25))
                    }
                }
                .rotationEffect(.degrees(Double(index) / Double(visibleTicks) * 360))
            }
            .rotationEffect(.degrees(rotation))
            
            // Indicators / "Galaxy Watch" Bezel
            Circle()
                .strokeBorder(
                    AngularGradient(colors: [color.opacity(0), color.opacity(0.5), color.opacity(0)], center: .center, startAngle: .degrees(0), endAngle: .degrees(360))
                    , lineWidth: 20
                )
                .frame(width: radius * 2 + 20, height: radius * 2 + 20)
                .rotationEffect(.degrees(rotation))
                .opacity(0.3)
        }
        // Touch Area
        .contentShape(Circle().inset(by: -20).stroke(lineWidth: 40)) // Don't block center
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        onInteract(true)
                    }
                    
                    // Calculate angle from center
                    let vector = CGVector(dx: gesture.location.x - center.x, dy: gesture.location.y - center.y)
                    let angle = atan2(vector.dy, vector.dx) * 180 / .pi + 90
                    
                    // Normalize to 0-360
                    var normalizedAngle = angle
                    if normalizedAngle < 0 { normalizedAngle += 360 }
                    
                    // Update visual rotation immediately to track finger
                    withAnimation(.interactiveSpring) {
                        rotation = normalizedAngle
                    }
                    
                    // Map to value
                    let newValue = (normalizedAngle / 360.0) * totalRange
                    value = min(max(0, newValue), totalRange)
                }
                .onEnded { _ in
                    isDragging = false
                    onInteract(false)
                    // Snap logic
                    let snapStep = 360.0 / Double(visibleTicks)
                    let snappedRot = round(rotation / snapStep) * snapStep
                    withAnimation(.spring) {
                        rotation = snappedRot
                    }
                }
        )
        .onAppear {
            rotation = (value / totalRange) * 360.0
        }
        .onChange(of: value) {
            // Only sync if NOT dragging to avoid feedback loop
            if !isDragging {
                let targetRot = (value / totalRange) * 360.0
                withAnimation(.interactiveSpring) {
                    rotation = targetRot
                }
            }
        }
        .frame(width: radius * 2 + 60, height: radius * 2 + 60)
    }
}
