import SwiftUI

struct GroupDetailView: View {
    let group: FitnessGroup
    @EnvironmentObject var dataManager: DataManager
    @State private var showShareSheet = false
    @State private var showCreateChallenge = false
    @State private var showLeaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var members: [GroupMember] {
        dataManager.getGroupMembers(group)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Invite code
                inviteCodeSection
                
                // Weekly goal progress
                weeklyGoalSection
                
                // Leaderboard
                leaderboardSection
                
                // Active challenges
                challengesSection
                
                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color.background)
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share Invite", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showCreateChallenge = true
                    } label: {
                        Label("Create Challenge", systemImage: "flag.fill")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showCreateChallenge) {
            ChallengeView(groupId: group.id)
                .environmentObject(dataManager)
        }
        .confirmationDialog("Leave Group?", isPresented: $showLeaveConfirmation) {
            Button("Leave Group", role: .destructive) {
                dataManager.leaveGroup(group.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to leave \(group.name)?")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Join my PushPal group! Code: \(group.inviteCode)"])
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(group.emoji)
                .font(.system(size: 64))
            
            Text("\(group.memberIds.count) members")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Invite Code
    private var inviteCodeSection: some View {
        VStack(spacing: 8) {
            Text("Invite Code")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Text(group.inviteCode)
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.bold)
                    .tracking(4)
                
                Button {
                    UIPasteboard.general.string = group.inviteCode
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color.accentOrange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Weekly Goal
    private var weeklyGoalSection: some View {
        let totalPushups = members.reduce(0) { $0 + $1.weeklyPushups }
        let progress = min(1.0, Double(totalPushups) / Double(group.weeklyGoal))
        
        return VStack(spacing: 16) {
            HStack {
                Text("Weekly Team Goal")
                    .font(.headline)
                Spacer()
                Text("\(totalPushups)/\(group.weeklyGoal)")
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.accentOrange, .accentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 16)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Leaderboard
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Leaderboard")
                    .font(.headline)
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
            }
            
            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                leaderboardRow(rank: index + 1, member: member)
                
                if index < members.count - 1 {
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func leaderboardRow(rank: Int, member: GroupMember) -> some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor(rank))
                        .frame(width: 28, height: 28)
                }
                Text("\(rank)")
                    .font(.headline)
                    .foregroundStyle(rank <= 3 ? .black : .white)
            }
            .frame(width: 32)
            
            // Avatar
            Text(member.avatarEmoji)
                .font(.title2)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.displayName)
                        .font(.headline)
                    if member.userId == dataManager.userProfile.id {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(Color.accentOrange)
                    }
                }
                
                if member.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(member.streak) day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Pushup count
            Text("\(member.weeklyPushups)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.accentOrange)
        }
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .clear
        }
    }
    
    // MARK: - Challenges
    private var challengesSection: some View {
        let groupChallenges = dataManager.getChallenges(for: group.id)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Challenges")
                    .font(.headline)
                Spacer()
                Button {
                    showCreateChallenge = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentOrange)
                }
            }
            
            if groupChallenges.isEmpty {
                Text("No active challenges. Create one!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(groupChallenges) { challenge in
                    ChallengeRow(challenge: challenge)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Invite Friends")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Challenge Row
struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(challenge.targetPushups) pushups • \(challenge.daysRemaining) days left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        GroupDetailView(group: FitnessGroup(name: "Workout Buddies", emoji: "🏋️", createdBy: UUID(), weeklyGoal: 500))
            .environmentObject(DataManager.shared)
    }
    .preferredColorScheme(.dark)
}
