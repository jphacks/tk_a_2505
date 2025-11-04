//
//  GroupModel.swift
//  escape
//
//  Created by Claude on 2025/11/02.
//

import Foundation

// MARK: - Group Model

/// Represents a group from the database
struct Group: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String?
    let iconUrl: String?
    let ownerId: UUID
    let inviteCode: String
    let maxMembers: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconUrl = "icon_url"
        case ownerId = "owner_id"
        case inviteCode = "invite_code"
        case maxMembers = "max_members"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Group Member Model

/// Represents the role of a group member
enum MemberRole: String, Codable, CaseIterable {
    case owner
    case admin
    case member

    var displayName: String {
        switch self {
        case .owner:
            return String(localized: "role.owner")
        case .admin:
            return String(localized: "role.admin")
        case .member:
            return String(localized: "role.member")
        }
    }

    var canManageMembers: Bool {
        switch self {
        case .owner, .admin:
            return true
        case .member:
            return false
        }
    }
}

/// Represents a group member from the database
struct GroupMember: Codable, Identifiable, Equatable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    let role: MemberRole
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}

// MARK: - Helper Extensions

extension Group {
    /// Returns true if the current user is the owner of this group
    var isCurrentUserOwner: Bool {
        // This would need to be set based on current user context
        // For now, this is a placeholder that should be set by the ViewModel
        false
    }

    /// Returns a shortened invite code for display
    var displayInviteCode: String {
        let code = inviteCode
        if code.count >= 4 {
            let firstTwo = String(code.prefix(2))
            let lastTwo = String(code.suffix(2))
            return "\(firstTwo)••\(lastTwo)"
        }
        return code
    }

    /// Returns member count if available (to be set by ViewModel)
    var memberCount: Int {
        // This would be populated by the ViewModel from a separate query
        0
    }
}

// MARK: - Request Models

/// Request model for creating a new group
struct CreateGroupRequest: Codable {
    let name: String
    let description: String?

    init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
    }
}

/// Request model for updating group information
struct UpdateGroupRequest: Codable {
    let name: String?
    let description: String?
    let maxMembers: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case maxMembers = "max_members"
    }
}

// MARK: - Response Models

/// Extended group model with additional information
struct GroupWithDetails: Codable, Identifiable {
    let group: Group
    let memberCount: Int
    let isCurrentUserMember: Bool
    let currentUserRole: MemberRole?

    var id: UUID {
        group.id
    }
}

/// Response model for group member with user information
struct GroupMemberWithUser: Codable, Identifiable {
    let member: GroupMember
    let user: User

    var id: UUID {
        member.id
    }

    var displayName: String {
        user.displayName
    }

    var roleDisplayName: String {
        member.role.displayName
    }
}

// MARK: - Error Types

enum GroupError: LocalizedError {
    case invalidInviteCode
    case groupFull
    case alreadyMember
    case notMember
    case insufficientPermissions
    case groupNotFound
    case creationFailed
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode:
            return String(localized: "group.error.invalid_invite_code")
        case .groupFull:
            return String(localized: "group.error.group_full")
        case .alreadyMember:
            return String(localized: "group.error.already_member")
        case .notMember:
            return String(localized: "group.error.not_member")
        case .insufficientPermissions:
            return String(localized: "group.error.insufficient_permissions")
        case .groupNotFound:
            return String(localized: "group.error.group_not_found")
        case .creationFailed:
            return String(localized: "group.error.creation_failed")
        case .deletionFailed:
            return String(localized: "group.error.deletion_failed")
        }
    }
}
