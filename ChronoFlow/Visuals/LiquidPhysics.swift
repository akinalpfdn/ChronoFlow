import SwiftUI
import SpriteKit
import CoreMotion

// MARK: - Physics Scene

class LiquidGameScene: SKScene {
    // Tuning knobs. Fewer, larger balls cover the same area for roughly half
    // the simulation and draw cost; adjust together if the liquid looks sparse.
    static let maxBalls = 300
    static let circleRadius = 20.0

    /// Matches the magnitude the accelerometer produces when the phone is held
    /// upright, so switching tilt off doesn't change how heavy the liquid feels.
    static let restGravity = CGVector(dx: 0, dy: -50)

    /// Simulating and drawing goo above 30fps is not perceptible once blurred.
    static let framesPerSecond = 30

    var nodes = [SKNode]()

    // Target fill percentage (0.0 to 1.0)
    var fillPercentage: Double = 0.0

    /// Off under Reduce Motion: gravity stays fixed and the accelerometer stops.
    var tiltEnabled: Bool = true {
        didSet {
            guard tiltEnabled != oldValue else { return }
            applyTiltSetting()
        }
    }

    private var motionManager: CMMotionManager?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true

        // Define boundaries
        // We extend the top effectively infinitely so balls can fall from "above"
        let boundaryFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height + 2000
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryFrame)
        physicsBody?.friction = 0.0
        physicsBody?.restitution = 0.0 // No bounce, maximizes fluid feel

        physicsWorld.gravity = Self.restGravity

        motionManager = CMMotionManager()
        applyTiltSetting()
    }

    override func willMove(from view: SKView) {
        motionManager?.stopAccelerometerUpdates()
    }

    private func applyTiltSetting() {
        guard let motionManager else { return }
        if tiltEnabled {
            motionManager.startAccelerometerUpdates()
        } else {
            motionManager.stopAccelerometerUpdates()
            physicsWorld.gravity = Self.restGravity
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // 1. Update Gravity from Gyro
        if tiltEnabled, let data = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: data.acceleration.x * 50, dy: data.acceleration.y * 50)
        }

        // 2. Manage Particle Count
        let targetCount = Int(Double(Self.maxBalls) * fillPercentage)

        if nodes.count < targetCount {
            let needed = targetCount - nodes.count
            // Spawn rate to fill up reasonably fast
            let spawnRate = 15
            let toSpawn = min(needed, spawnRate)

            for _ in 0..<toSpawn {
                spawnBall()
            }
        } else if nodes.count > targetCount {
            let toRemove = min(nodes.count - targetCount, 15)
            for _ in 0..<toRemove {
                if let node = nodes.last {
                    node.removeFromParent()
                    nodes.removeLast()
                }
            }
        }
    }

    private func spawnBall() {
        // We use lightweight SKNodes for physics only.
        // Visuals are handled by the SwiftUI Canvas.
        let ball = SKNode()

        // Spawn randomly above the visible area
        let spawnY = frame.height + CGFloat.random(in: 50...400)
        let spawnX = CGFloat.random(in: 10...(frame.width - 10))

        ball.position = CGPoint(x: spawnX, y: spawnY)

        ball.physicsBody = SKPhysicsBody(circleOfRadius: Self.circleRadius)
        ball.physicsBody?.friction = 0.0
        ball.physicsBody?.restitution = 0.0
        ball.physicsBody?.linearDamping = 0.0 // Flow like water (was 0.1)
        ball.physicsBody?.angularDamping = 0.0
        ball.physicsBody?.density = 1.0

        addChild(ball)
        nodes.append(ball)
    }
}

// MARK: - SwiftUI View

struct LiquidBackgroundView: View {
    @Binding var progress: Double // 0.0 to 1.0
    var color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scene = LiquidGameScene()

    var body: some View {
        ZStack {
            // Invisible Physics Layer
            // We use this to drive the simulation, but we don't draw it.
            GeometryReader { proxy in
                SpriteView(
                    scene: scene,
                    preferredFramesPerSecond: LiquidGameScene.framesPerSecond,
                    options: [.allowsTransparency]
                )
                .onAppear {
                    scene.size = proxy.size
                    scene.scaleMode = .resizeFill
                    scene.fillPercentage = progress
                    scene.tiltEnabled = !reduceMotion
                }
                .onChange(of: progress) {
                    scene.fillPercentage = progress
                }
                .onChange(of: reduceMotion) {
                    scene.tiltEnabled = !reduceMotion
                }
            }
            .opacity(0.0) // Completely hide the SpriteKit view
            .allowsHitTesting(false)

            // Rendering Layer (Canvas + Metaballs)
            // Capped to the simulation rate: redrawing faster only re-runs the
            // blur and threshold filters over identical positions.
            TimelineView(.animation(minimumInterval: 1.0 / Double(LiquidGameScene.framesPerSecond))) { timeline in
                Canvas { ctx, size in
                    let _ = timeline.date

                    // Metaball filter chain: draw opaque circles, blur them so
                    // overlapping alphas merge, then threshold to cut a hard edge.
                    ctx.addFilter(.alphaThreshold(min: 0.5, color: color))
                    ctx.addFilter(.blur(radius: 12))

                    ctx.drawLayer { layerCtx in
                        for node in scene.nodes {
                            // Coordinate flip: SpriteKit (0,0 bottom-left) -> Canvas (0,0 top-left)
                            let p = node.position
                            let y = size.height - p.y
                            let x = p.x

                            // Visual Trick: Draw larger than physics body to close gaps
                            let rPhysics = LiquidGameScene.circleRadius
                            let rVisual = rPhysics * 1.3

                            let rect = CGRect(x: x - rVisual, y: y - rVisual, width: rVisual * 2, height: rVisual * 2)

                            layerCtx.fill(Circle().path(in: rect), with: .color(.white))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
