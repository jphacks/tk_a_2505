//
//  RankingCardView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/05.
//

import SwiftUI

struct RankingCardView: View {
    @Binding var pointViewModel: PointViewModel
    @State private var selectedTab: RankingTab = .national
    @State private var showingRankingDetail = false

    enum RankingTab {
        case national
        case team
    }

    var body: some View {
        Button {
            showingRankingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("brandOrange"), Color("brandRed")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("ranking.title")
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()
                }

                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // National Tab
                        TabButton(
                            title: "ranking.national",
                            icon: "flag.fill",
                            isSelected: selectedTab == .national
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .national
                            }
                        }

                        // Team Tab (TODO)
                        TabButton(
                            title: "ranking.team",
                            icon: "person.3.fill",
                            isSelected: selectedTab == .team
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .team
                            }
                        }
                    }
                }

                // Content
                TabView(selection: $selectedTab) {
                    // National Ranking Preview
                    NationalRankingPreview(pointViewModel: $pointViewModel)
                        .tag(RankingTab.national)

                    // Team Ranking Preview (TODO)
                    VStack(spacing: 8) {
                        Text("ranking.team_coming_soon")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text("ranking.team_description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .tag(RankingTab.team)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 100)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingRankingDetail) {
            RankingView(selectedTab: selectedTab)
        }
        .task {
            await pointViewModel.fetchUserStats()
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: LocalizedStringKey
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                        LinearGradient(
                            colors: [Color("brandOrange"), Color("brandRed")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - National Ranking Preview

private struct NationalRankingPreview: View {
    @Binding var pointViewModel: PointViewModel

    var body: some View {
        VStack(spacing: 0) {
            // User's Stats
            if let rank = pointViewModel.userNationalRank {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ranking.your_rank")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(String(format: NSLocalizedString("result.rank_format", comment: ""), rank))
                            .font(.title3)
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("brandOrange"), Color("brandRed")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ranking.your_points")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("\(pointViewModel.totalPoints)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("brandMediumBlue"))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("brandOrange").opacity(0.1))
                )
            }
        }
    }
}

// MARK: - Ranking Row Preview

private struct RankingRowPreview: View {
    let entry: RankingEntry

    var body: some View {
        HStack(spacing: 12) {
            // Rank Medal
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(entry.rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
            }

            // Username
            Text(entry.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            // Points
            Text(entry.formattedPoints)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Color("brandMediumBlue")
        }
    }
}
