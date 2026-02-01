import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // No updates needed
    }
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            previewLayer.session = session
        }
    }
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        layer.addSublayer(previewLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - Pose Skeleton Overlay (Optional visual debugging)
struct PoseSkeletonView: View {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let size: CGSize
    
    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.neck, .root)
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            // Draw connections
            for (joint1, joint2) in connections {
                if let point1 = joints[joint1], let point2 = joints[joint2] {
                    let scaledPoint1 = scalePoint(point1, to: canvasSize)
                    let scaledPoint2 = scalePoint(point2, to: canvasSize)
                    
                    var path = Path()
                    path.move(to: scaledPoint1)
                    path.addLine(to: scaledPoint2)
                    
                    context.stroke(path, with: .color(.accentOrange), lineWidth: 3)
                }
            }
            
            // Draw joints
            for (_, point) in joints {
                let scaledPoint = scalePoint(point, to: canvasSize)
                let rect = CGRect(x: scaledPoint.x - 6, y: scaledPoint.y - 6, width: 12, height: 12)
                context.fill(Circle().path(in: rect), with: .color(.accentOrange))
            }
        }
    }
    
    private func scalePoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

import Vision
