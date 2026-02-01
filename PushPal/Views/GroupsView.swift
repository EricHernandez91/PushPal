import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var joinCode = ""
    @State private var isJoining = false
    @State private var joinError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick actions
                    HStack(spacing: 12) {
                        actionButton(
                            title: "Create Group",
                            icon: "plus.circle.fill",
                            color: .accentOrange
                        ) {
                            showCreateGroup = true
                        }
                        
                        actionButton(
                            title: "Join Group",
                            icon: "person.badge.plus",
                            color: .accentBlue
                        ) {
                            showJoinGroup = true
                        }
                    }
                    .padding(.horizontal)
                    
                    // Active challenges
                    if !dataManager.getActiveChallenges().isEmpty {
                        activeChallengesSection
                    }
                    
                    // My groups
                    if dataManager.groups.isEmpty {
                        emptyGroupsView
                    } else {
                        groupsList
                    }
                }
                .padding(.vertical)
            }
            .background(Color.background)
            .navigationTitle("Groups")
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView()
                    .environmentObject(dataManager)
            }
            .alert("Join Group", isPresented: $showJoinGroup) {
                TextField("Enter invite code", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                Button("Cancel", role: .cancel) {
                    joinCode = ""
                }
                Button("Join") {
                    Task {
                        await joinGroup()
                    }
                }
            } message: {
                Text("Enter the 6-character invite code")
            }
            .alert("Error", isPresented: .constant(joinError != nil)) {
                Button("OK") {
                    joinError = nil
                }
            } message: {
                if let error = joinError {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Action Button
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Active Challenges
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Challenges")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.getActiveChallenges()) { challenge in
                        ChallengeCard(challenge: challenge)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Groups List
    private var groupsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Groups")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(dataManager.groups) { group in
                NavigationLink(destination: GroupDetailView(group: group)) {
                    GroupCard(group: group)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyGroupsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Groups Yet")
                .font(.title2.weight(.semibold))
            
            Text("Create or join a group to compete with friends and stay accountable!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Join Group Action
    private func joinGroup() async {
        guard joinCode.count == 6 else {
            joinError = "Invalid code. Please enter a 6-character code."
            return
        }
        
        isJoining = true
        
        do {
            if let _ = try await dataManager.joinGroup(inviteCode: joinCode.uppercased()) {
                joinCode = ""
            } else {
                joinError = "No group found with that code."
            }
        } catch {
            joinError = "Failed to join group. Please try again."
        }
        
        isJoining = false
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: FitnessGroup
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji avatar
            Text(group.emoji)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(Color.accentOrange.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                Text("\(group.memberIds.count) members • \(group.weeklyGoal) weekly goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯")
                    .font(.title)
                Spacer()
                Text("\(challenge.daysRemaining)d left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(challenge.name)
                .font(.headline)
                .lineLimit(2)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentGreen)
                        .frame(width: geo.size.width * challenge.progress)
                }
            }
            .frame(height: 8)
            
            Text("\(challenge.targetPushups) pushups")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 180)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    GroupsView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
