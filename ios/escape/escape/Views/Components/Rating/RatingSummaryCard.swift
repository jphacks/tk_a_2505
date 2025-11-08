//
//  RatingSummaryCard.swift
//  escape
//
//  Created for shelter rating system
//

import SwiftUI

/// Displays a summary of ratings for a shelter (average rating and total count)
struct RatingSummaryCard: View {
    // MARK: - Properties

    let summary: ShelterRatingSummary?
    let style: DisplayStyle

    // MARK: - Initialization

    init(summary: ShelterRatingSummary?, style: DisplayStyle = .full) {
        self.summary = summary
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        if let summary = summary, summary.hasRatings {
            switch style {
            case .compact:
                compactView(summary: summary)
            case .full:
                fullView(summary: summary)
            case .inline:
                inlineView(summary: summary)
            }
        } else {
            emptyView
        }
    }

    // MARK: - View Styles

    /// Compact view: just stars and count
    private func compactView(summary: ShelterRatingSummary) -> some View {
        HStack(spacing: 4) {
            StarRatingView.compact(rating: summary.averageRating)

            Text("(\(summary.totalRatings))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Full card view with detailed information
    private func fullView(summary: ShelterRatingSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("rating.ratings_and_reviews", tableName: "Localizable")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .center, spacing: 16) {
                // Large average rating number
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", summary.averageRating))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)

                    StarRatingView.medium(rating: summary.averageRating)
                }

                Divider()
                    .frame(height: 60)

                // Rating count
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(summary.totalRatings)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(summary.totalRatings == 1 ? String(localized: "rating.review_singular", table: "Localizable") : String(localized: "rating.review_plural", table: "Localizable"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    /// Inline view: horizontal layout
    private func inlineView(summary: ShelterRatingSummary) -> some View {
        HStack(spacing: 8) {
            Text(String(format: "%.1f", summary.averageRating))
                .font(.title3)
                .fontWeight(.semibold)

            StarRatingView.compact(rating: summary.averageRating)

            Text("(\(summary.totalRatings) \(summary.totalRatings == 1 ? String(localized: "rating.review_lowercase_singular", table: "Localizable") : String(localized: "rating.review_lowercase_plural", table: "Localizable")))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// Empty state when no ratings exist
    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("rating.no_reviews_yet", tableName: "Localizable")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("rating.be_first_to_review", tableName: "Localizable")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Display Style

    enum DisplayStyle {
        /// Just stars and count - minimal space
        case compact

        /// Full card with large numbers and details
        case full

        /// Horizontal inline layout for headers
        case inline
    }
}

// MARK: - Preview

#Preview("Full Style") {
    VStack(spacing: 20) {
        RatingSummaryCard(
            summary: ShelterRatingSummary(averageRating: 4.5, totalRatings: 23),
            style: .full
        )

        RatingSummaryCard(
            summary: ShelterRatingSummary(averageRating: 3.2, totalRatings: 7),
            style: .full
        )

        RatingSummaryCard(
            summary: ShelterRatingSummary(averageRating: 5.0, totalRatings: 1),
            style: .full
        )

        RatingSummaryCard(summary: nil, style: .full)
    }
    .padding()
}

#Preview("Compact & Inline Styles") {
    VStack(alignment: .leading, spacing: 20) {
        Text("Compact Style")
            .font(.headline)
        RatingSummaryCard(
            summary: ShelterRatingSummary(averageRating: 4.5, totalRatings: 23),
            style: .compact
        )

        Divider()

        Text("Inline Style")
            .font(.headline)
        RatingSummaryCard(
            summary: ShelterRatingSummary(averageRating: 4.5, totalRatings: 23),
            style: .inline
        )

        Divider()

        Text("Empty State")
            .font(.headline)
        RatingSummaryCard(summary: nil, style: .inline)
    }
    .padding()
}
