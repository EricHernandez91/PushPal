import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName = ""
    @State private var selectedEmoji = "🏋️"
    @State private var weeklyGoal = 500
    
    private let emojiOptions = ["🏋️", "💪", "🔥", "⚡", "🎯", "🏆", "🚀", "💯", "🦾", "🏃", "🧘", "🥊"]
    
    private let goalOptions = [100, 250, 500, 750, 1000, 1500, 2000]
    
    var body: some View {
        NavigationStack {
            Form {
                // Group name
                Section {
                    TextField("Group Name", text: $groupName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Choose a fun name for your group!")
                }
                
                // Emoji picker
                Section("Choose an Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title)
                                    .padding(8)
                                    .background(
                                        selectedEmoji == emoji
                                            ? Color.accentOrange.opacity(0.3)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedEmoji == emoji ? Color.accentOrange : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Weekly goal
                Section {
                    Picker("Weekly Goal", selection: $weeklyGoal) {
                        ForEach(goalOptions, id: \.self) { goal in
                            Text("\(goal) pushups").tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Team Weekly Goal")
                } footer: {
                    Text("This is the combined goal for all group members each week.")
                }
                
                // Preview
                Section("Preview") {
                    HStack(spacing: 16) {
                        Text(selectedEmoji)
                            .font(.system(size: 36))
                            .frame(width: 60, height: 60)
                            .background(Color.accentOrange.opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(groupName.isEmpty ? "Group Name" : groupName)
                                .font(.headline)
                                .foregroundStyle(groupName.isEmpty ? .secondary : .primary)
                            
                            Text("1 member • \(weeklyGoal) weekly goal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        _ = dataManager.createGroup(name: trimmedName, emoji: selectedEmoji, weeklyGoal: weeklyGoal)
        dismiss()
    }
}

#Preview {
    CreateGroupView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
