//
//  UserProfileViewModel.swift
//  escape
//
//  Created by Claude on 2025-11-08.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class UserProfileViewModel {
    // MARK: - Properties

    var isLoading = false
    var errorMessage: String?
    var user: User?
    var missionResults: [MissionResult] = []
    var userBadges: [Badge] = []
    var dailyPointsMap: [String: Int] = [:]

    // MARK: - Dependencies

    private let userSupabase: UserSupabase
    private let missionResultSupabase: MissionResultSupabase
    private let badgeSupabase: BadgeSupabase

    // MARK: - Initialization

    init(
        userSupabase: UserSupabase = UserSupabase(),
        missionResultSupabase: MissionResultSupabase = MissionResultSupabase(),
        badgeSupabase: BadgeSupabase = BadgeSupabase()
    ) {
        self.userSupabase = userSupabase
        self.missionResultSupabase = missionResultSupabase
        self.badgeSupabase = badgeSupabase
    }

    // MARK: - Public Methods

    /// Fetches the complete profile for a given user
    func fetchUserProfile(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            // Calculate date range for last 30 days
            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
                throw NSError(domain: "UserProfileViewModel", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])
            }

            // Fetch all data in parallel
            async let userTask = userSupabase.getUserProfile(userId: userId)
            async let missionResultsTask = missionResultSupabase.fetchMissionResultsInDateRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            async let badgesTask = fetchUserBadges(userId: userId)

            // Await all results
            let (fetchedUser, fetchedMissionResults, fetchedBadges) = try await (
                userTask,
                missionResultsTask,
                badgesTask
            )

            // Update state
            self.user = fetchedUser
            self.missionResults = fetchedMissionResults
            self.userBadges = fetchedBadges

            // Calculate daily points map
            calculateDailyPoints()

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("Error fetching user profile: \(error)")
        }
    }

    /// Refreshes the profile data
    func refresh(userId: UUID) async {
        await fetchUserProfile(userId: userId)
    }

    // MARK: - Private Methods

    /// Calculates total points for each day from mission results
    private func calculateDailyPoints() {
        var pointsMap: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for result in missionResults {
            let dateString = formatter.string(from: result.createdAt)
            let points = Int(result.finalPoints ?? 0)
            pointsMap[dateString, default: 0] += points
        }

        self.dailyPointsMap = pointsMap
    }

    /// Fetches all badges that the user has collected
    private func fetchUserBadges(userId: UUID) async throws -> [Badge] {
        // Fetch the user's badge collection
        let userBadges = try await badgeSupabase.fetchUserBadges(userId: userId)

        // Extract unique badge IDs
        let badgeIds = Set(userBadges.map { $0.badgeId })

        // Fetch all badge details
        let badges = try await badgeSupabase.fetchBadgesByIds(Array(badgeIds))

        return badges
    }

    /// Gets the current user's profile badge for avatar display
    func getProfileBadge() -> Badge? {
        guard let user = user,
              let profileBadgeId = user.profileBadgeId else {
            return nil
        }

        return userBadges.first { $0.id == profileBadgeId.uuidString }
    }
}
