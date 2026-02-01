import Foundation
import Combine
import UIKit

@MainActor
class WorkoutSession: ObservableObject {
    @Published var isActive = false
    @Published var isPaused = false
    @Published var pushupCount = 0
    @Published var currentPhase: PushupPhase = .unknown
    @Published var formScore: Double = 0.0
    @Published var elapsedTime: TimeInterval = 0
    @Published var calories: Double = 0
    @Published var showCompletionScreen = false
    
    private var startTime: Date?
    private var timer: Timer?
    private var formScores: [Double] = []
    
    // Calorie calculation constants
    private let caloriesPerPushup: Double = 0.32 // Average for moderate intensity
    
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var averageFormScore: Double {
        guard !formScores.isEmpty else { return 0 }
        return formScores.reduce(0, +) / Double(formScores.count)
    }
    
    var formFeedback: String {
        switch formScore {
        case 0.9...1.0: return "Perfect Form! 🔥"
        case 0.7..<0.9: return "Good Form 👍"
        case 0.5..<0.7: return "Keep Your Back Straight"
        case 0.3..<0.5: return "Go Lower"
        default: return "Adjust Position"
        }
    }
    
    var formColor: String {
        switch formScore {
        case 0.8...1.0: return "green"
        case 0.5..<0.8: return "yellow"
        default: return "red"
        }
    }
    
    func start() {
        isActive = true
        isPaused = false
        pushupCount = 0
        elapsedTime = 0
        calories = 0
        formScores = []
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                if let start = self.startTime {
                    self.elapsedTime = Date().timeIntervalSince(start)
                }
            }
        }
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
        if let elapsed = startTime?.timeIntervalSinceNow {
            startTime = Date().addingTimeInterval(elapsed)
        }
    }
    
    func stop() -> Workout {
        isActive = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        let workout = Workout(
            date: Date(),
            pushupCount: pushupCount,
            duration: elapsedTime,
            averageFormScore: averageFormScore,
            caloriesBurned: calories
        )
        
        showCompletionScreen = true
        return workout
    }
    
    func recordPushup(formScore: Double) {
        pushupCount += 1
        self.formScore = formScore
        formScores.append(formScore)
        calories = Double(pushupCount) * caloriesPerPushup
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func updatePhase(_ phase: PushupPhase) {
        if currentPhase != phase {
            currentPhase = phase
        }
    }
    
    func updateFormScore(_ score: Double) {
        formScore = score
    }
    
    func reset() {
        isActive = false
        isPaused = false
        pushupCount = 0
        currentPhase = .unknown
        formScore = 0
        elapsedTime = 0
        calories = 0
        formScores = []
        showCompletionScreen = false
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
}
