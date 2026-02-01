import Foundation
import SwiftUI
import Combine

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfile
    @Published var workouts: [Workout] = []
    @Published var groups: [FitnessGroup] = []
    @Published var challenges: [Challenge] = []
    @Published var personalRecords: PersonalRecords
    @Published var currentStreak: Int = 0
    @Published var todayPushups: Int = 0
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Keys
    private let profileKey = "userProfile"
    private let workoutsKey = "workouts"
    private let groupsKey = "groups"
    private let challengesKey = "challenges"
    private let recordsKey = "personalRecords"
    
    // MARK: - Initialization
    private init() {
        // Load user profile
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? decoder.decode(UserProfile.self, from: data) {
            self.userProfile = profile
        } else {
            self.userProfile = UserProfile()
        }
        
        // Load personal records
        if let data = userDefaults.data(forKey: recordsKey),
           let records = try? decoder.decode(PersonalRecords.self, from: data) {
            self.personalRecords = records
        } else {
            self.personalRecords = PersonalRecords()
        }
        
        loadWorkouts()
        loadGroups()
        loadChallenges()
        calculateCurrentStreak()
        calculateTodayPushups()
    }
    
    // MARK: - Profile Management
    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        saveProfile()
    }
    
    func updateDailyGoal(_ goal: Int) {
        userProfile.dailyGoal = goal
        saveProfile()
    }
    
    func updateDisplayName(_ name: String) {
        userProfile.displayName = name
        saveProfile()
    }
    
    func updateAvatar(_ emoji: String) {
        userProfile.avatarEmoji = emoji
        saveProfile()
    }
    
    private func saveProfile() {
        if let data = try? encoder.encode(userProfile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }
    
    // MARK: - Workout Management
    func saveWorkout(_ workout: Workout) {
        workouts.append(workout)
        
        // Update today's total
        todayPushups += workout.pushupCount
        
        // Update personal records
        personalRecords.updateWithWorkout(workout, dailyTotal: todayPushups, currentStreak: currentStreak)
        
        // Update streak
        calculateCurrentStreak()
        
        // Persist
        saveWorkouts()
        saveRecords()
        
        // Notify groups
        Task {
            await CloudKitManager.shared.syncWorkout(workout)
        }
    }
    
    func getWorkouts(for date: Date) -> [Workout] {
        let calendar = Calendar.current
        return workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getWorkouts(from startDate: Date, to endDate: Date) -> [Workout] {
        workouts.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    func getTotalPushups(for date: Date) -> Int {
        getWorkouts(for: date).reduce(0) { $0 + $1.pushupCount }
    }
    
    func getWeeklyPushups() -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return getWorkouts(from: startOfWeek, to: Date()).reduce(0) { $0 + $1.pushupCount }
    }
    
    func getMonthlyPushups() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return getWorkouts(from: startOfMonth, to: Date()).reduce(0) { $0 + $1.pushupCount }
    }
    
    func getWeeklyData() -> [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        var result: [(String, Int)] = []
        
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let count = getTotalPushups(for: date)
            result.append((dayName, count))
        }
        
        return result
    }
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: workoutsKey),
           let loaded = try? decoder.decode([Workout].self, from: data) {
            workouts = loaded
        }
    }
    
    private func saveWorkouts() {
        if let data = try? encoder.encode(workouts) {
            userDefaults.set(data, forKey: workoutsKey)
        }
    }
    
    private func saveRecords() {
        if let data = try? encoder.encode(personalRecords) {
            userDefaults.set(data, forKey: recordsKey)
        }
    }
    
    // MARK: - Streak Calculation
    private func calculateCurrentStreak() {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Check if today has workouts
        if getTotalPushups(for: checkDate) > 0 {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        // Count consecutive days backwards
        while true {
            if getTotalPushups(for: checkDate) > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        currentStreak = streak
    }
    
    private func calculateTodayPushups() {
        todayPushups = getTotalPushups(for: Date())
    }
    
    // MARK: - Group Management
    func createGroup(name: String, emoji: String, weeklyGoal: Int) -> FitnessGroup {
        let group = FitnessGroup(name: name, emoji: emoji, createdBy: userProfile.id, weeklyGoal: weeklyGoal)
        groups.append(group)
        saveGroups()
        
        Task {
            await CloudKitManager.shared.createGroup(group)
        }
        
        return group
    }
    
    func joinGroup(inviteCode: String) async throws -> FitnessGroup? {
        // Try to find group in CloudKit
        if let group = await CloudKitManager.shared.fetchGroup(byInviteCode: inviteCode) {
            var updatedGroup = group
            if !updatedGroup.memberIds.contains(userProfile.id) {
                updatedGroup.memberIds.append(userProfile.id)
            }
            groups.append(updatedGroup)
            saveGroups()
            return updatedGroup
        }
        return nil
    }
    
    func leaveGroup(_ groupId: UUID) {
        groups.removeAll { $0.id == groupId }
        saveGroups()
    }
    
    func getGroupMembers(_ group: FitnessGroup) -> [GroupMember] {
        // In production, this would fetch from CloudKit
        // For now, return mock data including current user
        var members: [GroupMember] = [
            GroupMember(userId: userProfile.id, displayName: userProfile.displayName, avatarEmoji: userProfile.avatarEmoji, weeklyPushups: getWeeklyPushups(), streak: currentStreak)
        ]
        
        // Add some mock members for demo
        if group.memberIds.count > 1 {
            members.append(contentsOf: [
                GroupMember(userId: UUID(), displayName: "Alex", avatarEmoji: "🔥", weeklyPushups: 324, streak: 12),
                GroupMember(userId: UUID(), displayName: "Jordan", avatarEmoji: "💪", weeklyPushups: 280, streak: 8),
                GroupMember(userId: UUID(), displayName: "Sam", avatarEmoji: "⚡", weeklyPushups: 156, streak: 3)
            ])
        }
        
        return members.sorted { $0.weeklyPushups > $1.weeklyPushups }
    }
    
    private func loadGroups() {
        if let data = userDefaults.data(forKey: groupsKey),
           let loaded = try? decoder.decode([FitnessGroup].self, from: data) {
            groups = loaded
        }
    }
    
    private func saveGroups() {
        if let data = try? encoder.encode(groups) {
            userDefaults.set(data, forKey: groupsKey)
        }
    }
    
    // MARK: - Challenge Management
    func createChallenge(name: String, description: String, targetPushups: Int, endDate: Date, groupId: UUID) -> Challenge {
        let challenge = Challenge(name: name, description: description, targetPushups: targetPushups, endDate: endDate, groupId: groupId)
        challenges.append(challenge)
        saveChallenges()
        return challenge
    }
    
    func joinChallenge(_ challengeId: UUID) {
        if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
            if !challenges[index].participants.contains(userProfile.id) {
                challenges[index].participants.append(userProfile.id)
                saveChallenges()
            }
        }
    }
    
    func getActiveChallenges() -> [Challenge] {
        challenges.filter { !$0.isCompleted && $0.endDate > Date() }
    }
    
    func getChallenges(for groupId: UUID) -> [Challenge] {
        challenges.filter { $0.groupId == groupId }
    }
    
    private func loadChallenges() {
        if let data = userDefaults.data(forKey: challengesKey),
           let loaded = try? decoder.decode([Challenge].self, from: data) {
            challenges = loaded
        }
    }
    
    private func saveChallenges() {
        if let data = try? encoder.encode(challenges) {
            userDefaults.set(data, forKey: challengesKey)
        }
    }
    
    // MARK: - Stats Helpers
    func getDailyGoalProgress() -> Double {
        guard userProfile.dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todayPushups) / Double(userProfile.dailyGoal))
    }
    
    func getAveragePerDay(days: Int = 7) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let total = getWorkouts(from: startDate, to: Date()).reduce(0) { $0 + $1.pushupCount }
        return total / max(1, days)
    }
    
    // MARK: - Data Reset
    func resetAllData() {
        workouts = []
        groups = []
        challenges = []
        personalRecords = PersonalRecords()
        currentStreak = 0
        todayPushups = 0
        
        userDefaults.removeObject(forKey: workoutsKey)
        userDefaults.removeObject(forKey: groupsKey)
        userDefaults.removeObject(forKey: challengesKey)
        userDefaults.removeObject(forKey: recordsKey)
    }
}
