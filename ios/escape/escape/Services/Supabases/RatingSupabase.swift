//
//  RatingSupabase.swift
//  escape
//
//  Created for shelter rating and review system
//

import Foundation
import Supabase

class RatingSupabase {
    // MARK: - Fetch Ratings

    /// Fetches all ratings for a specific shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: Array of ShelterRating objects ordered by creation date (newest first)
    func getRatingsForShelter(shelterId: UUID) async throws -> [ShelterRating] {
        let ratings: [ShelterRating] = try await supabase
            .from("shelter_ratings")
            .select()
            .eq("shelter_id", value: shelterId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return ratings
    }

    /// Fetches all ratings for a specific shelter with user information
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: Array of ShelterRatingWithUser objects with joined user data
    func getRatingsWithUsersForShelter(shelterId: UUID) async throws -> [ShelterRatingWithUser] {
        // Step 1: Fetch all ratings for the shelter
        let ratings = try await getRatingsForShelter(shelterId: shelterId)

        // Step 2: For each rating, fetch the corresponding user information
        var result: [ShelterRatingWithUser] = []

        for rating in ratings {
            // Fetch the user who created this rating
            let user: User? = try? await supabase
                .from("users")
                .select()
                .eq("id", value: rating.userId)
                .single()
                .execute()
                .value

            // Combine into ShelterRatingWithUser
            let combined = ShelterRatingWithUser(
                rating: rating,
                user: user
            )

            result.append(combined)
        }

        return result
    }

    /// Fetches the current user's rating for a specific shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: ShelterRating if exists, nil otherwise
    func getUserRatingForShelter(shelterId: UUID) async throws -> ShelterRating? {
        let currentUser = try await supabase.auth.session.user

        let ratings: [ShelterRating] = try await supabase
            .from("shelter_ratings")
            .select()
            .eq("shelter_id", value: shelterId)
            .eq("user_id", value: currentUser.id)
            .limit(1)
            .execute()
            .value

        return ratings.first
    }

    /// Fetches all ratings created by the current user
    /// - Returns: Array of ShelterRating objects ordered by creation date (newest first)
    func getCurrentUserRatings() async throws -> [ShelterRating] {
        let currentUser = try await supabase.auth.session.user

        let ratings: [ShelterRating] = try await supabase
            .from("shelter_ratings")
            .select()
            .eq("user_id", value: currentUser.id)
            .order("created_at", ascending: false)
            .execute()
            .value

        return ratings
    }

    // MARK: - Rating Statistics

    /// Gets the average rating and total count for a shelter using the database function
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: ShelterRatingSummary with average rating and count
    func getRatingSummaryForShelter(shelterId: UUID) async throws -> ShelterRatingSummary {
        // Call the database function get_shelter_rating_summary
        struct RawSummary: Codable {
            let averageRating: Double
            let totalRatings: Int

            enum CodingKeys: String, CodingKey {
                case averageRating = "average_rating"
                case totalRatings = "total_ratings"
            }
        }

        let result: [RawSummary] = try await supabase
            .rpc("get_shelter_rating_summary", params: ["shelter_uuid": shelterId.uuidString])
            .execute()
            .value

        guard let summary = result.first else {
            // Return empty summary if no ratings
            return ShelterRatingSummary(averageRating: 0.0, totalRatings: 0)
        }

        return ShelterRatingSummary(
            averageRating: summary.averageRating,
            totalRatings: summary.totalRatings
        )
    }

    /// Gets rating summaries for multiple shelters at once (for map display)
    /// - Parameter shelterIds: Array of shelter UUIDs
    /// - Returns: Dictionary mapping shelter ID to rating summary
    func getRatingSummariesForShelters(shelterIds: [UUID]) async throws -> [UUID: ShelterRatingSummary]
    {
        var summaries: [UUID: ShelterRatingSummary] = [:]

        // Fetch summaries for each shelter
        // Note: This could be optimized with a custom database function if needed
        for shelterId in shelterIds {
            if let summary = try? await getRatingSummaryForShelter(shelterId: shelterId) {
                summaries[shelterId] = summary
            }
        }

        return summaries
    }

    // MARK: - Create & Update Ratings

    /// Creates a new rating for a shelter
    /// Note: User must have the badge for this shelter (enforced by RLS policy)
    /// - Parameters:
    ///   - shelterId: The shelter UUID
    ///   - rating: Star rating (1-5)
    ///   - review: Optional review text (max 500 characters)
    /// - Returns: The created ShelterRating
    /// - Throws: ValidationError if data is invalid, or database error if RLS policy fails
    @discardableResult
    func createRating(
        shelterId: UUID,
        rating: Int,
        review: String?
    ) async throws -> ShelterRating {
        let currentUser = try await supabase.auth.session.user

        // Create request and validate
        let request = UpsertRatingRequest(
            shelterId: shelterId,
            userId: currentUser.id,
            rating: rating,
            review: review
        )

        try request.validate()

        // Insert into database
        let createdRating: ShelterRating = try await supabase
            .from("shelter_ratings")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        debugPrint("✅ Created rating for shelter: \(shelterId), rating: \(rating) stars")
        return createdRating
    }

    /// Updates an existing rating for a shelter
    /// Note: User must own the rating and still have the badge (enforced by RLS policy)
    /// - Parameters:
    ///   - ratingId: The rating UUID to update
    ///   - rating: New star rating (1-5)
    ///   - review: New review text (max 500 characters)
    /// - Returns: The updated ShelterRating
    /// - Throws: ValidationError if data is invalid, or database error if RLS policy fails
    @discardableResult
    func updateRating(
        ratingId: UUID,
        rating: Int,
        review: String?
    ) async throws -> ShelterRating {
        let currentUser = try await supabase.auth.session.user

        // Validate the new rating data
        let request = UpsertRatingRequest(
            shelterId: UUID(),  // Not needed for update, just for validation
            userId: currentUser.id,
            rating: rating,
            review: review
        )

        try request.validate()

        // Create update request with proper types
        struct UpdateRequest: Encodable {
            let rating: Int
            let review: String?
        }

        let updateRequest = UpdateRequest(rating: rating, review: review)

        // Update the rating
        let updatedRating: ShelterRating = try await supabase
            .from("shelter_ratings")
            .update(updateRequest)
            .eq("id", value: ratingId)
            .select()
            .single()
            .execute()
            .value

        debugPrint("✅ Updated rating: \(ratingId), new rating: \(rating) stars")
        return updatedRating
    }

    /// Creates or updates a rating for a shelter (upsert operation)
    /// - Parameters:
    ///   - shelterId: The shelter UUID
    ///   - rating: Star rating (1-5)
    ///   - review: Optional review text (max 500 characters)
    /// - Returns: The created or updated ShelterRating
    @discardableResult
    func upsertRating(
        shelterId: UUID,
        rating: Int,
        review: String?
    ) async throws -> ShelterRating {
        // Check if user already has a rating for this shelter
        if let existingRating = try await getUserRatingForShelter(shelterId: shelterId) {
            // Update existing rating
            return try await updateRating(
                ratingId: existingRating.id,
                rating: rating,
                review: review
            )
        } else {
            // Create new rating
            return try await createRating(
                shelterId: shelterId,
                rating: rating,
                review: review
            )
        }
    }

    // MARK: - Delete Ratings

    /// Deletes a rating
    /// Note: User must own the rating (enforced by RLS policy)
    /// - Parameter ratingId: The rating UUID to delete
    func deleteRating(ratingId: UUID) async throws {
        try await supabase
            .from("shelter_ratings")
            .delete()
            .eq("id", value: ratingId)
            .execute()

        debugPrint("✅ Deleted rating: \(ratingId)")
    }

    /// Deletes the current user's rating for a specific shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: True if rating was deleted, false if no rating existed
    @discardableResult
    func deleteUserRatingForShelter(shelterId: UUID) async throws -> Bool {
        guard let rating = try await getUserRatingForShelter(shelterId: shelterId) else {
            return false
        }

        try await deleteRating(ratingId: rating.id)
        return true
    }

    // MARK: - Authorization Checks

    /// Checks if the current user can rate a specific shelter
    /// User can rate if they have collected the badge for that shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: True if user can rate, false otherwise
    func canUserRateShelter(shelterId: UUID) async throws -> Bool {
        let currentUser = try await supabase.auth.session.user

        debugPrint("🔍 Checking if user can rate shelter:")
        debugPrint("   User ID: \(currentUser.id)")
        debugPrint("   Shelter ID: \(shelterId)")

        // Call the database function user_can_rate_shelter
        let result: [Bool] = try await supabase
            .rpc(
                "user_can_rate_shelter",
                params: [
                    "user_uuid": currentUser.id.uuidString,
                    "shelter_uuid": shelterId.uuidString,
                ]
            )
            .execute()
            .value

        debugPrint("   Can rate result: \(result.first ?? false)")
        return result.first ?? false
    }

    /// Checks the current user's rating status for a shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: CanRateShelterResponse with detailed authorization info
    func checkUserRatingStatus(shelterId: UUID) async throws -> CanRateShelterResponse {
        // Check if user has badge
        let hasBadge = try await canUserRateShelter(shelterId: shelterId)

        // Check if user has existing rating
        let hasExistingRating = try await getUserRatingForShelter(shelterId: shelterId) != nil

        // User can rate if they have badge
        let canRate = hasBadge

        return CanRateShelterResponse(
            canRate: canRate,
            hasBadge: hasBadge,
            hasExistingRating: hasExistingRating
        )
    }

    // MARK: - Convenience Methods

    /// Checks if the current user has rated a specific shelter
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: True if user has rated, false otherwise
    func hasUserRatedShelter(shelterId: UUID) async throws -> Bool {
        let rating = try await getUserRatingForShelter(shelterId: shelterId)
        return rating != nil
    }

    /// Gets the count of ratings for a shelter (quick method without full summary)
    /// - Parameter shelterId: The shelter UUID
    /// - Returns: Number of ratings
    func getRatingCountForShelter(shelterId: UUID) async throws -> Int {
        let summary = try await getRatingSummaryForShelter(shelterId: shelterId)
        return summary.totalRatings
    }

    /// Gets all shelters that the current user has rated
    /// - Returns: Array of shelter UUIDs
    func getSheltersRatedByCurrentUser() async throws -> [UUID] {
        let ratings = try await getCurrentUserRatings()
        return ratings.map { $0.shelterId }
    }
}

// MARK: - Error Handling

extension RatingSupabase {
    enum RatingServiceError: LocalizedError {
        case userNotAuthenticated
        case ratingNotFound
        case shelterNotFound
        case userCannotRate
        case invalidRating
        case reviewTooLong
        case databaseError(String)

        var errorDescription: String? {
            switch self {
            case .userNotAuthenticated:
                return String(
                    localized: "rating.error.not_authenticated",
                    defaultValue: "User is not authenticated",
                    table: "Localizable"
                )
            case .ratingNotFound:
                return String(
                    localized: "rating.error.not_found",
                    defaultValue: "Rating not found",
                    table: "Localizable"
                )
            case .shelterNotFound:
                return String(
                    localized: "rating.error.shelter_not_found",
                    defaultValue: "Shelter not found",
                    table: "Localizable"
                )
            case .userCannotRate:
                return String(
                    localized: "rating.error.cannot_rate",
                    defaultValue:
                        "You must visit this shelter and collect its badge before rating",
                    table: "Localizable"
                )
            case .invalidRating:
                return String(
                    localized: "rating.error.invalid_rating",
                    defaultValue: "Rating must be between 1 and 5 stars",
                    table: "Localizable"
                )
            case .reviewTooLong:
                return String(
                    localized: "rating.error.review_too_long",
                    defaultValue: "Review must be 500 characters or less",
                    table: "Localizable"
                )
            case let .databaseError(message):
                return String(
                    localized: "rating.error.database",
                    defaultValue: "Database error: \(message)",
                    table: "Localizable"
                )
            }
        }
    }
}
