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
    @State private var lastAngle: Double? // Previous finger angle, for delta tracking
    @State private var lastHapticValue: Int = 0 // Track for haptics

    // Computed property to center the coordinate system for drag math
    private var center: CGPoint {
        CGPoint(x: radius + 30, y: radius + 30)
    }

    /// Angle of the touch point measured from the gear centre, in degrees.
    private func angle(to location: CGPoint) -> Double {
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        return atan2(vector.dy, vector.dx) * 180 / .pi
    }

    /// Rotation can accumulate past a full turn; map it back into 0..<totalRange.
    private func wrappedValue(for rotation: Double) -> Double {
        let raw = (rotation / 360.0) * totalRange
        let wrapped = raw.truncatingRemainder(dividingBy: totalRange)
        return wrapped < 0 ? wrapped + totalRange : wrapped
    }

    /// The angle equivalent to `value` that sits closest to the current rotation,
    /// so an external update never animates a spurious full spin.
    private func nearestRotation(for value: Double) -> Double {
        let target = (value / totalRange) * 360.0
        return target + ((rotation - target) / 360.0).rounded() * 360.0
    }
    
    // Haptics
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
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
        // Touch Area: Strictly defined ring at radius
        // Frame is radius*2 + 60 -> "Radius" of view is r+30.
        // We want ring at `radius`. Indent = 30.
        .contentShape(
             Circle()
                .inset(by: 30) // Moves from edge (r+30) to (r)
                .stroke(lineWidth: 40) // Clickable area width
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    let current = angle(to: gesture.location)

                    guard let previous = lastAngle else {
                        // First touch only establishes a reference: the gear must
                        // turn by how far the finger travels, not jump to where it landed.
                        lastAngle = current
                        isDragging = true
                        onInteract(true)
                        return
                    }

                    // Shortest signed delta, so crossing the ±180° seam doesn't spin the gear.
                    var delta = current - previous
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }

                    lastAngle = current
                    rotation += delta

                    // Wraps freely past 0 and 59 in both directions.
                    value = wrappedValue(for: rotation)

                    // Haptic Feedback Logic
                    let intValue = Int(value)
                    if intValue != lastHapticValue {
                        lastHapticValue = intValue
                        if intValue % 5 == 0 {
                            impactFeedback.impactOccurred(intensity: 1.0) // Stronger click for 5, 10, 15...
                        } else {
                            impactFeedback.impactOccurred(intensity: 0.5) // Light click for 1, 2, 3...
                        }
                    }
                }
                .onEnded { _ in
                    // Snap to the nearest tick, keeping any accumulated turns.
                    let snapStep = 360.0 / Double(visibleTicks)
                    let snappedRot = round(rotation / snapStep) * snapStep

                    withAnimation(.spring) {
                        rotation = snappedRot
                    }
                    value = wrappedValue(for: snappedRot)

                    lastAngle = nil
                    isDragging = false
                    onInteract(false)
                }
        )
        .onAppear {
            rotation = (value / totalRange) * 360.0
        }
        .onChange(of: value) {
            // Only sync if NOT dragging to avoid feedback loop
            if !isDragging {
                withAnimation(.interactiveSpring) {
                    rotation = nearestRotation(for: value)
                }
            }
        }
        .frame(width: radius * 2 + 60, height: radius * 2 + 60)
    }
}
