import SwiftUI
import SpriteKit
import CoreMotion

// MARK: - Physics Scene

class LiquidGameScene: SKScene {
    static let circleRadius = 7.0 // Slightly smaller for finer liquid
    static let maxBalls = 1500 // Increased count for smoother look
    
    var motionManager: CMMotionManager?
    var nodes = [SKNode]()
    
    // Target fill percentage (0.0 to 1.0)
    var fillPercentage: Double = 0.0
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        // Define boundaries
        // We extend the top effectively infinitely so balls can fall from "above"
        let boundaryFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height + 2000
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryFrame)
        physicsBody?.friction = 0.1
        physicsBody?.restitution = 0.1 // Low bounce for water-like feel
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // 1. Update Gravity from Gyro
        if let data = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: data.acceleration.x * 20, dy: data.acceleration.y * 20)
        }
        
        // 2. Manage Particle Count based on fillPercentage
        let targetCount = Int(Double(Self.maxBalls) * fillPercentage)
        
        if nodes.count < targetCount {
            // Add balls
            // Spawn them at top random x
            // Don't spawn too many per frame to avoid lag spikes
            let needed = targetCount - nodes.count
            let spawnRate = 10
            let toSpawn = min(needed, spawnRate)
            
            for _ in 0..<toSpawn {
                spawnBall()
            }
        } else if nodes.count > targetCount {
            // Remove balls
            // Remove from the top (last added) or bottom?
            // Removing from indices 0 is usually oldest.
            let toRemove = min(nodes.count - targetCount, 10)
            for _ in 0..<toRemove {
                if let node = nodes.last {
                    node.removeFromParent()
                    nodes.removeLast()
                }
            }
        }
    }
    
    private func spawnBall() {
        let node = SKShapeNode(circleOfRadius: Self.circleRadius)
        // Use ShapeNode for debugging if needed, but for the Canvas renderer we just need position.
        // Actually, sample.swift uses SKNode and draws in Canvas.
        // Let's use bare SKNode with physics body for performance, visual is handled by canvas.
        let ball = SKNode()
        
        // Spawn randomly above the visible area
        // Or if percentage is low, spawn them.
        let spawnY = frame.height + CGFloat.random(in: 50...200)
        let spawnX = CGFloat.random(in: 10...(frame.width - 10))
        
        ball.position = CGPoint(x: spawnX, y: spawnY)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: Self.circleRadius)
        ball.physicsBody?.friction = 0.1
        ball.physicsBody?.restitution = 0.1
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.density = 1.0
        
        addChild(ball)
        nodes.append(ball)
    }
}

// MARK: - SwiftUI View

struct LiquidBackgroundView: View {
    @Binding var progress: Double // 0.0 to 1.0
    var color: Color
    
    @State private var scene = LiquidGameScene()
    
    var body: some View {
        ZStack {
            // Physics Simulation Layer (Invisible)
            GeometryReader { proxy in
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .onAppear {
                        scene.size = proxy.size
                        scene.scaleMode = .resizeFill
                    }
                    .onChange(of: progress) {
                        scene.fillPercentage = progress
                    }
                    // Initial sync
                    .onAppear {
                         scene.fillPercentage = progress
                    }
            }
            .opacity(0) // Hide the SpriteKit view itself
            
            // Rendering Layer (Metaballs)
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    // We don't really need time, but accessing it drives the update loop
                    
                    // Metaball Filter Chain
                    // 1. Draw blurred circles
                    // 2. Threshold alpha
                    
                    ctx.addFilter(.alphaThreshold(min: 0.5, color: color))
                    ctx.addFilter(.blur(radius: 12)) // Blur amount controls "gooeyness"
                    
                    ctx.drawLayer { layerCtx in
                        for node in scene.nodes {
                            // Convert SpriteKit coordinates to SwiftUI Canvas coordinates
                            // SpriteKit: (0,0) is bottom-left. Canvas: (0,0) is top-left.
                            let p = node.position
                            let y = size.height - p.y
                            let x = p.x
                            
                            let r = LiquidGameScene.circleRadius
                            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                            
                            layerCtx.fill(Circle().path(in: rect), with: .color(.white))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false) // Let touches pass through to buttons
    }
}
