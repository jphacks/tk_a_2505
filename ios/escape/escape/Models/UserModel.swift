//
//  UserModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/11.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let name: String?
    let profileBadgeId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
        case profileBadgeId = "shelter_badge_id"
    }
}

// MARK: - Helper Extensions

extension User {
    /// Returns the display name, or a default if name is nil
    var displayName: String {
        name ?? "Anonymous User"
    }

    /// Returns true if the user has set their name
    var hasName: Bool {
        name != nil && !(name?.isEmpty ?? true)
    }
}
