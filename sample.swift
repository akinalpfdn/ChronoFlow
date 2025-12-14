//
// A 30-minute hack to recreate the "iBeer" effect using SpriteKit, SwiftUI, and metaballs.
// The effect is created by having hundreds of physics-enabled balls in a SpriteKit scene,
// all drawing nothing. These balls are then read back out by SwiftUI in a TimelineView, and
// drawn using blur and alpha threshold filters to make them appear to be a liquid.
// The SpriteKit scene then has its gravity changed dynamically using the accelerometer,
// meaning that the "liquid" splashes around as you tilt your phone.
//
// Created by Paul Hudson
// https://www.hackingwithswift.com/license
//

import CoreMotion
import SpriteKit
import SwiftUI

@main
struct MetaphysicsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// The SwiftUI view that creates and manages a physics scene using SpriteKit, 
/// converting it into SwiftUI views to get the liquid effect.
struct ContentView: View {
    /// The game scene containing all the physics balls.
    @State private var scene = GameScene()

    /// Tracks whether the blob effect is enabled or not.
    @State private var isBlurred = true

    var body: some View {
        ZStack {
            // A placeholder SpriteKit view that fills all the screen. This isn't drawn – everything is clear –
            // but it lets us read physics accurately.
            GeometryReader { proxy in
                SpriteView(scene: scene)
                    .onAppear {
                        scene.size = proxy.size
                    }
            }

            // All the drawing happens here, inside a mask to create a nice color gradient.
            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom).mask {
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        // Touch the timeline date, so it updates correctly.
                        _ = timeline.date

                        // This applies the "blob" effect, making the balls look like
                        // liquid rather than a bunch of balls.
                        if isBlurred {
                            ctx.addFilter(.alphaThreshold(min: 0.5, color: .white))
                            ctx.addFilter(.blur(radius: 32))
                        }

                        // Do all our drawing in a sublayer so the metaball
                        // effect is applied.
                        ctx.drawLayer { ctx in
                            for node in scene.nodes {
                                let frame = CGRect(x: node.position.x - GameScene.circleRadius, y: size.height - node.position.y - GameScene.circleRadius, width: GameScene.circleRadius * 2, height: GameScene.circleRadius * 2)

                                // We draw white circles, but there's a LinearGradient
                                // mask that applies color.
                                ctx.fill(Circle().path(in: frame), with: .color(.white))
                            }
                        }
                    }
                }
            }
            .onTapGesture {
                isBlurred.toggle()
            }
        }
    }
}

/// The SpriteKit scene responsible for physics calculations.
class GameScene: SKScene {
    /// A single place to track the circle size.
    static let circleRadius = 8.0

    /// Delivers all accelerometer updates to us.
    var motionManager: CMMotionManager?

    /// An array of all the balls, so we can read them externally.
    var nodes = [SKNode]()

    /// Creates  a frame that goes offscreen at the top, so the balls appear to disappear out of the device.
    override func didMove(to view: SKView) {
        let newFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 1000)
        physicsBody = SKPhysicsBody(edgeLoopFrom: newFrame)

        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()

        // 800 balls is probably too many by about 30%, but it looks nice!
        for _ in 1...800 {
            createNode(at: CGPoint(x: Double.random(in: 0..<frame.width), y: Double.random(in: 0..<frame.height)))
        }
    }

    /// Creates a single ball with no friction and no bounciness.
    func createNode(at point: CGPoint) {
        let box = SKNode()
        box.position = point
        box.physicsBody = SKPhysicsBody(circleOfRadius: Self.circleRadius)
        box.physicsBody?.friction = 0
        box.physicsBody?.restitution = 0
        addChild(box)
        nodes.append(box)
    }

    /// Updates the scene's gravity so tilting the phone makes the "liquid" move.
    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 50, dy: accelerometerData.acceleration.y * 50)
        }
    }
}