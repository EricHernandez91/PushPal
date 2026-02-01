import SwiftUI

struct ChallengeView: View {
    let groupId: UUID
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var challengeName = ""
    @State private var description = ""
    @State private var targetPushups = 1000
    @State private var duration: ChallengeDuration = .oneWeek
    
    enum ChallengeDuration: String, CaseIterable {
        case threeDays = "3 Days"
        case oneWeek = "1 Week"
        case twoWeeks = "2 Weeks"
        case oneMonth = "1 Month"
        
        var days: Int {
            switch self {
            case .threeDays: return 3
            case .oneWeek: return 7
            case .twoWeeks: return 14
            case .oneMonth: return 30
            }
        }
    }
    
    private let targetOptions = [250, 500, 1000, 2000, 5000, 10000]
    
    var body: some View {
        NavigationStack {
            Form {
                // Challenge name
                Section {
                    TextField("Challenge Name", text: $challengeName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your challenge a motivating name!")
                }
                
                // Description (optional)
                Section("Description (Optional)") {
                    TextField("What's this challenge about?", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                // Target pushups
                Section {
                    Picker("Target", selection: $targetPushups) {
                        ForEach(targetOptions, id: \.self) { target in
                            Text("\(target) pushups").tag(target)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Pushup Target")
                } footer: {
                    Text("The total pushups needed to complete this challenge.")
                }
                
                // Duration
                Section("Duration") {
                    Picker("Duration", selection: $duration) {
                        ForEach(ChallengeDuration.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Challenge summary
                Section("Challenge Summary") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(Color.accentOrange)
                            Text("\(targetPushups) pushups")
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.accentBlue)
                            Text("\(duration.rawValue)")
                        }
                        
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(Color.accentGreen)
                            Text("~\(targetPushups / duration.days) pushups/day")
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createChallenge()
                    }
                    .disabled(challengeName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createChallenge() {
        let trimmedName = challengeName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let endDate = Calendar.current.date(byAdding: .day, value: duration.days, to: Date())!
        
        _ = dataManager.createChallenge(
            name: trimmedName,
            description: description,
            targetPushups: targetPushups,
            endDate: endDate,
            groupId: groupId
        )
        
        dismiss()
    }
}

#Preview {
    ChallengeView(groupId: UUID())
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
