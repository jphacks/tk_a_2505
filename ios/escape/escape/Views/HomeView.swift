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
    @State private var groupViewModel = GroupViewModel()
    @State private var pointViewModel = PointViewModel()

    @State private var showingGroupBottomSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    HStack {
                        Text("HiNan!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("brandOrange"))

                        Spacer()

                        // グループアイコンボタン
                        Button(action: {
                            showingGroupBottomSheet = true
                        }) {
                            Image(systemName: "person.3.fill")
                                .font(.title2)
                                .foregroundColor(Color("brandOrange"))
                                .frame(width: 44, height: 44)
                                .background(Color("brandOrange").opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    // 現在のミッション セクション
                    MissionSection()

                    // バッジコレクション セクション
                    BadgeCollectionView(badges: homeViewModel.userBadges, stats: homeViewModel.badgeStats)
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
            .navigationBarHidden(true)
            .sheet(isPresented: $showingGroupBottomSheet) {
                GroupBottomSheetView(groupViewModel: groupViewModel)
            }
            .onAppear {
                Task {
                    await homeViewModel.loadUserBadges()
                    await groupViewModel.loadUserGroups()
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
