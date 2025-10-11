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
                    BadgeCollectionView(badges: userBadges)
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
            id: "1",
            title: "震度6強の地震発生！避難所へ緊急避難せよ",
            name: "緊急地震避難訓練",
            description: "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            estimatedDuration: 15,
            distance: 800,
            severity: .critical,
            isUrgent: true,
            aiGeneratedAt: Date()
        )
    }

    private func loadUserBadges() {
        // TODO: Supabaseからユーザーのバッジを取得
        userBadges = [
            Badge(id: "1", name: "後楽園", icon: "star.fill", color: Color("brandOrange"), isUnlocked: true, imageName: "korakuen", badgeNumber: "B001", address: "東京都文京区後楽1-3-61", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7056, longitude: 139.7514),
            Badge(id: "2", name: "東大前", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true, imageName: "todaimae", badgeNumber: "B002", address: "東京都文京区本郷7-3-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7123, longitude: 139.7614),
            Badge(id: "3", name: "ロゴ", icon: "timer", color: Color("brandMediumBlue"), isUnlocked: true, imageName: "logo", badgeNumber: "B003", address: "東京都文京区湯島3-30-1", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7081, longitude: 139.7686),
            Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: true, imageName: nil, badgeNumber: "B004", address: "東京都文京区千駄木2-19-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7265, longitude: 139.7610),
        ]
    }
}

#Preview("HomeView - English") {
    HomeView().environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView().environment(\.locale, .init(identifier: "ja"))
}
