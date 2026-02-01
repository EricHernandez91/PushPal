import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var poseService = PoseDetectionService()
    @StateObject private var session = WorkoutSession()
    @EnvironmentObject var dataManager: DataManager
    
    @State private var showingPermissionAlert = false
    @State private var cameraReady = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                if cameraReady {
                    // Camera preview
                    CameraPreviewView(session: poseService.captureSession)
                        .ignoresSafeArea()
                        .overlay(alignment: .top) {
                            poseOverlay
                        }
                    
                    // Controls overlay
                    VStack {
                        Spacer()
                        controlsView
                    }
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    loadingView
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if session.isActive {
                        Text(session.formattedTime)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.accentOrange)
                    }
                }
            }
            .sheet(isPresented: $session.showCompletionScreen) {
                if let lastWorkout = dataManager.workouts.last {
                    WorkoutCompleteView(workout: lastWorkout)
                        .environmentObject(dataManager)
                }
            }
        }
        .task {
            await setupCamera()
        }
        .onDisappear {
            poseService.stopCamera()
            poseService.stopDetection()
        }
    }
    
    // MARK: - Pose Overlay
    private var poseOverlay: some View {
        VStack(spacing: 8) {
            // Status bar
            HStack {
                // Form indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(formColor)
                        .frame(width: 12, height: 12)
                    Text(poseService.bodyDetected ? session.formFeedback : "Position yourself")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                Spacer()
                
                // Phase indicator
                if session.isActive {
                    Text(poseService.currentPhase.description)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            
            Spacer()
        }
    }
    
    private var formColor: Color {
        guard poseService.bodyDetected else { return .gray }
        switch session.formScore {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .yellow
        default: return .red
        }
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        VStack(spacing: 24) {
            // Count display
            if session.isActive {
                VStack(spacing: 4) {
                    Text("\(session.pushupCount)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: session.pushupCount)
                    
                    Text("pushups")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
            }
            
            // Stats row
            if session.isActive {
                HStack(spacing: 40) {
                    statItem(value: String(format: "%.0f", session.calories), label: "cal")
                    statItem(value: String(format: "%.0f%%", session.formScore * 100), label: "form")
                    statItem(value: session.formattedTime, label: "time")
                }
                .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                if session.isActive {
                    // Stop button
                    Button {
                        stopWorkout()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    // Pause/Resume button
                    Button {
                        if session.isPaused {
                            session.resume()
                            poseService.startDetection()
                        } else {
                            session.pause()
                            poseService.stopDetection()
                        }
                    } label: {
                        Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.accentOrange)
                            .clipShape(Circle())
                    }
                } else {
                    // Start button
                    Button {
                        startWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.accentOrange, .accentOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 40)
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - State Views
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentOrange)
            Text("Setting up camera...")
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentOrange)
        }
        .padding()
    }
    
    // MARK: - Actions
    private func setupCamera() async {
        do {
            try await poseService.setupCamera()
            poseService.startCamera()
            
            // Connect pose detection to workout session
            poseService.onPushupCompleted = { formScore in
                Task { @MainActor in
                    if session.isActive && !session.isPaused {
                        session.recordPushup(formScore: formScore)
                    }
                }
            }
            
            cameraReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func startWorkout() {
        session.start()
        poseService.startDetection()
    }
    
    private func stopWorkout() {
        poseService.stopDetection()
        let workout = session.stop()
        dataManager.saveWorkout(workout)
    }
}

// MARK: - Preview
#Preview {
    CameraView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
