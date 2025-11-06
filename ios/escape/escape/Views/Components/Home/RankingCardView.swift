//
//  RankingCardView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/05.
//

import SwiftUI

struct RankingCardView: View {
    @Binding var pointViewModel: PointViewModel
    @State private var groupViewModel = GroupViewModel()
    @State private var selectedTab: RankingTab = .national
    @State private var showingRankingDetail = false

    enum RankingTab {
        case national
        case team
    }

    var body: some View {
        Button {
            // Pre-load data before showing sheet to avoid empty state
            Task {
                if selectedTab == .team && groupViewModel.hasAnyGroup {
                    if let groupId = groupViewModel.primaryGroup?.team.id {
                        await pointViewModel.fetchTeamStats(groupId: groupId)
                    }
                }
            }
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
                    NationalRankingPreview(pointViewModel: pointViewModel)
                        .tag(RankingTab.national)

                    // Team Ranking Preview
                    TeamRankingPreview(pointViewModel: pointViewModel, groupViewModel: groupViewModel)
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
            RankingView(selectedTab: selectedTab, pointViewModel: pointViewModel, groupViewModel: groupViewModel)
        }
        .task {
            // Pre-load all ranking data
            async let userStatsFetch = pointViewModel.fetchUserStats()
            async let groupsFetch = groupViewModel.loadUserGroups()

            await userStatsFetch
            await groupsFetch

            // Load team stats if user has a group
            if let groupId = groupViewModel.primaryGroup?.team.id {
                await pointViewModel.fetchTeamStats(groupId: groupId)
            }
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
    let pointViewModel: PointViewModel

    var body: some View {
        VStack(spacing: 0) {
            // User's Stats
            if let rank = pointViewModel.userNationalRank {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ranking.your_rank")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(String(format: NSLocalizedString("ranking.national_rank_format", comment: ""), rank))
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

// MARK: - Team Ranking Preview

private struct TeamRankingPreview: View {
    let pointViewModel: PointViewModel
    let groupViewModel: GroupViewModel

    var body: some View {
        VStack(spacing: 0) {
            if !groupViewModel.hasAnyGroup {
                // No team placeholder
                VStack(spacing: 8) {
                    Text("ranking.no_team_preview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text("ranking.join_team_to_compete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let rank = pointViewModel.userTeamRank, let team = groupViewModel.primaryGroup {
                // User's team stats
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ranking.your_team_rank")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(String(format: NSLocalizedString("ranking.team_rank_format", comment: ""), rank))
                            .font(.title3)
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("brandMediumBlue"), Color("brandOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(team.team.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text("\(team.memberCount) " + NSLocalizedString("ranking.members", comment: ""))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("brandMediumBlue"))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("brandMediumBlue").opacity(0.1))
                )
            }
        }
    }
}
