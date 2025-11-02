//
//  GroupViewModel.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import Foundation

@MainActor
@Observable
class GroupViewModel {
    // MARK: - Dependencies

    private let groupSupabase: GroupSupabase
    private let userSupabase: UserSupabase

    // MARK: - Published State

    var userGroups: [GroupWithDetails] = []
    var selectedGroup: GroupWithDetails?
    var groupMembers: [GroupMemberWithUser] = []
    var isLoading = false
    var isCreatingGroup = false
    var isJoiningGroup = false
    var errorMessage: String?

    // MARK: - Form State

    var createGroupName: String = ""
    var createGroupDescription: String = ""
    var joinGroupInviteCode: String = ""

    // MARK: - Initialization

    init(groupSupabase: GroupSupabase = GroupSupabase(), userSupabase: UserSupabase = UserSupabase()) {
        self.groupSupabase = groupSupabase
        self.userSupabase = userSupabase
    }

    // MARK: - Group Management

    /// Loads all groups for the current user
    func loadUserGroups() async {
        isLoading = true
        errorMessage = nil

        do {
            userGroups = try await groupSupabase.fetchUserGroups()
        } catch {
            errorMessage = "グループの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ Failed to load user groups: \(error)")
        }

        isLoading = false
    }

    /// Creates a new group
    func createGroup() async {
        guard !createGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "グループ名を入力してください"
            return
        }

        isCreatingGroup = true
        errorMessage = nil

        do {
            let request = CreateGroupRequest(
                name: createGroupName.trimmingCharacters(in: .whitespacesAndNewlines),
                description: createGroupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : createGroupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            let groupId = try await groupSupabase.createGroup(request)
            print("✅ Created group with ID: \(groupId)")

            // Clear form
            createGroupName = ""
            createGroupDescription = ""

            // Reload groups to show the new one
            await loadUserGroups()

        } catch {
            errorMessage = "グループの作成に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to create group: \(error)")
        }

        isCreatingGroup = false
    }

    /// Joins a group using invite code
    func joinGroup() async {
        guard !joinGroupInviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "招待コードを入力してください"
            return
        }

        isJoiningGroup = true
        errorMessage = nil

        do {
            let groupId = try await groupSupabase.joinGroup(inviteCode: joinGroupInviteCode.trimmingCharacters(in: .whitespacesAndNewlines))
            print("✅ Joined group with ID: \(groupId)")

            // Clear form
            joinGroupInviteCode = ""

            // Reload groups to show the new one
            await loadUserGroups()

        } catch {
            if let groupError = error as? GroupError {
                errorMessage = groupError.localizedDescription
            } else {
                errorMessage = "グループへの参加に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to join group: \(error)")
        }

        isJoiningGroup = false
    }

    /// Selects a group and loads its members
    func selectGroup(_ group: GroupWithDetails) async {
        selectedGroup = group
        await loadGroupMembers(groupId: group.id)
    }

    /// Loads members for a specific group
    func loadGroupMembers(groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            groupMembers = try await groupSupabase.fetchGroupMembers(groupId: groupId)
        } catch {
            errorMessage = "メンバーの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ Failed to load group members: \(error)")
        }

        isLoading = false
    }

    /// Leaves the currently selected group
    func leaveCurrentGroup() async {
        guard let group = selectedGroup else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await groupSupabase.leaveGroup(groupId: group.id)
            print("✅ Left group: \(group.group.name)")

            // Clear selection and reload groups
            selectedGroup = nil
            groupMembers = []
            await loadUserGroups()

        } catch {
            errorMessage = "グループからの退出に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to leave group: \(error)")
        }

        isLoading = false
    }

    /// Removes a member from the group (admin/owner only)
    func removeMember(_ member: GroupMemberWithUser) async {
        guard let group = selectedGroup else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await groupSupabase.removeMember(groupId: group.id, userId: member.member.userId)
            print("✅ Removed member: \(member.user.displayName)")

            // Reload members
            await loadGroupMembers(groupId: group.id)

        } catch {
            errorMessage = "メンバーの削除に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to remove member: \(error)")
        }

        isLoading = false
    }

    /// Updates a member's role (owner only)
    func updateMemberRole(_ member: GroupMemberWithUser, newRole: MemberRole) async {
        guard let group = selectedGroup else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await groupSupabase.updateMemberRole(
                groupId: group.id,
                userId: member.member.userId,
                newRole: newRole
            )
            print("✅ Updated member role: \(member.user.displayName) -> \(newRole.displayName)")

            // Reload members to reflect changes
            await loadGroupMembers(groupId: group.id)

        } catch {
            errorMessage = "役割の変更に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to update member role: \(error)")
        }

        isLoading = false
    }

    /// Updates group information (owner only)
    func updateGroup(name: String?, description: String?) async {
        guard let group = selectedGroup else { return }

        isLoading = true
        errorMessage = nil

        do {
            let request = UpdateGroupRequest(
                name: name,
                description: description,
                maxMembers: nil
            )

            try await groupSupabase.updateGroup(groupId: group.id, request: request)
            print("✅ Updated group: \(group.group.name)")

            // Reload groups to reflect changes
            await loadUserGroups()

        } catch {
            errorMessage = "グループ情報の更新に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to update group: \(error)")
        }

        isLoading = false
    }

    /// Deletes the group (owner only)
    func deleteGroup() async {
        guard let group = selectedGroup else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await groupSupabase.deleteGroup(groupId: group.id)
            print("✅ Deleted group: \(group.group.name)")

            // Clear selection and reload groups
            selectedGroup = nil
            groupMembers = []
            await loadUserGroups()

        } catch {
            errorMessage = "グループの削除に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to delete group: \(error)")
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    /// Clears any error message
    func clearError() {
        errorMessage = nil
    }

    /// Checks if the current user is the owner of the selected group
    var isCurrentUserOwner: Bool {
        guard let group = selectedGroup else { return false }
        return group.currentUserRole == .owner
    }

    /// Checks if the current user is an admin or owner of the selected group
    var canManageMembers: Bool {
        guard let group = selectedGroup else { return false }
        return group.currentUserRole?.canManageMembers ?? false
    }

    /// Gets a formatted member count string
    func memberCountText(for group: GroupWithDetails) -> String {
        return "\(group.memberCount)/\(group.group.maxMembers)人"
    }

    /// Validates if invite code format is correct
    func isValidInviteCode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 8 && trimmed.allSatisfy { $0.isUppercase || $0.isNumber }
    }

    /// Validates if group name is acceptable
    func isValidGroupName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 100
    }
}
