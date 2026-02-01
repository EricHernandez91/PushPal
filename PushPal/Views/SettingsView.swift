import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var displayName: String = ""
    @State private var selectedEmoji = "💪"
    @State private var dailyGoal = 50
    @State private var remindersEnabled = false
    @State private var reminderTime = Date()
    @State private var showResetConfirmation = false
    
    private let emojiOptions = ["💪", "🔥", "⚡", "🏆", "🚀", "🦾", "🏋️", "🥊", "🧘", "🏃"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile section
                Section("Profile") {
                    HStack {
                        Text(selectedEmoji)
                            .font(.system(size: 48))
                            .frame(width: 70, height: 70)
                            .background(Color.accentOrange.opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Display Name", text: $displayName)
                                .font(.headline)
                            Text("Member since \(dataManager.userProfile.joinDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Emoji picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                    dataManager.updateAvatar(emoji)
                                } label: {
                                    Text(emoji)
                                        .font(.title)
                                        .padding(8)
                                        .background(
                                            selectedEmoji == emoji
                                                ? Color.accentOrange.opacity(0.3)
                                                : Color.cardBackground
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                
                // Goals section
                Section {
                    Stepper(value: $dailyGoal, in: 10...500, step: 10) {
                        HStack {
                            Text("Daily Goal")
                            Spacer()
                            Text("\(dailyGoal)")
                                .foregroundStyle(.accentOrange)
                                .fontWeight(.semibold)
                        }
                    }
                    .onChange(of: dailyGoal) { _, newValue in
                        dataManager.updateDailyGoal(newValue)
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Your daily pushup target. Adjust to match your fitness level.")
                }
                
                // Notifications section
                Section {
                    Toggle("Daily Reminders", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { _, enabled in
                            Task {
                                if enabled {
                                    let granted = await notificationManager.requestAuthorization()
                                    if granted {
                                        await notificationManager.scheduleDailyReminder(at: reminderTime)
                                    } else {
                                        remindersEnabled = false
                                    }
                                } else {
                                    await notificationManager.cancelDailyReminders()
                                }
                            }
                        }
                    
                    if remindersEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newTime in
                                Task {
                                    await notificationManager.scheduleDailyReminder(at: newTime)
                                }
                            }
                    }
                } header: {
                    Text("Notifications")
                }
                
                // About section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://pushpal.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://pushpal.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Data section
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset All Data")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("This will delete all your workout history, groups, and personal records. This action cannot be undone.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
            .onChange(of: displayName) { _, newValue in
                dataManager.updateDisplayName(newValue)
            }
            .confirmationDialog("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Reset All Data", role: .destructive) {
                    dataManager.resetAllData()
                    loadSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your workout history, groups, and achievements.")
            }
        }
    }
    
    private func loadSettings() {
        displayName = dataManager.userProfile.displayName
        selectedEmoji = dataManager.userProfile.avatarEmoji
        dailyGoal = dataManager.userProfile.dailyGoal
        remindersEnabled = dataManager.userProfile.remindersEnabled
        if let time = dataManager.userProfile.reminderTime {
            reminderTime = time
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
        .environmentObject(NotificationManager.shared)
        .preferredColorScheme(.dark)
}
