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

    /// Converts to UI Badge model for display with full shelter details
    func toBadge() -> Badge {
        Badge(
            id: shelterBadgeInfo.id.uuidString,
            name: shelterBadgeInfo.badgeName,
            icon: determineIcon(),
            color: determineColor(),
            isUnlocked: true,
            imageName: determineImageName(),
            badgeNumber: shelterInfo.commonId,
            address: shelterInfo.address,
            municipality: shelterInfo.municipality,
            isShelter: shelterInfo.isShelter ?? false,
            isFlood: shelterInfo.isFlood ?? false,
            isLandslide: shelterInfo.isLandslide ?? false,
            isStormSurge: shelterInfo.isStormSurge ?? false,
            isEarthquake: shelterInfo.isEarthquake ?? false,
            isTsunami: shelterInfo.isTsunami ?? false,
            isFire: shelterInfo.isFire ?? false,
            isInlandFlood: shelterInfo.isInlandFlood ?? false,
            isVolcano: shelterInfo.isVolcano ?? false,
            latitude: shelterInfo.latitude,
            longitude: shelterInfo.longitude
        )
    }

    /// Determines the appropriate icon based on badge name
    private func determineIcon() -> String {
        let lowerName = shelterBadgeInfo.badgeName.lowercased()

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
        let lowerName = shelterBadgeInfo.badgeName.lowercased()

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

    /// Determines image name based on shelter name
    /// This maps known shelter names to their image assets
    private func determineImageName() -> String? {
        let shelterName = shelterInfo.name.lowercased()

        // Map known shelter names to image assets
        if shelterName.contains("後楽園") || shelterName.contains("korakuen") {
            return "korakuen"
        } else if shelterName.contains("東大") || shelterName.contains("todai") {
            return "todaimae"
        } else if shelterName.contains("ロゴ") || shelterName.contains("logo") {
            return "logo"
        }
        // Add more mappings as needed

        return nil
    }
}

// MARK: - Badge UI Model

/// UI model for displaying badges with full shelter information
struct Badge: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    let imageName: String?

    // Shelter related information
    let badgeNumber: String?
    let address: String?
    let municipality: String?
    let isShelter: Bool
    let isFlood: Bool
    let isLandslide: Bool
    let isStormSurge: Bool
    let isEarthquake: Bool
    let isTsunami: Bool
    let isFire: Bool
    let isInlandFlood: Bool
    let isVolcano: Bool
    let latitude: Double?
    let longitude: Double?

    /// Returns list of supported disasters with icons and localized names
    var supportedDisasters: [(icon: String, name: String)] {
        var disasters: [(icon: String, name: String)] = []

        if isEarthquake {
            disasters.append((
                icon: "waveform.path.ecg",
                name: String(localized: "home.disaster.earthquake", table: "Localizable")
            ))
        }
        if isFlood {
            disasters.append((
                icon: "water.waves",
                name: String(localized: "home.disaster.flood", table: "Localizable")
            ))
        }
        if isFire {
            disasters.append((
                icon: "flame.fill",
                name: String(localized: "home.disaster.fire", table: "Localizable")
            ))
        }
        if isTsunami {
            disasters.append((
                icon: "water.waves.and.arrow.up",
                name: String(localized: "home.disaster.tsunami", table: "Localizable")
            ))
        }
        if isLandslide {
            disasters.append((
                icon: "mountain.2.fill",
                name: String(localized: "home.disaster.landslide", table: "Localizable")
            ))
        }
        if isStormSurge {
            disasters.append((
                icon: "wind",
                name: String(localized: "home.disaster.storm_surge", table: "Localizable")
            ))
        }
        if isInlandFlood {
            disasters.append((
                icon: "drop.fill",
                name: String(localized: "home.disaster.inland_flood", table: "Localizable")
            ))
        }
        if isVolcano {
            disasters.append((
                icon: "triangle.fill",
                name: String(localized: "home.disaster.volcano", table: "Localizable")
            ))
        }

        return disasters
    }

    /// Available brand colors for badges
    var availableColors: [Color] {
        return [
            Color("brandOrange"),
            Color("brandDarkBlue"),
            Color("brandMediumBlue"),
            Color("brandRed"),
            Color("brandPeach"),
            Color.green,
            Color.purple,
            Color.brown,
            Color.gray,
            Color.blue,
        ]
    }

    /// Returns a random color from available colors
    var randomColor: Color {
        return availableColors.randomElement() ?? Color("brandOrange")
    }

    /// Static helper to get a random color
    static var randomColor: Color {
        let colors = [
            Color("brandOrange"),
            Color("brandDarkBlue"),
            Color("brandMediumBlue"),
            Color("brandRed"),
            Color("brandPeach"),
            Color.green,
            Color.purple,
            Color.brown,
            Color.gray,
            Color.blue,
        ]
        return colors.randomElement() ?? Color("brandOrange")
    }
}
