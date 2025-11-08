//
//  TeamRankingView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/05.
//

import SwiftUI

struct TeamRankingView: View {
    let pointViewModel: PointViewModel
    let groupViewModel: GroupViewModel
    @State private var animateEntries = false
    @State private var currentUserId: UUID?
    @State private var isLoadingTeam = false
    @State private var selectedUserId: UUID?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("brandMediumBlue").opacity(0.05),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !groupViewModel.hasAnyGroup && !groupViewModel.isLoading {
                // No Group Placeholder
                NoGroupView()
            } else if isLoadingTeam || groupViewModel.isLoading {
                LoadingView()
            } else if let error = pointViewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await loadTeamRankings()
                    }
                }
            } else if pointViewModel.teamRanking.isEmpty && groupViewModel.hasAnyGroup {
                EmptyTeamView()
            } else if groupViewModel.hasAnyGroup {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Team Name Header
                        if let team = groupViewModel.primaryGroup {
                            TeamHeaderView(team: team)
                                .padding(.top, 8)
                                .padding(.horizontal)
                        }

                        // Team Rankings
                        ForEach(Array(pointViewModel.teamRanking.enumerated()), id: \.element.id) {
                            index, entry in
                            if entry.rank == -1 {
                                // Separator
                                SeparatorView()
                                    .padding(.horizontal)
                            } else {
                                TeamRankingRow(
                                    entry: entry,
                                    currentUserId: currentUserId,
                                    delay: Double(index) * 0.05,
                                    onTap: handleUserTap
                                )
                                .padding(.horizontal)
                                .opacity(animateEntries ? 1 : 0)
                                .offset(y: animateEntries ? 0 : 20)
                            }
                        }

                        // Bottom spacing
                        Color.clear.frame(height: 20)
                    }
                    .padding(.bottom, 8)
                }
                .refreshable {
                    await loadTeamRankings()
                }
            }
        }
        .sheet(item: $selectedUserId) { userId in
            UserProfileBottomSheetView(userId: userId)
                .presentationDetents([.medium, .large])
        }
        .task {
            await loadTeamRankings()
            startAnimations()
        }
    }

    private func handleUserTap(userId: UUID) {
        selectedUserId = userId
    }

    private func loadTeamRankings() async {
        isLoadingTeam = true

        // Ensure groups are loaded first
        if groupViewModel.userGroups.isEmpty {
            await groupViewModel.loadUserGroups()
        }

        guard let groupId = groupViewModel.primaryGroup?.team.id else {
            print("⚠️ No primary group found")
            isLoadingTeam = false
            return
        }

        // Get current user ID
        do {
            let authService = AuthSupabase()
            currentUserId = try await authService.getCurrentUserId()
        } catch {
            print("❌ Failed to get current user ID: \(error)")
        }

        // Fetch team stats
        await pointViewModel.fetchTeamStats(groupId: groupId)

        isLoadingTeam = false
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            animateEntries = true
        }
    }
}

// MARK: - Team Header View

private struct TeamHeaderView: View {
    let team: TeamWithDetails

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("brandMediumBlue"), Color("brandOrange")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(team.team.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("\(team.memberCount) " + NSLocalizedString("ranking.members", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("brandMediumBlue").opacity(0.1))
            )
        }
    }
}

// MARK: - No Group View

private struct NoGroupView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("brandMediumBlue"), Color("brandOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ranking.no_team_title")
                .font(.title2)
                .fontWeight(.bold)

            Text("ranking.no_team_description")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - Empty Team View

private struct EmptyTeamView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("brandMediumBlue"), Color("brandOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ranking.team_no_rankings")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("ranking.team_complete_missions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Team Ranking Row

private struct TeamRankingRow: View {
    let entry: RankingEntry
    let currentUserId: UUID?
    let delay: Double
    let onTap: (UUID) -> Void
    @State private var isPressed = false
    @State private var pulseAnimation = false

    var isCurrentUser: Bool {
        currentUserId == entry.userId
    }

    var body: some View {
        HStack(spacing: 16) {
            // Rank Number
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rankGradient)
                    .frame(width: 25, height: 25)

                Text("\(entry.rank)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // User Avatar
            UserAvatarView.teamRanking(
                username: entry.displayName,
                badgeImageUrl: entry.profileBadgeImageUrl
            )

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.displayName)
                        .font(.headline)
                        .fontWeight(isCurrentUser ? .bold : .semibold)
                        .foregroundColor(isCurrentUser ? Color("brandMediumBlue") : .primary)

                    // "YOU" badge for current user
                    if isCurrentUser {
                        Text("YOU")
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color("brandMediumBlue"))
                            )
                    }
                }

                Text(entry.formattedPoints + " " + NSLocalizedString("ranking.points", comment: ""))
                    .font(.caption)
                    .foregroundColor(isCurrentUser ? Color("brandMediumBlue").opacity(0.8) : .secondary)
            }

            Spacer()

            // Medal/Badge for top 3
            if entry.rank <= 3 {
                Image(systemName: rankIcon)
                    .font(.title2)
                    .foregroundColor(rankIconColor)
            }
        }
        .padding(isCurrentUser ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isCurrentUser ? Color("brandMediumBlue").opacity(0.1) : Color(.secondarySystemBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isCurrentUser ? Color("brandMediumBlue") : Color.clear,
                            lineWidth: isCurrentUser ? 2 : 0
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isCurrentUser && pulseAnimation ? 1.02 : 1))
        .shadow(
            color: isCurrentUser ? Color("brandMediumBlue").opacity(0.4) : Color.black.opacity(0.1),
            radius: isCurrentUser ? 15 : 5,
            x: 0,
            y: isCurrentUser ? 8 : 2
        )
        .onAppear {
            if isCurrentUser {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .onTapGesture {
            onTap(entry.userId)
        }
    }

    private var rankGradient: LinearGradient {
        if entry.rank <= 3 {
            return LinearGradient(
                colors: [Color("brandMediumBlue"), Color("brandMediumBlue")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return "star"
        }
    }

    private var rankIconColor: Color {
        switch entry.rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Color("brandMediumBlue")
        }
    }
}

// MARK: - Separator View

private struct SeparatorView: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)

            Text("•••")
                .font(.caption)
                .foregroundColor(.secondary)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Views

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("ranking.loading")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onRetry) {
                Text("ranking.retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color("brandMediumBlue"), Color("brandOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding()
    }
}
