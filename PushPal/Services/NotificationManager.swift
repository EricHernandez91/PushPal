import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Daily Reminder
    
    func scheduleDailyReminder(at time: Date) async {
        // Remove existing daily reminders
        await cancelDailyReminders()
        
        let content = UNMutableNotificationContent()
        content.title = "Time for Pushups! 💪"
        content.body = getRandomMotivationalMessage()
        content.sound = .default
        content.badge = 1
        
        // Create time-based trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("Daily reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }
    
    func cancelDailyReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }
    
    // MARK: - Streak Notifications
    
    func sendStreakAtRiskNotification() async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak! 🔥"
        content.body = "You haven't done any pushups today. Quick set to keep it going?"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "streak-risk-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Group Notifications
    
    func sendGroupActivityNotification(memberName: String, pushupCount: Int, groupName: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(groupName) Activity"
        content.body = "\(memberName) just did \(pushupCount) pushups! 💪"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "group-activity-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await center.add(request)
    }
    
    func sendChallengeNotification(challengeName: String, message: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Challenge: \(challengeName)"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "challenge-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Celebration Notifications
    
    func sendPersonalRecordNotification(recordType: String, value: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Personal Record! 🏆"
        content.body = "You set a new \(recordType) record: \(value)!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "pr-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Helpers
    
    private func getRandomMotivationalMessage() -> String {
        let messages = [
            "Start strong, finish stronger! Your pushups await.",
            "Every rep counts. Let's crush it today!",
            "Your body can do it. It's time to convince your mind.",
            "No excuses, just results. Let's go!",
            "Champions train when others rest. Time to train!",
            "Small steps, big gains. Drop and give me 20!",
            "The only bad workout is the one you didn't do.",
            "Your future self will thank you. Start now!"
        ]
        return messages.randomElement() ?? messages[0]
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    func getPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        await MainActor.run {
            pendingNotifications = requests
        }
    }
}
