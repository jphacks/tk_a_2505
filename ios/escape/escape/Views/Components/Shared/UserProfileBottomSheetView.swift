//
//  UserProfileBottomSheetView.swift
//  escape
//
//  Created by Claude on 2025-11-08.
//

import SwiftUI

struct UserProfileBottomSheetView: View {
    let userId: UUID
    @State private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if let user = viewModel.user {
                        profileContent(user: user)
                    } else {
                        emptyView
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "userprofile.title", table: "Localizable"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchUserProfile(userId: userId)
        }
    }

    // MARK: - Profile Content

    @ViewBuilder
    private func profileContent(user: User) -> some View {
        // Header Section - Avatar & Username
        VStack(spacing: 16) {
            UserAvatarView.profile(
                username: user.name ?? String(localized: "common.anonymous", table: "Localizable"),
                badgeImageUrl: viewModel.getProfileBadge()?.imageUrl,
                size: .large
            )

            Text(user.name ?? String(localized: "common.anonymous", table: "Localizable"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)

        Divider()

        // Activity Heatmap Section
        ActivityHeatmapView(dailyPoints: viewModel.dailyPointsMap)

        Divider()

        // Badge Collection Section
        badgeCollectionSection
    }

    // MARK: - Badge Collection Section

    private var badgeCollectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("userprofile.badge_collection", tableName: "Localizable")
                .font(.headline)
                .foregroundColor(.primary)

            if viewModel.userBadges.isEmpty {
                emptyBadgesView
            } else {
                badgeGrid
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var badgeGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
            spacing: 12
        ) {
            ForEach(viewModel.userBadges, id: \.id) { badge in
                UserAvatarView(
                    username: badge.name,
                    badgeImageUrl: badge.imageUrl,
                    size: .medium,
                    showLoadingIndicator: true
                )
            }
        }
    }

    private var emptyBadgesView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("userprofile.no_badges", tableName: "Localizable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("userprofile.loading", tableName: "Localizable")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("userprofile.error_title", tableName: "Localizable")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(String(localized: "Try Again", table: "Localizable")) {
                Task {
                    await viewModel.fetchUserProfile(userId: userId)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("userprofile.user_not_found", tableName: "Localizable")
                .font(.headline)
            Text("userprofile.user_not_found_description", tableName: "Localizable")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview {
    UserProfileBottomSheetView(
        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    )
}
