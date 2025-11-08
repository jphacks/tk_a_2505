//
//  RatingCard.swift
//  escape
//
//  Created for shelter rating system
//

import SwiftUI

/// Displays an individual rating/review with user information
struct RatingCard: View {
    // MARK: - Properties

    let ratingWithUser: ShelterRatingWithUser
    let showDivider: Bool

    // MARK: - Initialization

    init(ratingWithUser: ShelterRatingWithUser, showDivider: Bool = true) {
        self.ratingWithUser = ratingWithUser
        self.showDivider = showDivider
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                UserAvatarView(
                    username: ratingWithUser.userName,
                    badgeImageUrl: ratingWithUser.userProfileBadgeImageUrl,
                    size: .small,
                    showLoadingIndicator: false
                )

                VStack(alignment: .leading, spacing: 8) {
                    // Header: User name and date
                    HStack {
                        Text(ratingWithUser.userName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(ratingWithUser.rating.displayDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Star rating
                    HStack(spacing: 4) {
                        StarRatingView.compact(rating: Double(ratingWithUser.rating.rating))

                        if ratingWithUser.rating.wasEdited {
                            Text("(edited)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Review text
                    if ratingWithUser.rating.hasReview {
                        Text(ratingWithUser.rating.review!)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 12)

            if showDivider {
                Divider()
            }
        }
    }
}

// MARK: - Loading State Card

struct RatingCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar skeleton
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 8) {
                    // Name skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 120, height: 16)

                    // Stars skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 14)

                    // Review skeleton
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 14)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 14)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 14)
                    }
                }
            }
            .padding(.vertical, 12)

            Divider()
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Empty State

struct RatingEmptyState: View {
    let message: String

    init(message: String = "No reviews yet. Be the first to review this shelter!") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview("Rating Cards") {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(0..<3) { index in
                RatingCard(
                    ratingWithUser: ShelterRatingWithUser(
                        rating: ShelterRating(
                            id: UUID(),
                            shelterId: UUID(),
                            userId: UUID(),
                            rating: 5 - index,
                            review: index == 0
                                ? "This shelter is very well maintained. Equipment is up to date and the facility is clean."
                                : index == 1
                                    ? "Good shelter but could use some improvements."
                                    : nil,
                            createdAt: Date().addingTimeInterval(-Double(index) * 86400),
                            updatedAt: Date().addingTimeInterval(-Double(index) * 86400)
                        ),
                        user: User(
                            id: UUID(),
                            createdAt: Date(),
                            name: "User \(index + 1)",
                            profileBadgeId: nil
                        ),
                        userProfileBadgeImageUrl: nil
                    )
                )
                .padding(.horizontal)
            }
        }
    }
}

#Preview("Loading State") {
    VStack(spacing: 0) {
        ForEach(0..<3) { _ in
            RatingCardSkeleton()
                .padding(.horizontal)
        }
    }
}

#Preview("Empty State") {
    RatingEmptyState()
}
