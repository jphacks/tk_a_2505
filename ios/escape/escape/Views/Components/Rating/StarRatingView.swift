//
//  StarRatingView.swift
//  escape
//
//  Created for shelter rating system
//

import SwiftUI

/// Reusable star rating view that can be used for both display and input
struct StarRatingView: View {
    // MARK: - Configuration

    /// The current rating value (can be decimal for display, e.g., 4.5)
    let rating: Double

    /// Maximum number of stars (default: 5)
    let maxRating: Int

    /// Whether the stars are tappable for user input
    let isInteractive: Bool

    /// Size of each star
    let starSize: CGFloat

    /// Spacing between stars
    let spacing: CGFloat

    /// Callback when user taps a star (only called if isInteractive = true)
    let onRatingChanged: ((Int) -> Void)?

    // MARK: - Initialization

    /// Creates a star rating view for display only
    /// - Parameters:
    ///   - rating: The rating to display (can be decimal, e.g., 4.5)
    ///   - maxRating: Maximum number of stars (default: 5)
    ///   - starSize: Size of each star (default: 20)
    ///   - spacing: Spacing between stars (default: 4)
    init(
        rating: Double,
        maxRating: Int = 5,
        starSize: CGFloat = 20,
        spacing: CGFloat = 4
    ) {
        self.rating = rating
        self.maxRating = maxRating
        isInteractive = false
        self.starSize = starSize
        self.spacing = spacing
        onRatingChanged = nil
    }

    /// Creates a star rating view for user input
    /// - Parameters:
    ///   - rating: The current selected rating (integer for input)
    ///   - maxRating: Maximum number of stars (default: 5)
    ///   - starSize: Size of each star (default: 30)
    ///   - spacing: Spacing between stars (default: 8)
    ///   - onRatingChanged: Callback when user taps a star
    init(
        rating: Int,
        maxRating: Int = 5,
        starSize: CGFloat = 30,
        spacing: CGFloat = 8,
        onRatingChanged: @escaping (Int) -> Void
    ) {
        self.rating = Double(rating)
        self.maxRating = maxRating
        isInteractive = true
        self.starSize = starSize
        self.spacing = spacing
        self.onRatingChanged = onRatingChanged
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1 ... maxRating, id: \.self) { index in
                starView(for: index)
                    .onTapGesture {
                        if isInteractive {
                            onRatingChanged?(index)
                        }
                    }
            }
        }
    }

    // MARK: - Star View

    @ViewBuilder
    private func starView(for index: Int) -> some View {
        let starState = getStarState(for: index)

        Image(systemName: starState.symbolName)
            .font(.system(size: starSize))
            .foregroundColor(starState.color)
            .symbolRenderingMode(.hierarchical)
    }

    // MARK: - Star State

    private func getStarState(for index: Int) -> StarState {
        let threshold = Double(index)

        if rating >= threshold {
            // Full star
            return StarState(symbolName: "star.fill", color: .yellow)
        } else if rating >= threshold - 0.5 {
            // Half star (only for display mode)
            return isInteractive
                ? StarState(symbolName: "star", color: .gray)
                : StarState(symbolName: "star.leadinghalf.filled", color: .yellow)
        } else {
            // Empty star
            return StarState(symbolName: "star", color: .gray)
        }
    }

    private struct StarState {
        let symbolName: String
        let color: Color
    }
}

// MARK: - Convenience Initializers

extension StarRatingView {
    /// Creates a compact star rating view for list displays
    static func compact(rating: Double) -> StarRatingView {
        StarRatingView(rating: rating, starSize: 14, spacing: 2)
    }

    /// Creates a medium star rating view for cards
    static func medium(rating: Double) -> StarRatingView {
        StarRatingView(rating: rating, starSize: 18, spacing: 4)
    }

    /// Creates a large star rating view for headers
    static func large(rating: Double) -> StarRatingView {
        StarRatingView(rating: rating, starSize: 24, spacing: 6)
    }
}

// MARK: - Preview

#Preview("Display Mode") {
    VStack(spacing: 20) {
        VStack(alignment: .leading) {
            Text("Integer Ratings")
                .font(.headline)
            StarRatingView(rating: 5)
            StarRatingView(rating: 4)
            StarRatingView(rating: 3)
            StarRatingView(rating: 2)
            StarRatingView(rating: 1)
        }

        VStack(alignment: .leading) {
            Text("Decimal Ratings (Half Stars)")
                .font(.headline)
            StarRatingView(rating: 4.5)
            StarRatingView(rating: 3.7)
            StarRatingView(rating: 2.3)
        }

        VStack(alignment: .leading) {
            Text("Sizes")
                .font(.headline)
            StarRatingView.compact(rating: 4.5)
            StarRatingView.medium(rating: 4.5)
            StarRatingView.large(rating: 4.5)
        }
    }
    .padding()
}

#Preview("Interactive Mode") {
    struct InteractivePreview: View {
        @State private var rating = 0

        var body: some View {
            VStack(spacing: 20) {
                Text("Tap a star to rate")
                    .font(.headline)

                StarRatingView(
                    rating: rating,
                    onRatingChanged: { newRating in
                        rating = newRating
                    }
                )

                Text("Current rating: \(rating)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }

    return InteractivePreview()
}
