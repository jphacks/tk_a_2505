//
//  GroupSupabase.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import Foundation
import Supabase

// MARK: - RPC Parameter Types

/// Parameter type for creating a team via RPC function
private struct CreateTeamParams: Sendable, Encodable {
    let group_name: String
    let group_description: String?
    let max_members_count: Int

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(group_name, forKey: .group_name)
        try container.encode(group_description, forKey: .group_description)
        try container.encode(max_members_count, forKey: .max_members_count)
    }

    private enum CodingKeys: String, CodingKey {
        case group_name
        case group_description
        case max_members_count
    }
}

/// Parameter type for joining a team via RPC function
private struct JoinTeamParams: Sendable, Encodable {
    let p_invite_code: String

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(p_invite_code, forKey: .p_invite_code)
    }

    private enum CodingKeys: String, CodingKey {
        case p_invite_code
    }
}

// MARK: - TeamSupabase

class TeamSupabase {
    // MARK: - Team Operations

    /// Creates a new group using the database function
    /// - Parameter request: CreateTeamRequest with group details
    /// - Returns: The created group ID
    /// - Throws: Database error if creation fails
    func createTeam(_ request: CreateTeamRequest) async throws -> UUID {
        // rpc関数のパラメータを適切な型で構築

        let params = CreateTeamParams(
            group_name: request.name,
            group_description: request.description,
            max_members_count: 50
        )

        let response: UUID =
            try await supabase
                .rpc("create_user_group", params: params)
                .execute()
                .value

        return response
    }

    /// Fetches all groups that the current user is a member of
    /// - Returns: Array of groups with member count
    /// - Throws: Database error if fetch fails
    func fetchUserTeams() async throws -> [TeamWithDetails] {
        let currentUser = try await supabase.auth.session.user

        // First get the groups the user is a member of
        let memberTeams: [TeamMember] =
            try await supabase
                .from("group_members")
                .select()
                .eq("user_id", value: currentUser.id)
                .execute()
                .value

        let groupIds = memberTeams.map { $0.groupId }

        guard !groupIds.isEmpty else {
            return []
        }

        // Fetch the group details
        let groups: [Team] =
            try await supabase
                .from("groups")
                .select()
                .in("id", values: groupIds)
                .execute()
                .value

        // Get member counts for each group
        var groupsWithDetails: [TeamWithDetails] = []

        for group in groups {
            let memberCount = try await fetchMemberCount(groupId: group.id)
            let currentUserMember = memberTeams.first { $0.groupId == group.id }

            let groupWithDetails = TeamWithDetails(
                team: group,
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
    /// - Returns: Team object if found
    /// - Throws: Database error if fetch fails
    func fetchTeam(by groupId: UUID) async throws -> Team? {
        let groups: [Team] =
            try await supabase
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
    ///   - request: UpdateTeamRequest with new information
    /// - Throws: Database error if update fails
    func updateTeam(groupId: UUID, request: UpdateTeamRequest) async throws {
        struct TeamUpdate: Encodable {
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

        let updateData = TeamUpdate(
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
    func deleteTeam(groupId: UUID) async throws {
        print("🗑️ Attempting to delete group with ID: \(groupId)")

        // First, verify the group exists and the user is the owner
        let currentUser = try await supabase.auth.session.user
        print("🗑️ Current user ID: \(currentUser.id)")

        let groups: [Team] =
            try await supabase
                .from("groups")
                .select()
                .eq("id", value: groupId)
                .eq("owner_id", value: currentUser.id)
                .execute()
                .value

        print("🗑️ Found \(groups.count) groups to delete")

        if groups.isEmpty {
            throw TeamError.insufficientPermissions
        }

        // Delete the group (RLS policy will handle ownership verification)
        let result =
            try await supabase
                .from("groups")
                .delete()
                .eq("id", value: groupId)
                .execute()

        print("🗑️ Delete result: \(result)")

        // Verify deletion
        let remainingTeams: [Team] =
            try await supabase
                .from("groups")
                .select()
                .eq("id", value: groupId)
                .execute()
                .value

        print("🗑️ Remaining groups after deletion: \(remainingTeams.count)")

        if !remainingTeams.isEmpty {
            throw TeamError.deletionFailed
        }

        print("✅ Team deletion completed successfully")
    }

    // MARK: - Team Member Operations

    /// Joins a group using invite code
    /// - Parameter inviteCode: 8-character invite code
    /// - Returns: The group ID that was joined
    /// - Throws: Database error if join fails
    func joinTeam(inviteCode: String) async throws -> UUID {
        let params = JoinTeamParams(p_invite_code: inviteCode)

        let response: UUID =
            try await supabase
                .rpc("join_group_by_invite_code", params: params)
                .execute()
                .value

        return response
    }

    /// Fetches all members of a group with user information
    /// - Parameter groupId: The group UUID
    /// - Returns: Array of group members with user details
    /// - Throws: Database error if fetch fails
    func fetchTeamMembers(groupId: UUID) async throws -> [TeamMemberWithUser] {
        // First, get all group members
        let members: [TeamMember] =
            try await supabase
                .from("group_members")
                .select()
                .eq("group_id", value: groupId)
                .order("joined_at", ascending: true)
                .execute()
                .value

        // Get all unique user IDs
        let userIds = members.map { $0.userId }

        // Fetch all users in one query
        let users: [User] =
            try await supabase
                .from("users")
                .select()
                .in("id", values: userIds)
                .execute()
                .value

        // Create a dictionary for quick user lookup
        let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        // Combine members with their user information
        let membersWithUsers: [TeamMemberWithUser] = members.compactMap { member in
            guard let user = userDict[member.userId] else { return nil }
            return TeamMemberWithUser(member: member, user: user)
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
    func leaveTeam(groupId: UUID) async throws {
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
        let members: [TeamMember] =
            try await supabase
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

        let members: [TeamMember] =
            try await supabase
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

        let members: [TeamMember] =
            try await supabase
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

extension TeamSupabase {
    /// Converts Supabase errors to TeamError
    private func handleError(_ error: Error) -> Error {
        // Convert specific Supabase errors to TeamError
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("invalid invite code") {
            return TeamError.invalidInviteCode
        } else if errorMessage.contains("group is full") {
            return TeamError.groupFull
        } else if errorMessage.contains("already a member") {
            return TeamError.alreadyMember
        } else if errorMessage.contains("user must be authenticated") {
            return TeamError.insufficientPermissions
        }

        return error
    }
}
