//
//  ShelterBadgeModel.swift
//  escape
//
//  Created for shelter badge management
//

import Foundation
import SwiftUI

// MARK: - Database Model

struct ShelterBadge: Codable, Identifiable {
    let id: UUID
    let badgeName: String
    let shelterId: UUID
    let firstUserId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case badgeName = "badge_name"
        case shelterId = "shelter_id"
        case firstUserId = "first_user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Helper Extensions

extension ShelterBadge {
    /// Converts the database model to a UI Badge model
    /// - Parameter isUnlocked: Whether the current user has unlocked this badge
    /// - Returns: A Badge object for display in the UI
    func toBadge(isUnlocked: Bool) -> Badge {
        Badge(
            id: id.uuidString,
            name: badgeName,
            icon: determineIcon(),
            color: determineColor(),
            isUnlocked: isUnlocked
        )
    }

    /// Determines the appropriate icon based on badge name
    /// This can be customized based on your badge naming conventions
    private func determineIcon() -> String {
        let lowerName = badgeName.lowercased()

        // Map badge names to SF Symbols
        if lowerName.contains("first") || lowerName.contains("pioneer") {
            return "star.fill"
        } else if lowerName.contains("shelter") || lowerName.contains("避難所") {
            return "house.fill"
        } else if lowerName.contains("earthquake") || lowerName.contains("地震") {
            return "waveform.path.ecg"
        } else if lowerName.contains("flood") || lowerName.contains("洪水") {
            return "water.waves"
        } else if lowerName.contains("fire") || lowerName.contains("火災") {
            return "flame.fill"
        } else if lowerName.contains("speed") || lowerName.contains("fast") {
            return "timer"
        } else if lowerName.contains("complete") || lowerName.contains("達成") {
            return "checkmark.circle.fill"
        } else if lowerName.contains("expert") || lowerName.contains("master") {
            return "shield.fill"
        } else {
            return "medal.fill"
        }
    }

    /// Determines the appropriate color based on badge characteristics
    private func determineColor() -> Color {
        let lowerName = badgeName.lowercased()

        // Map badge names to brand colors
        if lowerName.contains("first") || lowerName.contains("pioneer") {
            return Color("brandOrange")
        } else if lowerName.contains("earthquake") || lowerName.contains("地震") {
            return Color("brandOrange")
        } else if lowerName.contains("flood") || lowerName.contains("tsunami") ||
                   lowerName.contains("洪水") || lowerName.contains("津波") {
            return Color("brandDarkBlue")
        } else if lowerName.contains("fire") || lowerName.contains("火災") {
            return Color("brandRed")
        } else if lowerName.contains("expert") || lowerName.contains("master") {
            return Color("brandMediumBlue")
        } else {
            return Color("brandPeach")
        }
    }
}

// MARK: - Extended Model with Relations

/// Extended shelter badge model that includes related shelter and user information
struct ShelterBadgeWithDetails: Codable, Identifiable {
    let id: UUID
    let badgeName: String
    let shelterId: UUID
    let firstUserId: UUID
    let createdAt: Date
    let shelter: Shelter?
    let firstUser: User?

    enum CodingKeys: String, CodingKey {
        case id
        case badgeName = "badge_name"
        case shelterId = "shelter_id"
        case firstUserId = "first_user_id"
        case createdAt = "created_at"
        case shelter
        case firstUser = "first_user"
    }
}

// MARK: - User Shelter Badge (Junction Table)

/// Represents a user's unlocked badge from the user_shelter_badges table
struct UserShelterBadge: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let badgeId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case badgeId = "badge_id"
        case createdAt = "created_at"
    }
}

// MARK: - Badge Generation Request

/// Request model for generating a new shelter badge
struct CreateShelterBadgeRequest: Codable {
    let badgeName: String
    let shelterId: UUID
    let firstUserId: UUID

    enum CodingKeys: String, CodingKey {
        case badgeName = "badge_name"
        case shelterId = "shelter_id"
        case firstUserId = "first_user_id"
    }
}

// MARK: - User Badge Unlock Request

/// Request model for unlocking a badge for a user
struct UnlockBadgeRequest: Codable {
    let userId: UUID
    let badgeId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case badgeId = "badge_id"
    }
}

// MARK: - User Badge with Shelter Details

/// Represents a user's collected badge with full shelter information
struct UserBadgeWithShelter: Codable, Identifiable {
    let userBadgeInfo: UserShelterBadge
    let shelterBadgeInfo: ShelterBadge
    let shelterInfo: Shelter

    var id: UUID {
        userBadgeInfo.id
    }

    /// Converts to UI Badge model for display
    func toBadge() -> Badge {
        return shelterBadgeInfo.toBadge(isUnlocked: true)
    }
}
