//
//  ShelterRatingModel.swift
//  escape
//
//  Created for shelter rating and review system
//

import Foundation

// MARK: - Database Model

/// Represents a user's rating and review for a shelter from the shelter_ratings table
struct ShelterRating: Codable, Identifiable {
    let id: UUID
    let shelterId: UUID
    let userId: UUID
    let rating: Int  // 1-5 stars
    let review: String?  // Optional review text (max 500 chars)
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case shelterId = "shelter_id"
        case userId = "user_id"
        case rating
        case review
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Helper Extensions

extension ShelterRating {
    /// Returns true if the rating has a review text
    var hasReview: Bool {
        review != nil && !(review?.isEmpty ?? true)
    }

    /// Returns a display-friendly date string for the rating
    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Returns true if the rating was edited (created_at != updated_at)
    var wasEdited: Bool {
        createdAt != updatedAt
    }

    /// Returns star rating as an array for easy UI rendering
    /// Example: rating = 4 returns [true, true, true, true, false]
    var starsArray: [Bool] {
        (1...5).map { $0 <= rating }
    }
}

// MARK: - Extended Model with User Information

/// Extended rating model that includes user information for display
struct ShelterRatingWithUser: Codable, Identifiable {
    let rating: ShelterRating
    let user: User?
    let userProfileBadgeImageUrl: String?

    var id: UUID {
        rating.id
    }

    /// Returns the user's display name or "Anonymous" if user data is missing
    var userName: String {
        user?.displayName ?? "Anonymous User"
    }

    /// Returns the user's profile badge ID for displaying their avatar
    var userProfileBadgeId: UUID? {
        user?.profileBadgeId
    }
}

// MARK: - Rating Summary Model

/// Represents aggregated rating statistics for a shelter
struct ShelterRatingSummary: Codable {
    let averageRating: Double
    let totalRatings: Int

    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case totalRatings = "total_ratings"
    }

    /// Returns true if the shelter has any ratings
    var hasRatings: Bool {
        totalRatings > 0
    }

    /// Returns a formatted string like "4.5 (23 reviews)"
    var displayText: String {
        let reviewsText = String(
            localized: "rating.reviews_count",
            defaultValue: "\(totalRatings) reviews",
            table: "Localizable"
        )
        return String(format: "%.1f (\(reviewsText))", averageRating)
    }

    /// Returns a short display text like "4.5 ★"
    var shortDisplayText: String {
        String(format: "%.1f ★", averageRating)
    }

    /// Returns star rating as an array for easy UI rendering
    /// Uses half-star logic for averages
    var starsArray: [StarState] {
        (1...5).map { index in
            let threshold = Double(index)
            if averageRating >= threshold {
                return .full
            } else if averageRating >= threshold - 0.5 {
                return .half
            } else {
                return .empty
            }
        }
    }

    /// Star state for rendering (full, half, or empty)
    enum StarState {
        case full
        case half
        case empty
    }
}

// MARK: - Request Models

/// Request model for creating or updating a rating
struct UpsertRatingRequest: Codable {
    let shelterId: UUID
    let userId: UUID
    let rating: Int
    let review: String?

    enum CodingKeys: String, CodingKey {
        case shelterId = "shelter_id"
        case userId = "user_id"
        case rating
        case review
    }

    /// Validates the rating data before submission
    func validate() throws {
        guard rating >= 1 && rating <= 5 else {
            throw ValidationError.invalidRating
        }

        if let reviewText = review, reviewText.count > 500 {
            throw ValidationError.reviewTooLong
        }
    }

    enum ValidationError: LocalizedError {
        case invalidRating
        case reviewTooLong

        var errorDescription: String? {
            switch self {
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
            }
        }
    }
}

// MARK: - Response Models

/// Response from checking if user can rate a shelter
struct CanRateShelterResponse: Codable {
    let canRate: Bool
    let hasBadge: Bool
    let hasExistingRating: Bool

    enum CodingKeys: String, CodingKey {
        case canRate = "can_rate"
        case hasBadge = "has_badge"
        case hasExistingRating = "has_existing_rating"
    }
}

// MARK: - UI Helper Models

/// UI state for rating form
struct RatingFormState {
    var rating: Int = 0
    var review: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    var isValid: Bool {
        rating >= 1 && rating <= 5
    }

    var characterCount: Int {
        review.count
    }

    var isReviewTooLong: Bool {
        characterCount > 500
    }

    mutating func reset() {
        rating = 0
        review = ""
        isSubmitting = false
        errorMessage = nil
    }
}
