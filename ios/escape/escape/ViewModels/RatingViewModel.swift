//
//  RatingViewModel.swift
//  escape
//
//  Created for shelter rating and review system
//

import Foundation
import SwiftUI

@MainActor
@Observable
class RatingViewModel {
    // MARK: - Published State

    // Ratings data
    var ratings: [ShelterRatingWithUser] = []
    var ratingSummary: ShelterRatingSummary?
    var userRating: ShelterRating?

    // Loading states
    var isLoadingRatings = false
    var isSubmitting = false
    var isDeleting = false

    // Error handling
    var errorMessage: String?
    var successMessage: String?

    // Authorization
    var canRate = false
    var hasBadge = false
    var hasExistingRating = false

    // Current context
    var currentShelterId: UUID?

    // Form state
    var formState = RatingFormState()

    // MARK: - Dependencies

    private let ratingService: RatingSupabase
    private let badgeService: BadgeSupabase

    // MARK: - Initialization

    init(
        ratingService: RatingSupabase = RatingSupabase(),
        badgeService: BadgeSupabase = BadgeSupabase()
    ) {
        self.ratingService = ratingService
        self.badgeService = badgeService
    }

    // MARK: - Load Data

    /// Loads all ratings for a specific shelter with user information
    /// - Parameter shelterId: The shelter UUID
    func loadRatings(for shelterId: UUID) async {
        isLoadingRatings = true
        errorMessage = nil
        defer { isLoadingRatings = false }

        do {
            // Load rating summary
            ratingSummary = try await ratingService.getRatingSummaryForShelter(shelterId: shelterId)

            // Load all ratings with user info
            ratings = try await ratingService.getRatingsWithUsersForShelter(shelterId: shelterId)

            debugPrint(
                "✅ Loaded \(ratings.count) ratings for shelter: \(shelterId), avg: \(ratingSummary?.averageRating ?? 0)"
            )
        } catch {
            errorMessage = "Failed to load ratings"
            debugPrint("❌ Error loading ratings: \(error)")
        }
    }

    /// Loads the current user's rating for a specific shelter
    /// - Parameter shelterId: The shelter UUID
    func loadUserRating(for shelterId: UUID) async {
        currentShelterId = shelterId

        do {
            userRating = try await ratingService.getUserRatingForShelter(shelterId: shelterId)

            // Populate form if user has existing rating
            if let rating = userRating {
                formState.rating = rating.rating
                formState.review = rating.review ?? ""
            }

            debugPrint("✅ Loaded user rating: \(userRating != nil ? "exists" : "none")")
        } catch {
            debugPrint("❌ Error loading user rating: \(error)")
        }
    }

    /// Checks if the current user can rate a specific shelter
    /// - Parameter shelterId: The shelter UUID
    func checkRatingPermission(for shelterId: UUID) async {
        currentShelterId = shelterId

        do {
            let status = try await ratingService.checkUserRatingStatus(shelterId: shelterId)

            canRate = status.canRate
            hasBadge = status.hasBadge
            hasExistingRating = status.hasExistingRating

            debugPrint(
                "✅ Rating permission check: canRate=\(canRate), hasBadge=\(hasBadge), hasExisting=\(hasExistingRating)"
            )
        } catch {
            canRate = false
            hasBadge = false
            hasExistingRating = false
            debugPrint("❌ Error checking rating permission: \(error)")
        }
    }

    /// Loads all data needed for a shelter detail view
    /// Combines loading ratings, user rating, and permission check
    /// - Parameter shelterId: The shelter UUID
    func loadAllData(for shelterId: UUID) async {
        currentShelterId = shelterId

        // Load all data concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRatings(for: shelterId) }
            group.addTask { await self.loadUserRating(for: shelterId) }
            group.addTask { await self.checkRatingPermission(for: shelterId) }
        }
    }

    // MARK: - Submit Rating

    /// Submits a new rating or updates existing one
    /// - Parameters:
    ///   - shelterId: The shelter UUID (optional if already set)
    ///   - stars: Star rating (1-5)
    ///   - reviewText: Optional review text
    func submitRating(shelterId: UUID? = nil, stars: Int? = nil, reviewText: String? = nil)
        async
    {
        guard let targetShelterId = shelterId ?? currentShelterId else {
            errorMessage = "No shelter selected"
            return
        }

        // Use form state if parameters not provided
        let finalStars = stars ?? formState.rating
        let finalReview = reviewText ?? (formState.review.isEmpty ? nil : formState.review)

        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        defer { isSubmitting = false }

        do {
            // Validate form
            guard formState.isValid else {
                errorMessage = "Please select a rating between 1 and 5 stars"
                return
            }

            if formState.isReviewTooLong {
                errorMessage = "Review must be 500 characters or less"
                return
            }

            // Submit rating (creates or updates automatically)
            let submittedRating = try await ratingService.upsertRating(
                shelterId: targetShelterId,
                rating: finalStars,
                review: finalReview
            )

            userRating = submittedRating
            hasExistingRating = true

            successMessage = hasExistingRating
                ? String(localized: "rating.success.updated", defaultValue: "Rating updated!", table: "Localizable")
                : String(localized: "rating.success.created", defaultValue: "Rating submitted!", table: "Localizable")

            debugPrint("✅ Rating submitted: \(finalStars) stars")

            // Reload ratings to show updated data
            await loadRatings(for: targetShelterId)

        } catch let error as UpsertRatingRequest.ValidationError {
            errorMessage = error.localizedDescription
            debugPrint("❌ Validation error: \(error)")
        } catch {
            errorMessage = String(
                localized: "rating.error.submit_failed",
                defaultValue: "Failed to submit rating. Please try again.",
                table: "Localizable"
            )
            debugPrint("❌ Error submitting rating: \(error)")
        }
    }

    // MARK: - Delete Rating

    /// Deletes the current user's rating for the current shelter
    func deleteUserRating() async {
        guard let shelterId = currentShelterId else {
            errorMessage = "No shelter selected"
            return
        }

        isDeleting = true
        errorMessage = nil
        successMessage = nil
        defer { isDeleting = false }

        do {
            let wasDeleted = try await ratingService.deleteUserRatingForShelter(shelterId: shelterId)

            if wasDeleted {
                userRating = nil
                hasExistingRating = false
                formState.reset()

                successMessage = String(
                    localized: "rating.success.deleted",
                    defaultValue: "Rating deleted",
                    table: "Localizable"
                )

                debugPrint("✅ Rating deleted for shelter: \(shelterId)")

                // Reload ratings to show updated data
                await loadRatings(for: shelterId)
            } else {
                errorMessage = "No rating found to delete"
            }
        } catch {
            errorMessage = String(
                localized: "rating.error.delete_failed",
                defaultValue: "Failed to delete rating. Please try again.",
                table: "Localizable"
            )
            debugPrint("❌ Error deleting rating: \(error)")
        }
    }

    /// Deletes a specific rating by ID
    /// - Parameter ratingId: The rating UUID to delete
    func deleteRating(ratingId: UUID) async {
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await ratingService.deleteRating(ratingId: ratingId)

            // If this was the user's rating, clear it
            if userRating?.id == ratingId {
                userRating = nil
                hasExistingRating = false
                formState.reset()
            }

            successMessage = "Rating deleted"

            // Reload ratings
            if let shelterId = currentShelterId {
                await loadRatings(for: shelterId)
            }
        } catch {
            errorMessage = "Failed to delete rating"
            debugPrint("❌ Error deleting rating: \(error)")
        }
    }

    // MARK: - Form Management

    /// Prepares the form for editing an existing rating
    func startEditingRating() {
        guard let rating = userRating else { return }

        formState.rating = rating.rating
        formState.review = rating.review ?? ""

        debugPrint("📝 Started editing rating")
    }

    /// Resets the form to empty state
    func resetForm() {
        formState.reset()
    }

    /// Clears error and success messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Utility Methods

    /// Gets display text for authorization status
    var permissionMessage: String {
        if !hasBadge {
            return String(
                localized: "rating.permission.no_badge",
                defaultValue: "Visit this shelter and collect its badge to leave a rating",
                table: "Localizable"
            )
        } else if hasExistingRating {
            return String(
                localized: "rating.permission.has_rating",
                defaultValue: "You have rated this shelter",
                table: "Localizable"
            )
        } else {
            return String(
                localized: "rating.permission.can_rate",
                defaultValue: "You can rate this shelter!",
                table: "Localizable"
            )
        }
    }

    /// Returns true if the form has unsaved changes
    var hasUnsavedChanges: Bool {
        guard let existingRating = userRating else {
            // No existing rating - check if form has data
            return formState.rating > 0 || !formState.review.isEmpty
        }

        // Has existing rating - check if form differs
        return formState.rating != existingRating.rating
            || formState.review != (existingRating.review ?? "")
    }

    /// Returns the appropriate button text based on state
    var submitButtonText: String {
        if isSubmitting {
            return String(
                localized: "rating.button.submitting",
                defaultValue: "Submitting...",
                table: "Localizable"
            )
        } else if hasExistingRating {
            return String(
                localized: "rating.button.update",
                defaultValue: "Update Rating",
                table: "Localizable"
            )
        } else {
            return String(
                localized: "rating.button.submit",
                defaultValue: "Submit Rating",
                table: "Localizable"
            )
        }
    }

    /// Returns true if submit button should be enabled
    var canSubmit: Bool {
        !isSubmitting
            && formState.isValid
            && !formState.isReviewTooLong
            && hasUnsavedChanges
    }

    // MARK: - Statistics

    /// Gets the total number of ratings across all shelters by current user
    func getUserTotalRatingCount() async -> Int {
        do {
            let ratings = try await ratingService.getCurrentUserRatings()
            return ratings.count
        } catch {
            debugPrint("❌ Error getting user rating count: \(error)")
            return 0
        }
    }

    /// Gets all shelters rated by the current user
    func getUserRatedShelters() async -> [UUID] {
        do {
            return try await ratingService.getSheltersRatedByCurrentUser()
        } catch {
            debugPrint("❌ Error getting rated shelters: \(error)")
            return []
        }
    }
}
