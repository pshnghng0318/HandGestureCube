import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject private var cameraModel = CameraModel()
    @State private var cubeNode = SCNNode()
    @State private var scale: CGFloat = 1.0
    @State private var rotation = SCNVector3Zero

    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()

            SceneKitView(cubeNode: $cubeNode, scale: scale, rotation: rotation)
                .edgesIgnoringSafeArea(.all)

            Canvas { context, size in
                for point in cameraModel.handPoints {
                    let x = (1 - point.x) * size.width
                    let y = (1 - point.y) * size.height
                    let circle = Path(ellipseIn: CGRect(x: x-5, y: y-5, width: 10, height: 10))
                    context.fill(circle, with: .color(.purple.opacity(0.5)))
                }
            }
        }
        .onAppear {
            cameraModel.startSession()
            setupCube()
        }
        .onChange(of: cameraModel.handPoints) { points in
            updateCube(from: points)
        }
    }

    func setupCube() {
        let cube = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.purple
        cube.materials = [material]
        cubeNode.geometry = cube
        cubeNode.position = SCNVector3(0,0,0)
    }

    func updateCube(from points: [CGPoint]) {
        guard !points.isEmpty else { return }

        // --- 計算手部中心 ---
        let flippedXPoints = points.map { 1 - $0.x }
        let centerX = flippedXPoints.reduce(0, +) / CGFloat(points.count)
        let centerY = points.map { 1 - $0.y }.reduce(0, +) / CGFloat(points.count)

        // --- 計算手部面積 (bounding box) ---
        let minX = flippedXPoints.min() ?? 0
        let maxX = flippedXPoints.max() ?? 0
        let minY = points.map { 1 - $0.y }.min() ?? 0
        let maxY = points.map { 1 - $0.y }.max() ?? 0
        let handWidth = maxX - minX
        let handHeight = maxY - minY
        let handArea = handWidth * handHeight

        // --- 計算 Cube scale ---
        let minScale: CGFloat = 0.2
        let maxScale: CGFloat = min(1.0, handArea * 2.0) // 不超過手掌面積大小
        let newScale = max(minScale, min(maxScale, handArea * 2.0))
        scale = newScale

        // --- 計算 Cube rotation ---
        let rotX = Float((centerY - 0.5) * CGFloat.pi) // CGFloat -> Float
        let rotY = Float((centerX - 0.5) * CGFloat.pi)
        let rotZ: Float = Float.pi / 2 // 前鏡頭修正
        rotation = SCNVector3(-rotY, rotX, -rotZ)

        // --- 更新 Cube 節點 ---
        cubeNode.scale = SCNVector3(Float(scale), Float(scale), Float(scale))
        cubeNode.eulerAngles = rotation
    }
}
