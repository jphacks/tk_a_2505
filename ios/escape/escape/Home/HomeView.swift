//
//  HomeView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import SwiftUI

struct HomeView: View {
    @State private var currentMission: Mission? = nil
    @State private var userBadges: [Badge] = []
    @State private var badgeStats: (total: Int, unlocked: Int) = (0, 0)
    @State private var showingMissionDetail = false

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

                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // 現在のミッション セクション
                    MissionCardView(mission: currentMission) {
                        showingMissionDetail = true
                    }
                    .padding(.horizontal)

                    // バッジコレクション セクション
                    BadgeCollectionView(badges: userBadges, stats: badgeStats)
                        .padding(.horizontal)

                    // 統計情報
                    StatsView()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMissionDetail) {
                MissionDetailView(mission: currentMission)
            }
            .onAppear {
                loadCurrentMission()
                loadUserBadges()
            }
        }
    }

    private func loadCurrentMission() {
        // TODO: Supabaseから現在のミッションを取得
        currentMission = Mission(
            id: UUID(),
            userId: UUID(),
            title: "震度6強の地震発生！避難所へ緊急避難せよ",
            overview: "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            evacuationRegion: "文京区",
            status: .active,
            steps: nil,
            distances: nil,
            createdAt: Date()
        )
    }

    private func loadUserBadges() {
        Task {
            do {
                let badgeService = BadgeService()
                let collectedBadges = try await badgeService.getUserCollectedBadgesWithDetails()
                userBadges = collectedBadges.map { $0.toBadge() }

                // Fetch badge statistics
                badgeStats = try await badgeService.getBadgeStats()
            } catch {
                debugPrint("❌ Failed to load badges: \(error)")
                userBadges = [] // Fallback to empty array on error
                badgeStats = (0, 0)
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
