import Foundation
import CloudKit

actor CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    
    // Record types
    private let groupRecordType = "FitnessGroup"
    private let workoutRecordType = "Workout"
    private let memberRecordType = "GroupMember"
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.pushpal.app")
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            print("CloudKit account status error: \(error)")
            return .couldNotDetermine
        }
    }
    
    // MARK: - Groups
    
    func createGroup(_ group: FitnessGroup) async {
        let record = CKRecord(recordType: groupRecordType, recordID: CKRecord.ID(recordName: group.id.uuidString))
        record["name"] = group.name
        record["emoji"] = group.emoji
        record["inviteCode"] = group.inviteCode
        record["createdBy"] = group.createdBy.uuidString
        record["weeklyGoal"] = group.weeklyGoal
        record["memberIds"] = group.memberIds.map { $0.uuidString }
        record["isActive"] = group.isActive
        
        do {
            try await publicDatabase.save(record)
            print("Group created in CloudKit: \(group.name)")
        } catch {
            print("Failed to create group: \(error)")
        }
    }
    
    func fetchGroup(byInviteCode code: String) async -> FitnessGroup? {
        let predicate = NSPredicate(format: "inviteCode == %@", code)
        let query = CKQuery(recordType: groupRecordType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDatabase.records(matching: query)
            
            for (_, result) in results {
                if let record = try? result.get() {
                    return groupFromRecord(record)
                }
            }
        } catch {
            print("Failed to fetch group: \(error)")
        }
        
        return nil
    }
    
    func fetchUserGroups(userId: UUID) async -> [FitnessGroup] {
        let predicate = NSPredicate(format: "memberIds CONTAINS %@", userId.uuidString)
        let query = CKQuery(recordType: groupRecordType, predicate: predicate)
        
        var groups: [FitnessGroup] = []
        
        do {
            let (results, _) = try await publicDatabase.records(matching: query)
            
            for (_, result) in results {
                if let record = try? result.get(),
                   let group = groupFromRecord(record) {
                    groups.append(group)
                }
            }
        } catch {
            print("Failed to fetch user groups: \(error)")
        }
        
        return groups
    }
    
    private func groupFromRecord(_ record: CKRecord) -> FitnessGroup? {
        guard let name = record["name"] as? String,
              let emoji = record["emoji"] as? String,
              let inviteCode = record["inviteCode"] as? String,
              let createdByString = record["createdBy"] as? String,
              let createdBy = UUID(uuidString: createdByString),
              let weeklyGoal = record["weeklyGoal"] as? Int,
              let memberIdStrings = record["memberIds"] as? [String],
              let isActive = record["isActive"] as? Bool else {
            return nil
        }
        
        let memberIds = memberIdStrings.compactMap { UUID(uuidString: $0) }
        
        var group = FitnessGroup(id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                                  name: name,
                                  emoji: emoji,
                                  createdBy: createdBy,
                                  weeklyGoal: weeklyGoal)
        group.inviteCode = inviteCode
        group.memberIds = memberIds
        group.isActive = isActive
        
        return group
    }
    
    // MARK: - Workouts
    
    func syncWorkout(_ workout: Workout) async {
        let record = CKRecord(recordType: workoutRecordType, recordID: CKRecord.ID(recordName: workout.id.uuidString))
        record["date"] = workout.date
        record["pushupCount"] = workout.pushupCount
        record["duration"] = workout.duration
        record["averageFormScore"] = workout.averageFormScore
        record["caloriesBurned"] = workout.caloriesBurned
        
        do {
            try await privateDatabase.save(record)
        } catch {
            print("Failed to sync workout: \(error)")
        }
    }
    
    // MARK: - Group Members
    
    func fetchGroupMembers(groupId: UUID) async -> [GroupMember] {
        let predicate = NSPredicate(format: "groupId == %@", groupId.uuidString)
        let query = CKQuery(recordType: memberRecordType, predicate: predicate)
        
        var members: [GroupMember] = []
        
        do {
            let (results, _) = try await publicDatabase.records(matching: query)
            
            for (_, result) in results {
                if let record = try? result.get(),
                   let member = memberFromRecord(record) {
                    members.append(member)
                }
            }
        } catch {
            print("Failed to fetch group members: \(error)")
        }
        
        return members
    }
    
    private func memberFromRecord(_ record: CKRecord) -> GroupMember? {
        guard let userIdString = record["userId"] as? String,
              let userId = UUID(uuidString: userIdString),
              let displayName = record["displayName"] as? String,
              let avatarEmoji = record["avatarEmoji"] as? String,
              let weeklyPushups = record["weeklyPushups"] as? Int,
              let streak = record["streak"] as? Int else {
            return nil
        }
        
        return GroupMember(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            userId: userId,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            weeklyPushups: weeklyPushups,
            streak: streak
        )
    }
    
    func updateMemberStats(userId: UUID, groupId: UUID, weeklyPushups: Int, streak: Int) async {
        let recordId = CKRecord.ID(recordName: "\(groupId.uuidString)-\(userId.uuidString)")
        
        do {
            let record = try await publicDatabase.record(for: recordId)
            record["weeklyPushups"] = weeklyPushups
            record["streak"] = streak
            record["lastWorkoutDate"] = Date()
            try await publicDatabase.save(record)
        } catch {
            print("Failed to update member stats: \(error)")
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribeToGroupUpdates(groupId: UUID) async {
        let predicate = NSPredicate(format: "groupId == %@", groupId.uuidString)
        let subscription = CKQuerySubscription(
            recordType: memberRecordType,
            predicate: predicate,
            subscriptionID: "group-updates-\(groupId.uuidString)",
            options: [.firesOnRecordUpdate, .firesOnRecordCreation]
        )
        
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        do {
            try await publicDatabase.save(subscription)
        } catch {
            print("Failed to create subscription: \(error)")
        }
    }
}
