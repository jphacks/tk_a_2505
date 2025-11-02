//
//  GroupSupabase.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import Foundation
import Supabase

class GroupSupabase {
    // MARK: - Group Operations

    /// Creates a new group using the database function
    /// - Parameter request: CreateGroupRequest with group details
    /// - Returns: The created group ID
    /// - Throws: Database error if creation fails
    func createGroup(_ request: CreateGroupRequest) async throws -> UUID {
        // rpc関数のパラメータを適切な型で構築
        struct CreateGroupParams: Encodable {
            let group_name: String
            let group_description: String?
            let max_members_count: Int
        }

        let params = CreateGroupParams(
            group_name: request.name,
            group_description: request.description,
            max_members_count: 50
        )

        let response: UUID = try await supabase
            .rpc("create_user_group", params: params)
            .execute()
            .value

        return response
    }

    /// Fetches all groups that the current user is a member of
    /// - Returns: Array of groups with member count
    /// - Throws: Database error if fetch fails
    func fetchUserGroups() async throws -> [GroupWithDetails] {
        let currentUser = try await supabase.auth.session.user

        // First get the groups the user is a member of
        let memberGroups: [GroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("user_id", value: currentUser.id)
            .execute()
            .value

        let groupIds = memberGroups.map { $0.groupId }

        guard !groupIds.isEmpty else {
            return []
        }

        // Fetch the group details
        let groups: [Group] = try await supabase
            .from("groups")
            .select()
            .in("id", values: groupIds)
            .execute()
            .value

        // Get member counts for each group
        var groupsWithDetails: [GroupWithDetails] = []

        for group in groups {
            let memberCount = try await fetchMemberCount(groupId: group.id)
            let currentUserMember = memberGroups.first { $0.groupId == group.id }

            let groupWithDetails = GroupWithDetails(
                group: group,
                memberCount: memberCount,
                isCurrentUserMember: true,
                currentUserRole: currentUserMember?.role
            )

            groupsWithDetails.append(groupWithDetails)
        }

        return groupsWithDetails
    }

    /// Fetches a specific group by ID
    /// - Parameter groupId: The group UUID
    /// - Returns: Group object if found
    /// - Throws: Database error if fetch fails
    func fetchGroup(by groupId: UUID) async throws -> Group? {
        let groups: [Group] = try await supabase
            .from("groups")
            .select()
            .eq("id", value: groupId)
            .limit(1)
            .execute()
            .value

        return groups.first
    }

    /// Updates group information
    /// - Parameters:
    ///   - groupId: The group UUID
    ///   - request: UpdateGroupRequest with new information
    /// - Throws: Database error if update fails
    func updateGroup(groupId: UUID, request: UpdateGroupRequest) async throws {
        struct GroupUpdate: Encodable {
            let name: String?
            let description: String?
            let maxMembers: Int?
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case name
                case description
                case maxMembers = "max_members"
                case updatedAt = "updated_at"
            }
        }

        let updateData = GroupUpdate(
            name: request.name,
            description: request.description,
            maxMembers: request.maxMembers,
            updatedAt: Date()
        )

        try await supabase
            .from("groups")
            .update(updateData)
            .eq("id", value: groupId)
            .execute()
    }

    /// Deletes a group
    /// - Parameter groupId: The group UUID
    /// - Throws: Database error if deletion fails
    func deleteGroup(groupId: UUID) async throws {
        print("🗑️ Attempting to delete group with ID: \(groupId)")

        // First, verify the group exists and the user is the owner
        let currentUser = try await supabase.auth.session.user
        print("🗑️ Current user ID: \(currentUser.id)")

        let groups: [Group] = try await supabase
            .from("groups")
            .select()
            .eq("id", value: groupId)
            .eq("owner_id", value: currentUser.id)
            .execute()
            .value

        print("🗑️ Found \(groups.count) groups to delete")

        if groups.isEmpty {
            throw GroupError.insufficientPermissions
        }

        // Delete the group (RLS policy will handle ownership verification)
        let result = try await supabase
            .from("groups")
            .delete()
            .eq("id", value: groupId)
            .execute()

        print("🗑️ Delete result: \(result)")

        // Verify deletion
        let remainingGroups: [Group] = try await supabase
            .from("groups")
            .select()
            .eq("id", value: groupId)
            .execute()
            .value

        print("🗑️ Remaining groups after deletion: \(remainingGroups.count)")

        if !remainingGroups.isEmpty {
            throw GroupError.deletionFailed
        }

        print("✅ Group deletion completed successfully")
    }

    // MARK: - Group Member Operations

    /// Joins a group using invite code
    /// - Parameter inviteCode: 8-character invite code
    /// - Returns: The group ID that was joined
    /// - Throws: Database error if join fails
    func joinGroup(inviteCode: String) async throws -> UUID {
        struct JoinGroupParams: Encodable {
            let p_invite_code: String
        }

        let params = JoinGroupParams(p_invite_code: inviteCode)

        let response: UUID = try await supabase
            .rpc("join_group_by_invite_code", params: params)
            .execute()
            .value

        return response
    }

    /// Fetches all members of a group with user information
    /// - Parameter groupId: The group UUID
    /// - Returns: Array of group members with user details
    /// - Throws: Database error if fetch fails
    func fetchGroupMembers(groupId: UUID) async throws -> [GroupMemberWithUser] {
        // First, get all group members
        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .order("joined_at", ascending: true)
            .execute()
            .value

        // Get all unique user IDs
        let userIds = members.map { $0.userId }

        // Fetch all users in one query
        let users: [User] = try await supabase
            .from("users")
            .select()
            .in("id", values: userIds)
            .execute()
            .value

        // Create a dictionary for quick user lookup
        let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        // Combine members with their user information
        let membersWithUsers: [GroupMemberWithUser] = members.compactMap { member in
            guard let user = userDict[member.userId] else { return nil }
            return GroupMemberWithUser(member: member, user: user)
        }

        return membersWithUsers
    }

    /// Removes a member from a group
    /// - Parameters:
    ///   - groupId: The group UUID
    ///   - userId: The user UUID to remove
    /// - Throws: Database error if removal fails
    func removeMember(groupId: UUID, userId: UUID) async throws {
        try await supabase
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Leaves a group (removes current user)
    /// - Parameter groupId: The group UUID
    /// - Throws: Database error if leaving fails
    func leaveGroup(groupId: UUID) async throws {
        let currentUser = try await supabase.auth.session.user

        try await supabase
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId)
            .eq("user_id", value: currentUser.id)
            .execute()
    }

    /// Updates a member's role
    /// - Parameters:
    ///   - groupId: The group UUID
    ///   - userId: The user UUID
    ///   - newRole: The new role to assign
    /// - Throws: Database error if update fails
    func updateMemberRole(groupId: UUID, userId: UUID, newRole: MemberRole) async throws {
        try await supabase
            .from("group_members")
            .update(["role": newRole.rawValue])
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Helper Methods

    /// Fetches the member count for a specific group
    /// - Parameter groupId: The group UUID
    /// - Returns: Number of members in the group
    /// - Throws: Database error if fetch fails
    private func fetchMemberCount(groupId: UUID) async throws -> Int {
        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .execute()
            .value

        return members.count
    }

    /// Checks if the current user is a member of a specific group
    /// - Parameter groupId: The group UUID
    /// - Returns: True if user is a member, false otherwise
    func isCurrentUserMember(of groupId: UUID) async throws -> Bool {
        let currentUser = try await supabase.auth.session.user

        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .eq("user_id", value: currentUser.id)
            .limit(1)
            .execute()
            .value

        return !members.isEmpty
    }

    /// Gets the current user's role in a specific group
    /// - Parameter groupId: The group UUID
    /// - Returns: The user's role if they are a member, nil otherwise
    func getCurrentUserRole(in groupId: UUID) async throws -> MemberRole? {
        let currentUser = try await supabase.auth.session.user

        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .eq("user_id", value: currentUser.id)
            .limit(1)
            .execute()
            .value

        return members.first?.role
    }
}

// MARK: - Error Handling Extension

extension GroupSupabase {
    /// Converts Supabase errors to GroupError
    private func handleError(_ error: Error) -> Error {
        // Convert specific Supabase errors to GroupError
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("invalid invite code") {
            return GroupError.invalidInviteCode
        } else if errorMessage.contains("group is full") {
            return GroupError.groupFull
        } else if errorMessage.contains("already a member") {
            return GroupError.alreadyMember
        } else if errorMessage.contains("user must be authenticated") {
            return GroupError.insufficientPermissions
        }

        return error
    }
}
