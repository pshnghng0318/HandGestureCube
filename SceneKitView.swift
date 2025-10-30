import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @Binding var cubeNode: SCNNode
    var scale: CGFloat
    var rotation: SCNVector3

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.scene?.rootNode.addChildNode(cubeNode)
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        cubeNode.scale = SCNVector3(Float(scale), Float(scale), Float(scale))
        cubeNode.eulerAngles = rotation
    }
}
