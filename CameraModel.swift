import SwiftUI
import AVFoundation
import Vision

class CameraModel: NSObject, ObservableObject {
    @Published var handPoints: [CGPoint] = []
    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "cameraQueue")

    func startSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            session.addInput(input)
        } catch {
            print("Cannot access camera")
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: queue)
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            // connection.videoOrientation = .portrait
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90  // portrait 模式
            }
            connection.isVideoMirrored = true
        }

        session.startRunning()
    }
}

extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .upMirrored,
                                            options: [:])
        try? handler.perform([request])

        guard let observation = request.results?.first else { return }

        let joints: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]

        var points: [CGPoint] = []
        for joint in joints {
            if let point = try? observation.recognizedPoint(joint), point.confidence > 0.3 {
                points.append(point.location)
            }
        }

        DispatchQueue.main.async {
            self.handPoints = points
        }
    }
}
