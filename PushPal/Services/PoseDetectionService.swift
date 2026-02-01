import Foundation
import AVFoundation
import Vision
import Combine
import UIKit

@MainActor
class PoseDetectionService: NSObject, ObservableObject {
    // Published state
    @Published var isDetecting = false
    @Published var currentPhase: PushupPhase = .unknown
    @Published var formScore: Double = 0.0
    @Published var bodyDetected = false
    @Published var jointPositions: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var debugMessage: String = ""
    
    // Camera session
    let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoQueue = DispatchQueue(label: "com.pushpal.videoqueue", qos: .userInteractive)
    
    // Vision
    nonisolated(unsafe) private var bodyPoseRequest: VNDetectHumanBodyPoseRequest?

    // Pushup detection state
    private var lastShoulderHeight: CGFloat?
    private var pushupThresholdUp: CGFloat = 0.6
    private var pushupThresholdDown: CGFloat = 0.4
    private var isInDownPosition = false
    nonisolated(unsafe) private var frameCount = 0
    private var stablePhaseCount = 0
    private let requiredStableFrames = 3
    
    // Callback for rep counting
    var onPushupCompleted: ((Double) -> Void)?
    
    // Form analysis constants
    private let idealElbowAngleUp: CGFloat = 160 // Near straight
    private let idealElbowAngleDown: CGFloat = 90 // 90 degrees at bottom
    
    override init() {
        super.init()
        setupVision()
    }
    
    // MARK: - Setup
    
    private func setupVision() {
        bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    }
    
    func setupCamera() async throws {
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            throw CameraError.accessDenied
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Find front camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraError.cameraUnavailable
        }
        
        // Configure camera for optimal performance
        try camera.lockForConfiguration()
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
        }
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
        }
        camera.unlockForConfiguration()
        
        // Add input
        let input = try AVCaptureDeviceInput(device: camera)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Add output
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            videoOutput = output
            
            // Configure connection
            if let connection = output.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = true
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    func startCamera() {
        videoQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func stopCamera() {
        videoQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func startDetection() {
        isDetecting = true
        resetState()
    }
    
    func stopDetection() {
        isDetecting = false
    }
    
    func resetState() {
        lastShoulderHeight = nil
        isInDownPosition = false
        currentPhase = .unknown
        formScore = 0
        stablePhaseCount = 0
    }
    
    // MARK: - Pose Analysis
    
    nonisolated private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let request = bodyPoseRequest else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
            
            if let observation = request.results?.first {
                Task { @MainActor in
                    self.analyzePose(observation)
                }
            } else {
                Task { @MainActor in
                    self.bodyDetected = false
                    self.debugMessage = "No body detected"
                }
            }
        } catch {
            Task { @MainActor in
                self.debugMessage = "Vision error: \(error.localizedDescription)"
            }
        }
    }
    
    private func analyzePose(_ observation: VNHumanBodyPoseObservation) {
        bodyDetected = true
        
        // Extract key points
        guard let points = try? extractKeyPoints(from: observation) else {
            debugMessage = "Could not extract key points"
            return
        }
        
        // Update joint positions for visualization
        jointPositions = points
        
        // Calculate shoulder height relative to hip (normalized)
        guard let leftShoulder = points[.leftShoulder],
              let rightShoulder = points[.rightShoulder],
              let leftHip = points[.leftHip],
              let rightHip = points[.rightHip] else {
            debugMessage = "Missing key body parts"
            return
        }
        
        let avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2
        let avgHipY = (leftHip.y + rightHip.y) / 2
        
        // In Vision coordinates, y increases downward
        // When doing pushups, shoulders move down (y increases) relative to hips
        let relativeShoulderHeight = avgShoulderY - avgHipY
        
        // Calculate form score
        let newFormScore = calculateFormScore(points: points)
        formScore = formScore * 0.7 + newFormScore * 0.3 // Smooth the score
        
        // Detect pushup phase
        detectPushupPhase(shoulderHeight: relativeShoulderHeight, points: points)
        
        debugMessage = String(format: "Shoulder: %.2f, Phase: %@", relativeShoulderHeight, currentPhase.description)
    }
    
    private func extractKeyPoints(from observation: VNHumanBodyPoseObservation) throws -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .root
        ]
        
        for joint in jointNames {
            if let point = try? observation.recognizedPoint(joint), point.confidence > 0.3 {
                points[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y) // Flip Y
            }
        }
        
        return points
    }
    
    private func detectPushupPhase(shoulderHeight: CGFloat, points: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let lastHeight = lastShoulderHeight else {
            lastShoulderHeight = shoulderHeight
            return
        }
        
        let movement = shoulderHeight - lastHeight
        let movementThreshold: CGFloat = 0.005
        
        var newPhase = currentPhase
        
        // Analyze elbow angle for phase detection
        let elbowAngle = calculateElbowAngle(points: points)
        
        if elbowAngle > 140 { // Arms nearly straight = up position
            if currentPhase == .goingUp && isInDownPosition {
                // Completed a rep!
                isInDownPosition = false
                stablePhaseCount = 0
                onPushupCompleted?(formScore)
            }
            newPhase = .up
        } else if elbowAngle < 110 { // Arms bent = down position
            newPhase = .down
            isInDownPosition = true
        } else if movement > movementThreshold {
            newPhase = .goingDown
        } else if movement < -movementThreshold {
            newPhase = .goingUp
        }
        
        // Only update phase after stable detection
        if newPhase == currentPhase {
            stablePhaseCount += 1
        } else {
            stablePhaseCount = 0
        }
        
        if stablePhaseCount >= requiredStableFrames || newPhase != currentPhase {
            currentPhase = newPhase
        }
        
        lastShoulderHeight = shoulderHeight
    }
    
    private func calculateElbowAngle(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> CGFloat {
        // Calculate average elbow angle
        var totalAngle: CGFloat = 0
        var count: CGFloat = 0
        
        if let shoulder = points[.leftShoulder],
           let elbow = points[.leftElbow],
           let wrist = points[.leftWrist] {
            totalAngle += angleBetweenPoints(shoulder, elbow, wrist)
            count += 1
        }
        
        if let shoulder = points[.rightShoulder],
           let elbow = points[.rightElbow],
           let wrist = points[.rightWrist] {
            totalAngle += angleBetweenPoints(shoulder, elbow, wrist)
            count += 1
        }
        
        return count > 0 ? totalAngle / count : 180
    }
    
    private func angleBetweenPoints(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        
        let dot = ab.dx * cb.dx + ab.dy * cb.dy
        let magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy)
        let magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy)
        
        guard magAB > 0, magCB > 0 else { return 180 }
        
        let cosAngle = dot / (magAB * magCB)
        let clampedCos = max(-1, min(1, cosAngle))
        return acos(clampedCos) * 180 / .pi
    }
    
    private func calculateFormScore(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> Double {
        var score: Double = 1.0
        
        // Check body alignment (shoulders, hips should be roughly level)
        if let leftShoulder = points[.leftShoulder],
           let rightShoulder = points[.rightShoulder] {
            let shoulderDiff = abs(leftShoulder.y - rightShoulder.y)
            score -= min(0.3, Double(shoulderDiff) * 2)
        }
        
        if let leftHip = points[.leftHip],
           let rightHip = points[.rightHip] {
            let hipDiff = abs(leftHip.y - rightHip.y)
            score -= min(0.2, Double(hipDiff) * 2)
        }
        
        // Check for straight back (shoulder-hip-ankle alignment)
        if let shoulder = points[.leftShoulder] ?? points[.rightShoulder],
           let hip = points[.leftHip] ?? points[.rightHip],
           let neck = points[.neck] {
            // Check if body forms a relatively straight line
            let expectedY = (shoulder.y + hip.y) / 2
            let deviation = abs(neck.y - expectedY)
            score -= min(0.3, Double(deviation) * 3)
        }
        
        return max(0, min(1, score))
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PoseDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1
        
        // Process every 2nd frame for performance
        guard frameCount % 2 == 0 else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Only process if we're detecting
        Task { @MainActor in
            guard self.isDetecting else { return }
        }
        
        processFrame(pixelBuffer)
    }
}

// MARK: - Errors
enum CameraError: LocalizedError {
    case accessDenied
    case cameraUnavailable
    case configurationFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Camera access was denied. Please enable camera access in Settings."
        case .cameraUnavailable:
            return "No suitable camera found on this device."
        case .configurationFailed:
            return "Failed to configure camera session."
        }
    }
}
