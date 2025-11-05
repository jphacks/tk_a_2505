//
//  RankingView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/05.
//

import SwiftUI

struct RankingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pointViewModel = PointViewModel()
    @State private var selectedTab: RankingTab

    enum RankingTab: String, CaseIterable {
        case national
        case team

        var title: LocalizedStringKey {
            switch self {
            case .national: return "ranking.national"
            case .team: return "ranking.team"
            }
        }

        var icon: String {
            switch self {
            case .national: return "flag.fill"
            case .team: return "person.3.fill"
            }
        }
    }

    init(selectedTab: RankingCardView.RankingTab = .national) {
        _selectedTab = State(initialValue: selectedTab == .national ? .national : .team)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector
                HStack(spacing: 0) {
                    ForEach(RankingTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.callout)

                                    Text(tab.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(selectedTab == tab ? Color("brandOrange") : .secondary)

                                Rectangle()
                                    .fill(selectedTab == tab ?
                                        LinearGradient(
                                            colors: [Color("brandOrange"), Color("brandRed")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.clear, Color.clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))

                Divider()

                // Content
                TabView(selection: $selectedTab) {
                    NationalRankingView(pointViewModel: $pointViewModel)
                        .tag(RankingTab.national)

                    TeamRankingView()
                        .tag(RankingTab.team)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("ranking.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
