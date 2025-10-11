//
//  BadgeService.swift
//  escape
//
//  Created for badge management and Supabase integration
//

import Foundation
import Supabase

@MainActor
class BadgeService {
    // MARK: - Fetch Badges

    /// Fetches all shelter badges with unlock status for the current user
    /// - Returns: Array of Badge objects for UI display with full shelter details
    func getUserBadges() async throws -> [Badge] {
        let currentUser = try await supabase.auth.session.user

        // Fetch all shelter badges with their shelter information
        let allShelterBadges: [ShelterBadge] = try await supabase
            .from("shelter_badges")
            .select()
            .order("created_at")
            .execute()
            .value

        // Fetch user's unlocked badges
        let unlockedBadges: [UserShelterBadge] = try await supabase
            .from("user_shelter_badges")
            .select()
            .eq("user_id", value: currentUser.id)
            .execute()
            .value

        let unlockedBadgeIds = Set(unlockedBadges.map { $0.badgeId })

        // Build Badge objects with full shelter details
        var badges: [Badge] = []

        for shelterBadge in allShelterBadges {
            // Fetch the shelter information for each badge
            let shelter: Shelter = try await supabase
                .from("shelters")
                .select()
                .eq("id", value: shelterBadge.shelterId.uuidString)
                .single()
                .execute()
                .value

            let isUnlocked = unlockedBadgeIds.contains(shelterBadge.id)

            // Create comprehensive Badge with shelter details
            let badge = createBadge(
                from: shelterBadge,
                shelter: shelter,
                isUnlocked: isUnlocked
            )

            badges.append(badge)
        }

        return badges
    }

    /// Fetches user's collected badges with full shelter and badge details
    /// This function queries user_shelter_badges, then joins with shelter_badges and shelters tables
    /// - Returns: Array of UserBadgeWithShelter containing user badge info, shelter badge info, and shelter info
    func getUserCollectedBadgesWithDetails() async throws -> [UserBadgeWithShelter] {
        let currentUser = try await supabase.auth.session.user

        // Step 1: Fetch user's collected badges from user_shelter_badges
        let userBadges: [UserShelterBadge] = try await supabase
            .from("user_shelter_badges")
            .select()
            .eq("user_id", value: currentUser.id)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Step 2: For each user badge, fetch the corresponding shelter badge and shelter info
        var result: [UserBadgeWithShelter] = []

        for userBadge in userBadges {
            // Fetch the shelter badge
            let shelterBadge: ShelterBadge = try await supabase
                .from("shelter_badges")
                .select()
                .eq("id", value: userBadge.badgeId)
                .single()
                .execute()
                .value

            // Fetch the shelter information
            // Note: Converting UUID to String for shelter ID lookup
            let shelter: Shelter = try await supabase
                .from("shelters")
                .select()
                .eq("id", value: shelterBadge.shelterId.uuidString)
                .single()
                .execute()
                .value

            // Combine into UserBadgeWithShelter
            let combined = UserBadgeWithShelter(
                userBadgeInfo: userBadge,
                shelterBadgeInfo: shelterBadge,
                shelterInfo: shelter
            )

            result.append(combined)
        }

        return result
    }

    /// Fetches badges with full details (including shelter and first user info)
    /// - Returns: Array of shelter badges with related data
    func getBadgesWithDetails() async throws -> [ShelterBadgeWithDetails] {
        let badges: [ShelterBadgeWithDetails] = try await supabase
            .from("shelter_badges")
            .select("*, shelter:shelters(*), first_user:users(*)")
            .order("created_at")
            .execute()
            .value

        return badges
    }

    // MARK: - Create Badges

    /// Creates a new shelter badge (typically when first user visits a shelter)
    /// - Parameters:
    ///   - badgeName: Name of the badge
    ///   - shelterId: The shelter UUID
    ///   - firstUserId: The first user to visit this shelter
    /// - Returns: The created shelter badge
    @discardableResult
    func createShelterBadge(
        badgeName: String,
        shelterId: UUID,
        firstUserId: UUID
    ) async throws -> ShelterBadge {
        let request = CreateShelterBadgeRequest(
            badgeName: badgeName,
            shelterId: shelterId,
            firstUserId: firstUserId
        )

        let createdBadge: ShelterBadge = try await supabase
            .from("shelter_badges")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        debugPrint("✅ Created shelter badge: \(badgeName) for shelter: \(shelterId)")
        return createdBadge
    }

    /// Generates a badge name for a shelter
    /// - Parameter shelter: The shelter object
    /// - Returns: A localized badge name
    func generateBadgeName(for shelter: Shelter) -> String {
        // Use the shelter name to create a badge name
        return "First Visit: \(shelter.name)"
    }

    // MARK: - Check Badge Status

    /// Checks if a badge already exists for a specific shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: True if a badge exists, false otherwise
    func badgeExists(forShelter shelterId: UUID) async throws -> Bool {
        let badges: [ShelterBadge] = try await supabase
            .from("shelter_badges")
            .select()
            .eq("shelter_id", value: shelterId)
            .limit(1)
            .execute()
            .value

        return !badges.isEmpty
    }

    /// Checks if the current user was the first to visit a shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: True if current user was first, false otherwise
    func isCurrentUserFirstVisitor(shelterId: UUID) async throws -> Bool {
        let currentUser = try await supabase.auth.session.user

        let badges: [ShelterBadge] = try await supabase
            .from("shelter_badges")
            .select()
            .eq("shelter_id", value: shelterId)
            .eq("first_user_id", value: currentUser.id)
            .limit(1)
            .execute()
            .value

        return !badges.isEmpty
    }

    // MARK: - Unlock Badges

    /// Unlocks a badge for the current user
    /// - Parameter badgeId: The badge UUID to unlock
    /// - Returns: The created user badge record
    @discardableResult
    func unlockBadge(badgeId: UUID) async throws -> UserShelterBadge {
        let currentUser = try await supabase.auth.session.user

        // Check if user already has this badge
        if try await hasUnlockedBadge(badgeId: badgeId) {
            throw BadgeServiceError.badgeAlreadyUnlocked
        }

        let request = UnlockBadgeRequest(
            userId: currentUser.id,
            badgeId: badgeId
        )

        let unlockedBadge: UserShelterBadge = try await supabase
            .from("user_shelter_badges")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        debugPrint("✅ Badge unlocked for user: \(currentUser.id)")
        return unlockedBadge
    }

    /// Checks if the current user has unlocked a specific badge
    /// - Parameter badgeId: The badge UUID
    /// - Returns: True if unlocked, false otherwise
    func hasUnlockedBadge(badgeId: UUID) async throws -> Bool {
        let currentUser = try await supabase.auth.session.user

        let badges: [UserShelterBadge] = try await supabase
            .from("user_shelter_badges")
            .select()
            .eq("user_id", value: currentUser.id)
            .eq("badge_id", value: badgeId)
            .limit(1)
            .execute()
            .value

        return !badges.isEmpty
    }

    /// Gets all unlocked badges for the current user
    /// - Returns: Array of UserShelterBadge records
    func getUnlockedBadges() async throws -> [UserShelterBadge] {
        let currentUser = try await supabase.auth.session.user

        let badges: [UserShelterBadge] = try await supabase
            .from("user_shelter_badges")
            .select()
            .eq("user_id", value: currentUser.id)
            .order("created_at", ascending: false)
            .execute()
            .value

        return badges
    }

    // MARK: - Badge Collection Statistics

    /// Gets badge statistics for the current user
    /// - Returns: Tuple with total badges and unlocked count
    func getBadgeStats() async throws -> (total: Int, unlocked: Int) {
        let badges = try await getUserBadges()
        let unlockedCount = badges.filter { $0.isUnlocked }.count

        return (total: badges.count, unlocked: unlockedCount)
    }

    /// Gets the percentage of badges collected
    /// - Returns: Percentage as a Double (0.0 to 1.0)
    func getBadgeCompletionPercentage() async throws -> Double {
        let stats = try await getBadgeStats()
        guard stats.total > 0 else { return 0.0 }

        return Double(stats.unlocked) / Double(stats.total)
    }

    // MARK: - Auto Badge Generation

    /// Handles badge logic when user visits a shelter
    /// Creates badge if user is first, unlocks badge for current user
    /// Call this when a user completes a mission at a shelter
    /// - Parameters:
    ///   - shelterId: The shelter UUID
    ///   - shelter: Optional shelter object (to avoid extra fetch)
    /// - Returns: Tuple with created badge (if first) and unlock status
    @discardableResult
    func handleShelterVisit(
        shelterId: UUID,
        shelter: Shelter? = nil
    ) async throws -> (createdBadge: ShelterBadge?, wasFirstVisitor: Bool) {
        let currentUser = try await supabase.auth.session.user
        var createdBadge: ShelterBadge? = nil
        var wasFirstVisitor = false

        // Check if badge already exists for this shelter
        if try await badgeExists(forShelter: shelterId) {
            // Badge exists, just unlock it for the user
            let existingBadges = try await getBadgesForShelter(shelterId: shelterId)
            if let badge = existingBadges.first {
                // Try to unlock (will skip if already unlocked)
                try? await unlockBadge(badgeId: badge.id)
            }
            debugPrint("ℹ️ Badge already exists for shelter: \(shelterId)")
        } else {
            // User is the first visitor! Create a badge
            wasFirstVisitor = true

            // Fetch shelter if not provided
            let shelterData: Shelter
            if let providedShelter = shelter {
                shelterData = providedShelter
            } else {
                shelterData = try await supabase
                    .from("shelters")
                    .select()
                    .eq("id", value: shelterId)
                    .single()
                    .execute()
                    .value
            }

            let badgeName = generateBadgeName(for: shelterData)

            createdBadge = try await createShelterBadge(
                badgeName: badgeName,
                shelterId: shelterId,
                firstUserId: currentUser.id
            )

            // Unlock the badge for the user
            if let badge = createdBadge {
                try await unlockBadge(badgeId: badge.id)
            }
        }

        return (createdBadge, wasFirstVisitor)
    }

    /// Automatically creates a badge for a shelter if it doesn't exist and user is first visitor
    /// Call this when a user completes a mission at a shelter
    /// - Parameters:
    ///   - shelterId: The shelter UUID
    ///   - shelter: Optional shelter object (to avoid extra fetch)
    /// - Returns: The created badge if user was first, nil otherwise
    @discardableResult
    func checkAndCreateBadge(
        forShelter shelterId: UUID,
        shelter: Shelter? = nil
    ) async throws -> ShelterBadge? {
        let result = try await handleShelterVisit(shelterId: shelterId, shelter: shelter)
        return result.createdBadge
    }
}

// MARK: - Error Handling

extension BadgeService {
    enum BadgeServiceError: LocalizedError {
        case userNotAuthenticated
        case badgeNotFound
        case shelterNotFound
        case badgeAlreadyUnlocked
        case databaseError(String)

        var errorDescription: String? {
            switch self {
            case .userNotAuthenticated:
                return "User is not authenticated"
            case .badgeNotFound:
                return "Badge not found"
            case .shelterNotFound:
                return "Shelter not found"
            case .badgeAlreadyUnlocked:
                return "Badge is already unlocked"
            case .databaseError(let message):
                return "Database error: \(message)"
            }
        }
    }
}
