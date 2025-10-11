//
//  HomeView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import Supabase
import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Tab
    @State private var missionController = MissionController()
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
                    if missionController.isLoading {
                        // Loading state
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .padding(.horizontal)
                    } else if let errorMessage = missionController.errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                loadCurrentMission()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .padding(.horizontal)
                    } else {
                        MissionCardView(mission: missionController.todaysMission) {
                            showingMissionDetail = true
                        }
                        .padding(.horizontal)
                    }

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
                MissionDetailView(
                    mission: missionController.todaysMission,
                    selectedTab: $selectedTab,
                    isPresented: $showingMissionDetail
                )
            }
            .onAppear {
                loadCurrentMission()
                loadUserBadges()
            }
        }
    }

    private func loadCurrentMission() {
        Task {
            // Get current user ID from Supabase auth
            guard let currentUser = supabase.auth.currentUser else {
                missionController.errorMessage = "Not authenticated"
                print("⚠️ User not authenticated")
                return
            }

            let userId = currentUser.id
            print("👤 Current user ID: \(userId)")
            print("👤 User email: \(currentUser.email ?? "none")")
            print("👤 UUID lowercase: \(userId.uuidString.lowercased())")

            // Fetch today's mission from Supabase
            await missionController.fetchTodaysMission(userId: userId)

            // Debug: If no mission found, try fetching latest mission
            if missionController.todaysMission == nil && missionController.errorMessage == nil {
                print("ℹ️ No today's mission found, trying to fetch latest...")
                await missionController.fetchLatestMission(userId: userId)
            }
        }
    }

    private func loadUserBadges() {
        // TODO: Supabaseからユーザーのバッジを取得
        userBadges = [
            Badge(id: "1", name: "sample1", icon: "star.fill", color: Color("brandOrange"), isUnlocked: true),
            Badge(id: "2", name: "sample2", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true),
            Badge(id: "3", name: "sample3", icon: "timer", color: Color("brandMediumBlue"), isUnlocked: false),
            Badge(id: "4", name: "sample4", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: false),
        ]
    }
}

#Preview("HomeView - English") {
    HomeView(selectedTab: .constant(.home)).environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView(selectedTab: .constant(.home)).environment(\.locale, .init(identifier: "ja"))
}
