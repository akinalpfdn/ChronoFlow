import SwiftUI
import SpriteKit
import CoreMotion

// MARK: - Physics Scene

class LiquidGameScene: SKScene {
    // Reduced count slightly from sample to ensure stability, but high enough for good liquid
    static let maxBalls = 600
    // Radius for the physics body
    static let circleRadius = 15.0
    
    var motionManager: CMMotionManager?
    var nodes = [SKNode]()
    
    // Target fill percentage (0.0 to 1.0)
    var fillPercentage: Double = 0.0
    
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
        
        // Default Gravity
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // 1. Update Gravity from Gyro
        if let data = motionManager?.accelerometerData {
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
    
    @State private var scene = LiquidGameScene()
    
    var body: some View {
        ZStack {
            // Invisible Physics Layer
            // We use this to drive the simulation, but we don't draw it.
            GeometryReader { proxy in
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .onAppear {
                        scene.size = proxy.size
                        scene.scaleMode = .resizeFill
                    }
                    .onChange(of: progress) {
                        scene.fillPercentage = progress
                    }
                    .onAppear {
                         scene.fillPercentage = progress
                    }
            }
            .opacity(0.0) // Completely hide the SpriteKit view
            .allowsHitTesting(false)
            
            // Rendering Layer (Canvas + Metaballs)
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let _ = timeline.date
                    
                    // Metaball Filter Chain (Derived from sample.swift)
                    // 1. Threshold Alpha: This creates the sharp "Liquid" hard edge.
                    //    Crucial: Must be applied BEFORE or AFTER the blur? 
                    //    In sample.swift: Threshold then Blur? No, usually Blur then Threshold.
                    //    Sample.swift code:
                    //       ctx.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    //       ctx.addFilter(.blur(radius: 32))
                    //    Actually, SwiftUI filters are applied in order.
                    //    To make metaballs: Draw Circles -> Blur -> Threshold.
                    //
                    //    Wait, sample.swift does:
                    //       ctx.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    //       ctx.addFilter(.blur(radius: 32))
                    //    This seems backwards for standard metaballs (usually Blur -> Threshold), 
                    //    BUT if the sample works that way, we should respect it.
                    //    However, standard metaball theory is: Blur overlapping shapes to merge alphas, then threshold to cut at a specific alpha.
                    //    Let's try the standard order which guarantees sharp edges:
                    
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
                } symbols: {
                    // Symbol definition if needed, but we drew directly in the closure
                    EmptyView().tag("liquidLayer")
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
