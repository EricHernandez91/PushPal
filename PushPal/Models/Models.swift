import Foundation
import SwiftUI

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var avatarEmoji: String
    var joinDate: Date
    var dailyGoal: Int
    var reminderTime: Date?
    var remindersEnabled: Bool
    
    init(id: UUID = UUID(), displayName: String = "Athlete", avatarEmoji: String = "💪", dailyGoal: Int = 50, reminderTime: Date? = nil, remindersEnabled: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.joinDate = Date()
        self.dailyGoal = dailyGoal
        self.reminderTime = reminderTime
        self.remindersEnabled = remindersEnabled
    }
}

// MARK: - Workout
struct Workout: Codable, Identifiable {
    let id: UUID
    let date: Date
    var pushupCount: Int
    var duration: TimeInterval
    var averageFormScore: Double
    var caloriesBurned: Double
    
    init(id: UUID = UUID(), date: Date = Date(), pushupCount: Int = 0, duration: TimeInterval = 0, averageFormScore: Double = 0, caloriesBurned: Double = 0) {
        self.id = id
        self.date = date
        self.pushupCount = pushupCount
        self.duration = duration
        self.averageFormScore = averageFormScore
        self.caloriesBurned = caloriesBurned
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Group
struct FitnessGroup: Codable, Identifiable {
    let id: UUID
    var name: String
    var emoji: String
    var inviteCode: String
    var createdBy: UUID
    var createdAt: Date
    var memberIds: [UUID]
    var weeklyGoal: Int
    var isActive: Bool
    
    init(id: UUID = UUID(), name: String, emoji: String = "🏋️", createdBy: UUID, weeklyGoal: Int = 500) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.inviteCode = Self.generateInviteCode()
        self.createdBy = createdBy
        self.createdAt = Date()
        self.memberIds = [createdBy]
        self.weeklyGoal = weeklyGoal
        self.isActive = true
    }
    
    static func generateInviteCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// MARK: - Group Member
struct GroupMember: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var displayName: String
    var avatarEmoji: String
    var weeklyPushups: Int
    var lastWorkoutDate: Date?
    var streak: Int
    
    init(id: UUID = UUID(), userId: UUID, displayName: String, avatarEmoji: String = "💪", weeklyPushups: Int = 0, streak: Int = 0) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.weeklyPushups = weeklyPushups
        self.lastWorkoutDate = nil
        self.streak = streak
    }
}

// MARK: - Challenge
struct Challenge: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var targetPushups: Int
    var startDate: Date
    var endDate: Date
    var groupId: UUID
    var participants: [UUID]
    var isCompleted: Bool
    
    init(id: UUID = UUID(), name: String, description: String = "", targetPushups: Int, startDate: Date = Date(), endDate: Date, groupId: UUID) {
        self.id = id
        self.name = name
        self.description = description
        self.targetPushups = targetPushups
        self.startDate = startDate
        self.endDate = endDate
        self.groupId = groupId
        self.participants = []
        self.isCompleted = false
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let remaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, remaining)
    }
    
    var progress: Double {
        // This would be calculated based on participant progress
        return 0.0
    }
}

// MARK: - Stats
struct DailyStats: Codable, Identifiable {
    let id: UUID
    let date: Date
    var totalPushups: Int
    var workoutCount: Int
    var totalDuration: TimeInterval
    var averageFormScore: Double
    
    init(id: UUID = UUID(), date: Date = Date(), totalPushups: Int = 0, workoutCount: Int = 0, totalDuration: TimeInterval = 0, averageFormScore: Double = 0) {
        self.id = id
        self.date = date
        self.totalPushups = totalPushups
        self.workoutCount = workoutCount
        self.totalDuration = totalDuration
        self.averageFormScore = averageFormScore
    }
}

// MARK: - Personal Records
struct PersonalRecords: Codable {
    var maxInOneSet: Int
    var maxInOneDay: Int
    var longestStreak: Int
    var totalAllTime: Int
    var bestFormScore: Double
    
    init() {
        self.maxInOneSet = 0
        self.maxInOneDay = 0
        self.longestStreak = 0
        self.totalAllTime = 0
        self.bestFormScore = 0
    }
    
    mutating func updateWithWorkout(_ workout: Workout, dailyTotal: Int, currentStreak: Int) {
        if workout.pushupCount > maxInOneSet {
            maxInOneSet = workout.pushupCount
        }
        if dailyTotal > maxInOneDay {
            maxInOneDay = dailyTotal
        }
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        totalAllTime += workout.pushupCount
        if workout.averageFormScore > bestFormScore {
            bestFormScore = workout.averageFormScore
        }
    }
}

// MARK: - Pose State
enum PushupPhase {
    case unknown
    case up
    case goingDown
    case down
    case goingUp
    
    var description: String {
        switch self {
        case .unknown: return "Get Ready"
        case .up: return "Arms Extended"
        case .goingDown: return "Going Down..."
        case .down: return "At Bottom"
        case .goingUp: return "Push Up!"
        }
    }
}
