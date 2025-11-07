//
//  HomeViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation

@MainActor
@Observable
class HomeViewModel {
    var userBadges: [Badge] = []
    var badgeStats: (total: Int, unlocked: Int) = (0, 0)
    var showingMissionDetail = false

    // MARK: - Dependencies

    private let badgeService: BadgeSupabase

    // MARK: - Initialization

    init(badgeService: BadgeSupabase = BadgeSupabase()) {
        self.badgeService = badgeService
    }

    // MARK: - Actions

    func loadUserBadges() async {
        do {
            let collectedBadges = try await badgeService.getUserCollectedBadgesWithDetails()
            userBadges = collectedBadges.map { $0.toBadge() }

            // Fetch badge statistics
            badgeStats = try await badgeService.getBadgeStats()
        } catch {
            print("❌ Failed to load badges: \(error)")
            userBadges = [] // Fallback to empty array on error
            badgeStats = (0, 0)
        }
    }
}
