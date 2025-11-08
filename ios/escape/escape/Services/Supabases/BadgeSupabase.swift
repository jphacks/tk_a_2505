//
//  BadgeSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import Supabase

class BadgeSupabase {
    // MARK: - Fetch Badges

    /// Fetches all shelter badges with unlock status for the current user
    /// - Returns: Array of Badge objects for UI display (simplified - doesn't include full shelter details)
    /// - Note: For badges with full shelter details, use getUserCollectedBadgesWithDetails()
    func getUserBadges() async throws -> [Badge] {
        // For now, delegate to the more comprehensive method and convert
        let collectedBadges = try await getUserCollectedBadgesWithDetails()
        return collectedBadges.map { $0.toBadge() }
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

            // Fetch the first user information
            let firstUser: User? = try? await supabase
                .from("users")
                .select()
                .eq("id", value: shelterBadge.firstUserId.uuidString)
                .single()
                .execute()
                .value

            // Combine into UserBadgeWithShelter
            let combined = UserBadgeWithShelter(
                userBadgeInfo: userBadge,
                shelterBadgeInfo: shelterBadge,
                shelterInfo: shelter,
                firstUser: firstUser
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

    /// Fetches the badge for a specific shelter
    /// Note: Each shelter has exactly one badge (1:1 relationship)
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: The shelter badge, or nil if not found
    func getBadgeForShelter(shelterId: UUID) async throws -> ShelterBadge? {
        let badges: [ShelterBadge] = try await supabase
            .from("shelter_badges")
            .select()
            .eq("shelter_id", value: shelterId)
            .limit(1)
            .execute()
            .value

        return badges.first
    }

    /// Batch fetches badge image URLs for multiple badge IDs
    /// - Parameter badgeIds: Array of badge UUIDs to fetch URLs for
    /// - Returns: Dictionary mapping badge ID (as String) to image URL
    /// - Note: Uses efficient batch query to prevent N+1 problem
    func getBadgeUrls(badgeIds: [UUID]) async throws -> [String: String] {
        guard !badgeIds.isEmpty else {
            return [:]
        }

        // Convert UUIDs to strings for query
        let badgeIdStrings = badgeIds.map { $0.uuidString.lowercased() }

        // Batch fetch badge names using .in() query
        struct BadgeQuery: Decodable {
            let id: String
            let badgeName: String

            enum CodingKeys: String, CodingKey {
                case id
                case badgeName = "badge_name"
            }
        }

        let badges: [BadgeQuery] = try await supabase
            .from("shelter_badges")
            .select("id,badge_name")
            .in("id", values: badgeIdStrings)
            .execute()
            .value

        // Build badge URL dictionary
        var badgeUrlDict: [String: String] = [:]
        let baseUrl = "https://wmmddehrriniwxsgnwqy.supabase.co/storage/v1/object/public/shelter_badges"
        for badge in badges {
            badgeUrlDict[badge.id] = "\(baseUrl)/\(badge.badgeName)"
        }

        return badgeUrlDict
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
        if let existingBadge = try await getBadgeForShelter(shelterId: shelterId) {
            // Badge exists, just unlock it for the user
            // Try to unlock (will skip if already unlocked)
            do {
                _ = try await unlockBadge(badgeId: existingBadge.id)
            } catch {
                debugPrint("❌ Failed to unlock existing badge: \(error)")
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

extension BadgeSupabase {
    /// Fetches user's collected badges by user ID
    /// - Parameter userId: The user's UUID
    /// - Returns: Array of UserShelterBadge objects
    func fetchUserBadges(userId: UUID) async throws -> [UserShelterBadge] {
        let userBadges: [UserShelterBadge] = try await supabase
            .from("user_shelter_badges")
            .select()
            .eq("user_id", value: userId.uuidString.lowercased())
            .order("created_at", ascending: false)
            .execute()
            .value

        return userBadges
    }

    /// Fetches badges by their IDs and converts them to Badge UI models
    /// - Parameter badgeIds: Array of badge UUIDs
    /// - Returns: Array of Badge objects for UI display
    func fetchBadgesByIds(_ badgeIds: [UUID]) async throws -> [Badge] {
        guard !badgeIds.isEmpty else { return [] }

        var badges: [Badge] = []

        for badgeId in badgeIds {
            do {
                // Fetch the shelter badge
                let shelterBadge: ShelterBadge = try await supabase
                    .from("shelter_badges")
                    .select()
                    .eq("id", value: badgeId.uuidString.lowercased())
                    .single()
                    .execute()
                    .value

                // Fetch the shelter information
                let shelter: Shelter = try await supabase
                    .from("shelters")
                    .select()
                    .eq("id", value: shelterBadge.shelterId.uuidString.lowercased())
                    .single()
                    .execute()
                    .value

                // Create Badge UI model
                let badge = Badge(
                    id: shelterBadge.id.uuidString,
                    name: shelter.name,
                    icon: shelterBadge.determineIcon(),
                    color: shelterBadge.determineColor(),
                    isUnlocked: true,
                    imageName: nil,
                    imageUrl: shelterBadge.getImageUrl(),
                    badgeNumber: shelter.number?.description,
                    address: shelter.address,
                    municipality: shelter.municipality,
                    isShelter: shelter.isShelter ?? false,
                    isFlood: shelter.isFlood ?? false,
                    isLandslide: shelter.isLandslide ?? false,
                    isStormSurge: shelter.isStormSurge ?? false,
                    isEarthquake: shelter.isEarthquake ?? false,
                    isTsunami: shelter.isTsunami ?? false,
                    isFire: shelter.isFire ?? false,
                    isInlandFlood: shelter.isInlandFlood ?? false,
                    isVolcano: shelter.isVolcano ?? false,
                    latitude: shelter.latitude,
                    longitude: shelter.longitude,
                    firstUserName: nil
                )

                badges.append(badge)
            } catch {
                print("⚠️ Failed to fetch badge \(badgeId): \(error)")
                // Continue to next badge instead of failing completely
                continue
            }
        }

        return badges
    }

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
            case let .databaseError(message):
                return "Database error: \(message)"
            }
        }
    }
}
