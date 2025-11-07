//
//  HomeView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Supabase
import SwiftUI

struct HomeView: View {
    @State private var homeViewModel = HomeViewModel()
    @State private var pointViewModel = PointViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 現在のミッション セクション
                    MissionSection()

                    // バッジコレクション セクション
                    BadgeCollectionView(
                        badges: homeViewModel.userBadges,
                        stats: homeViewModel.badgeStats,
                        isLoading: homeViewModel.isLoadingBadges
                    )
                    .padding(.horizontal)

                    // ランキング セクション
                    RankingCardView(pointViewModel: $pointViewModel)
                        .padding(.horizontal)

                    // 統計情報
                    StatsView()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .onAppear {
                Task {
                    await homeViewModel.loadUserBadges()
                }
            }
        }
    }
}

#Preview("HomeView - English") {
    HomeView().environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView().environment(\.locale, .init(identifier: "ja"))
}
