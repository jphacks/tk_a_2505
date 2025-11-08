//
//  ShelterReviewsView.swift
//  escape
//
//  Created for shelter rating system
//

import SwiftUI

/// Full-page view for displaying all reviews and rating form for a shelter
struct ShelterReviewsView: View {
    // MARK: - Properties

    let shelter: Shelter
    @Bindable var viewModel: RatingViewModel
    @State private var showEditSheet = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Rating summary section
                ratingSummarySection

                // User's rating section
                userRatingSection

                // All reviews section
                allReviewsSection
            }
            .padding()
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditRatingSheet(viewModel: viewModel)
        }
        .task {
            // Data should already be loaded by ShelterInfoSheet
            // But refresh if needed
            if viewModel.currentShelterId == nil {
                await viewModel.loadAllData(for: getShelterUUID())
            }
        }
    }

    // MARK: - Rating Summary Section

    @ViewBuilder
    private var ratingSummarySection: some View {
        if viewModel.isLoadingRatings {
            // Loading skeleton
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .redacted(reason: .placeholder)
            }
        } else {
            RatingSummaryCard(summary: viewModel.ratingSummary, style: .full)
        }
    }

    // MARK: - User Rating Section

    @ViewBuilder
    private var userRatingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.hasBadge {
                if viewModel.hasExistingRating {
                    // Show user's existing rating with edit option
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Rating")
                            .font(.headline)

                        if let userRating = viewModel.userRating {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    StarRatingView.medium(rating: Double(userRating.rating))

                                    if userRating.hasReview {
                                        Text(userRating.review!)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }

                                    Text(userRating.displayDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Edit button
                        Button(action: {
                            HapticFeedback.shared.lightImpact()
                            viewModel.startEditingRating()
                            showEditSheet = true
                        }) {
                            Text("Edit Your Rating")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    Divider()
                } else {
                    // Show rating form for new rating
                    RatingFormView(viewModel: viewModel, isEditing: false)
                    Divider()
                }
            } else {
                // User doesn't have badge - show message
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text(viewModel.permissionMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                Divider()
            }
        }
    }

    // MARK: - All Reviews Section

    @ViewBuilder
    private var allReviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Reviews")
                .font(.headline)

            if viewModel.isLoadingRatings {
                // Loading skeletons
                ForEach(0 ..< 3, id: \.self) { _ in
                    RatingCardSkeleton()
                }
            } else if viewModel.ratings.isEmpty {
                // Empty state
                RatingEmptyState()
            } else {
                // Reviews list
                VStack(spacing: 0) {
                    ForEach(viewModel.ratings) { ratingWithUser in
                        RatingCard(
                            ratingWithUser: ratingWithUser,
                            showDivider: ratingWithUser.id != viewModel.ratings.last?.id
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func getShelterUUID() -> UUID {
        UUID(uuidString: shelter.id) ?? UUID()
    }
}

// MARK: - Edit Rating Sheet

struct EditRatingSheet: View {
    @Bindable var viewModel: RatingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                RatingFormView(viewModel: viewModel, isEditing: true)
                    .padding()
            }
            .navigationTitle("Edit Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.successMessage) { _, newValue in
            if newValue != nil {
                // Dismiss sheet after successful submission
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShelterReviewsView(
            shelter: Shelter(
                id: UUID().uuidString,
                number: 1,
                commonId: "TEST001",
                name: "Sample Shelter",
                address: "123 Test Street",
                municipality: "Test City",
                isShelter: false,
                isFlood: true,
                isLandslide: false,
                isStormSurge: false,
                isEarthquake: true,
                isTsunami: false,
                isFire: true,
                isInlandFlood: false,
                isVolcano: false,
                isSameAddressAsShelter: false,
                otherMunicipalNotes: nil,
                acceptedPeople: nil,
                latitude: 35.6812,
                longitude: 139.7671,
                remarks: nil,
                lastUpdated: Date()
            ),
            viewModel: {
                let vm = RatingViewModel()
                // Simulate loaded data
                vm.ratingSummary = ShelterRatingSummary(
                    averageRating: 4.2,
                    totalRatings: 5
                )
                vm.ratings = [
                    ShelterRatingWithUser(
                        rating: ShelterRating(
                            id: UUID(),
                            shelterId: UUID(),
                            userId: UUID(),
                            rating: 5,
                            review: "Excellent shelter with great facilities!",
                            createdAt: Date().addingTimeInterval(-86400),
                            updatedAt: Date().addingTimeInterval(-86400)
                        ),
                        user: User(
                            id: UUID(),
                            createdAt: Date(),
                            name: "Test User 1",
                            profileBadgeId: nil
                        ),
                        userProfileBadgeImageUrl: nil
                    ),
                    ShelterRatingWithUser(
                        rating: ShelterRating(
                            id: UUID(),
                            shelterId: UUID(),
                            userId: UUID(),
                            rating: 4,
                            review: "Good shelter, well maintained.",
                            createdAt: Date().addingTimeInterval(-172_800),
                            updatedAt: Date().addingTimeInterval(-172_800)
                        ),
                        user: User(
                            id: UUID(),
                            createdAt: Date(),
                            name: "Test User 2",
                            profileBadgeId: nil
                        ),
                        userProfileBadgeImageUrl: nil
                    ),
                ]
                vm.hasBadge = true
                vm.canRate = true
                vm.hasExistingRating = false
                return vm
            }()
        )
    }
}
