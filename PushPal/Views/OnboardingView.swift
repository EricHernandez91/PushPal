import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var currentPage = 0
    @State private var displayName = ""
    @State private var selectedEmoji = "💪"
    @State private var dailyGoal = 50
    @State private var enableNotifications = false
    
    private let emojiOptions = ["💪", "🔥", "⚡", "🏆", "🚀", "🦾", "🏋️", "🥊", "🧘", "🏃"]
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                profilePage.tag(1)
                goalPage.tag(2)
                notificationPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Navigation
            VStack {
                Spacer()
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentOrange : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
                
                // Next button
                Button {
                    if currentPage < 3 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage == 3 ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon representation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentOrange, .accentOrange.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to PushPal")
                    .font(.largeTitle.weight(.bold))
                
                Text("Your personal pushup companion.\nTrack, compete, and get stronger together.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Profile Page
    private var profilePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Create Your Profile")
                .font(.title.weight(.bold))
            
            // Avatar
            Text(selectedEmoji)
                .font(.system(size: 72))
                .frame(width: 120, height: 120)
                .background(Color.accentOrange.opacity(0.2))
                .clipShape(Circle())
            
            // Emoji selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.title)
                                .padding(12)
                                .background(
                                    selectedEmoji == emoji
                                        ? Color.accentOrange.opacity(0.3)
                                        : Color.cardBackground
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedEmoji == emoji ? Color.accentOrange : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("Your name", text: $displayName)
                    .font(.title3)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Goal Page
    private var goalPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Set Your Daily Goal")
                .font(.title.weight(.bold))
            
            Text("How many pushups do you want to do each day?")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Goal display
            Text("\(dailyGoal)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentOrange)
            
            Text("pushups per day")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            // Slider
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { Double(dailyGoal) },
                    set: { dailyGoal = Int($0) }
                ), in: 10...200, step: 5)
                .tint(.accentOrange)
                
                HStack {
                    Text("10")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("200")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            .padding(.horizontal, 40)
            
            // Quick presets
            HStack(spacing: 12) {
                goalPresetButton(25, label: "Beginner")
                goalPresetButton(50, label: "Regular")
                goalPresetButton(100, label: "Pro")
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
    }
    
    private func goalPresetButton(_ goal: Int, label: String) -> some View {
        Button {
            dailyGoal = goal
        } label: {
            VStack(spacing: 4) {
                Text("\(goal)")
                    .font(.headline)
                Text(label)
                    .font(.caption)
            }
            .foregroundStyle(dailyGoal == goal ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(dailyGoal == goal ? Color.accentOrange : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Notification Page
    private var notificationPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Bell icon
            ZStack {
                Circle()
                    .fill(Color.accentBlue.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.accentBlue)
            }
            
            VStack(spacing: 16) {
                Text("Stay on Track")
                    .font(.title.weight(.bold))
                
                Text("Get daily reminders to keep your streak alive and notifications when your friends complete workouts.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Toggle
            Toggle(isOn: $enableNotifications) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.accentOrange)
                    Text("Enable Notifications")
                        .font(.headline)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentOrange))
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        // Save user profile
        var profile = UserProfile(
            displayName: displayName.isEmpty ? "Athlete" : displayName,
            avatarEmoji: selectedEmoji,
            dailyGoal: dailyGoal
        )
        profile.remindersEnabled = enableNotifications
        
        DataManager.shared.updateProfile(profile)
        
        // Request notifications if enabled
        if enableNotifications {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    // Schedule default reminder at 6 PM
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.hour, .minute], from: Date())
                    components.hour = 18
                    components.minute = 0
                    if let reminderTime = calendar.date(from: components) {
                        await notificationManager.scheduleDailyReminder(at: reminderTime)
                    }
                }
            }
        }
        
        // Complete onboarding
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(NotificationManager.shared)
        .preferredColorScheme(.dark)
}
