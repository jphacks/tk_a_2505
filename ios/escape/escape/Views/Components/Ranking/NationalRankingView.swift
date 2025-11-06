//
//  NationalRankingView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/05.
//

import SwiftUI

struct NationalRankingView: View {
    let pointViewModel: PointViewModel
    @State private var animateEntries = false
    @State private var showSparkles = false
    @State private var currentUserId: UUID?
    @State private var isLoadingNational = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("brandOrange").opacity(0.05),
                    Color("brandRed").opacity(0.05),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isLoadingNational {
                LoadingView()
            } else if let error = pointViewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await loadRankings()
                    }
                }
            } else if pointViewModel.nationalRanking.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Top 3 Podium (only if they're in the ranking)
                        let topThree = pointViewModel.nationalRanking.filter { $0.rank >= 1 && $0.rank <= 3 }
                        if !topThree.isEmpty {
                            TopThreePodium(rankings: topThree)
                                .padding(.top, 8)
                                .padding(.horizontal)
                        }

                        // All Rankings (including separators)
                        ForEach(Array(pointViewModel.nationalRanking.enumerated()), id: \.element.id) { index, entry in
                            if entry.rank == -1 {
                                // Separator
                                SeparatorView()
                                    .padding(.horizontal)
                            } else if entry.rank > 3 {
                                RankingRow(
                                    entry: entry,
                                    currentUserId: currentUserId,
                                    delay: Double(index) * 0.05
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
                    await loadRankings()
                }
            }
        }
        .task {
            await loadRankings()
            startAnimations()
        }
    }

    private func loadRankings() async {
        isLoadingNational = true

        // Get current user ID first
        do {
            let authService = AuthSupabase()
            currentUserId = try await authService.getCurrentUserId()

            // Use smart pagination with current user context
            let pointService = PointSupabase()
            let smartRankings = try await pointService.getSmartPaginatedNationalLeaderboard(userId: currentUserId!)
            pointViewModel.nationalRanking = smartRankings

            await pointViewModel.fetchUserStats()
        } catch {
            print("❌ Failed to load rankings: \(error)")
            // Fallback to regular leaderboard
            await pointViewModel.fetchNationalLeaderboard(limit: 100)
            await pointViewModel.fetchUserStats()
        }

        isLoadingNational = false
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            animateEntries = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                showSparkles = true
            }
        }
    }
}

// MARK: - Top 3 Podium

private struct TopThreePodium: View {
    let rankings: [RankingEntry]
    @State private var animateRanks = [false, false, false]
    @State private var showCrowns = [false, false, false]

    var body: some View {
        VStack(spacing: 20) {
            // Winner Banner
            if let first = rankings.first {
                WinnerBanner(entry: first, animate: animateRanks[0])
            }

            // Podium
            HStack(alignment: .bottom, spacing: 16) {
                // 2nd Place
                if rankings.count > 1 {
                    PodiumPosition(
                        entry: rankings[1],
                        height: 120,
                        color: Color.gray,
                        crownColor: .silver,
                        animate: animateRanks[1],
                        showCrown: showCrowns[1]
                    )
                }

                // 1st Place (Tallest)
                if let first = rankings.first {
                    PodiumPosition(
                        entry: first,
                        height: 160,
                        color: Color.yellow,
                        crownColor: .gold,
                        animate: animateRanks[0],
                        showCrown: showCrowns[0]
                    )
                }

                // 3rd Place
                if rankings.count > 2 {
                    PodiumPosition(
                        entry: rankings[2],
                        height: 100,
                        color: Color.orange,
                        crownColor: .bronze,
                        animate: animateRanks[2],
                        showCrown: showCrowns[2]
                    )
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // Stagger animations
            for i in 0 ..< min(3, rankings.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateRanks[i] = true
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                        showCrowns[i] = true
                    }
                }
            }
        }
    }
}

// MARK: - Winner Banner

private struct WinnerBanner: View {
    let entry: RankingEntry
    let animate: Bool
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 8) {
            // Crown Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 10)
                .scaleEffect(animate ? 1 : 0)
                .rotationEffect(.degrees(animate ? 0 : -180))

            Text("ranking.champion")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(entry.displayName)
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("brandOrange"), Color("brandRed")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(entry.formattedPoints)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("brandMediumBlue"))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.1),
                            Color.orange.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.5), Color.orange.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.yellow.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(animate ? 1 : 0.8)
        .opacity(animate ? 1 : 0)
    }
}

// MARK: - Podium Position

private struct PodiumPosition: View {
    let entry: RankingEntry
    let height: CGFloat
    let color: Color
    let crownColor: Color
    let animate: Bool
    let showCrown: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Crown for top 3
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundColor(crownColor)
                .opacity(showCrown ? 1 : 0)
                .scaleEffect(showCrown ? 1 : 0.5)
                .offset(y: showCrown ? 0 : 10)

            // Avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(entry.displayName.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                )
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 3)
                )

            // Name
            Text(entry.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(maxWidth: 100)

            // Points
            Text(entry.formattedPoints)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Podium
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: animate ? height : 0)
                .overlay(
                    Text("\(entry.rank)")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(color.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.5), lineWidth: 2)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ranking Row

private struct RankingRow: View {
    let entry: RankingEntry
    let currentUserId: UUID?
    let delay: Double
    @State private var isPressed = false
    @State private var pulseAnimation = false

    var isCurrentUser: Bool {
        currentUserId == entry.userId
    }

    var body: some View {
        HStack(spacing: 16) {
            // Rank Number
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(rankGradient)
                    .frame(width: 50, height: 50)

                Text("\(entry.rank)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.displayName)
                        .font(.headline)
                        .fontWeight(isCurrentUser ? .bold : .semibold)
                        .foregroundColor(isCurrentUser ? Color("brandOrange") : .primary)

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
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("brandOrange"), Color("brandRed")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }

                Text(entry.formattedPoints + " " + NSLocalizedString("ranking.points", comment: ""))
                    .font(.caption)
                    .foregroundColor(isCurrentUser ? Color("brandOrange").opacity(0.8) : .secondary)
            }

            Spacer()

            // Medal/Badge for top ranks
            if entry.rank <= 10 {
                Image(systemName: rankIcon)
                    .font(.title2)
                    .foregroundColor(rankIconColor)
            }
        }
        .padding(isCurrentUser ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentUser ?
                    LinearGradient(
                        colors: [Color("brandOrange").opacity(0.25), Color("brandRed").opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isCurrentUser ?
                                LinearGradient(
                                    colors: [Color("brandOrange"), Color("brandRed")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear, Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                            lineWidth: isCurrentUser ? 3 : 0
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isCurrentUser && pulseAnimation ? 1.02 : 1))
        .shadow(
            color: isCurrentUser ? Color("brandOrange").opacity(0.4) : Color.black.opacity(0.1),
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
    }

    private var rankGradient: LinearGradient {
        if entry.rank <= 10 {
            return LinearGradient(
                colors: [Color("brandOrange"), Color("brandRed")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var rankIcon: String {
        switch entry.rank {
        case 4 ... 5: return "star.fill"
        case 6 ... 10: return "star"
        default: return "medal.fill"
        }
    }

    private var rankIconColor: Color {
        switch entry.rank {
        case 4 ... 5: return Color.yellow
        case 6 ... 10: return Color.gray
        default: return Color("brandOrange")
        }
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
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color("brandOrange"), Color("brandRed")],
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

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("brandOrange"), Color("brandRed")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ranking.no_rankings_yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("ranking.complete_mission_prompt")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
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

// MARK: - Color Extensions

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let bronze = Color(red: 0.8, green: 0.5, blue: 0.2)
}
