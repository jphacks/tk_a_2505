//
//  PointViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/02.
//

import Foundation

@MainActor
@Observable
class PointViewModel {
    var isLoading = false
    var errorMessage: String?
    var totalPoints: Int64 = 0
    var recentPointRecords: [Point] = []
    var nationalRanking: [RankingEntry] = []
    var userNationalRank: Int?
    var teamRanking: [RankingEntry] = []
    var userTeamRank: Int?
    var currentTeamId: UUID?

    // MARK: - Dependencies

    private let pointService: PointSupabase
    private let authService: AuthSupabase

    // MARK: - Initialization

    init(
        pointService: PointSupabase = PointSupabase(),
        authService: AuthSupabase = AuthSupabase()
    ) {
        self.pointService = pointService
        self.authService = authService
    }

    // MARK: - Actions

    /// Adds a point record for the current user
    /// - Parameter points: The points to add (from mission result)
    func addPoints(_ points: Int64) async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await authService.getCurrentUserId()

            _ = try await pointService.addPointRecord(userId: userId, points: points)

            // Refresh total points
            await fetchTotalPoints()

            print("✅ Successfully added \(points) points for user")

        } catch {
            errorMessage = "Failed to add points: \(error.localizedDescription)"
            print("❌ Error adding points: \(error)")
        }

        isLoading = false
    }

    /// Fetches the total points for the current user
    func fetchTotalPoints() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await authService.getCurrentUserId()

            totalPoints = try await pointService.getTotalPoints(userId: userId)

            print("✅ Total points fetched: \(totalPoints)")

        } catch {
            errorMessage = "Failed to fetch points: \(error.localizedDescription)"
            print("❌ Error fetching points: \(error)")
        }

        isLoading = false
    }

    /// Fetches recent point records for the current user
    /// - Parameter limit: Maximum number of records to fetch
    func fetchRecentPointRecords(limit: Int = 50) async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await authService.getCurrentUserId()

            recentPointRecords = try await pointService.getRecentPointRecords(userId: userId, limit: limit)

            print("✅ Fetched \(recentPointRecords.count) recent point records")

        } catch {
            errorMessage = "Failed to fetch point records: \(error.localizedDescription)"
            print("❌ Error fetching point records: \(error)")
        }

        isLoading = false
    }

    /// Fetches national leaderboard (without setting isLoading to avoid conflicts)
    /// - Parameter limit: Number of top users to fetch
    func fetchNationalLeaderboard(limit: Int = 100) async {
        errorMessage = nil

        do {
            nationalRanking = try await pointService.getNationalLeaderboard(limit: limit)
            print("✅ Fetched \(nationalRanking.count) ranking entries")
        } catch {
            errorMessage = "Failed to fetch leaderboard: \(error.localizedDescription)"
            print("❌ Error fetching leaderboard: \(error)")
        }
    }

    /// Fetches user's national rank
    func fetchUserNationalRank() async {
        do {
            let userId = try await authService.getCurrentUserId()
            userNationalRank = try await pointService.getUserNationalRank(userId: userId)
            print("✅ User rank: \(userNationalRank ?? 0)")
        } catch {
            print("❌ Error fetching user rank: \(error)")
        }
    }

    /// Fetches both total points and national rank (without loading state)
    func fetchUserStats() async {
        do {
            let userId = try await authService.getCurrentUserId()

            // Fetch in parallel for speed
            async let pointsFetch = pointService.getTotalPoints(userId: userId)
            async let rankFetch = pointService.getUserNationalRank(userId: userId)

            totalPoints = try await pointsFetch
            userNationalRank = try await rankFetch

            print("✅ Fetched user stats (parallel): \(totalPoints) points, rank \(userNationalRank ?? 0)")
        } catch {
            print("❌ Error fetching user stats: \(error)")
        }
    }

    /// Fetches team leaderboard with smart pagination (without setting isLoading to avoid conflicts)
    /// - Parameter groupId: The team/group UUID
    func fetchTeamLeaderboard(groupId: UUID) async {
        errorMessage = nil
        currentTeamId = groupId

        do {
            let userId = try await authService.getCurrentUserId()
            teamRanking = try await pointService.getSmartPaginatedTeamLeaderboard(groupId: groupId, userId: userId)
            print("✅ Fetched \(teamRanking.count) team ranking entries")
        } catch {
            errorMessage = "Failed to fetch team leaderboard: \(error.localizedDescription)"
            print("❌ Error fetching team leaderboard: \(error)")
        }
    }

    /// Fetches user's team rank
    /// - Parameter groupId: The team/group UUID
    func fetchUserTeamRank(groupId: UUID) async {
        do {
            let userId = try await authService.getCurrentUserId()
            userTeamRank = try await pointService.getUserTeamRank(groupId: groupId, userId: userId)
            print("✅ User team rank: \(userTeamRank ?? 0)")
        } catch {
            print("❌ Error fetching user team rank: \(error)")
        }
    }

    /// Fetches both team leaderboard and user's rank in parallel
    /// - Parameter groupId: The team/group UUID
    func fetchTeamStats(groupId: UUID) async {
        currentTeamId = groupId
        errorMessage = nil

        do {
            let userId = try await authService.getCurrentUserId()

            // Fetch team leaderboard and rank in parallel
            async let leaderboardFetch = pointService.getSmartPaginatedTeamLeaderboard(groupId: groupId, userId: userId)
            async let rankFetch = pointService.getUserTeamRank(groupId: groupId, userId: userId)

            teamRanking = try await leaderboardFetch
            userTeamRank = try await rankFetch

            print("✅ Fetched team stats (parallel): \(teamRanking.count) entries, rank \(userTeamRank ?? 0)")
        } catch {
            errorMessage = "Failed to fetch team stats: \(error.localizedDescription)"
            print("❌ Error fetching team stats: \(error)")
        }
    }

    /// Resets the view model state
    func reset() {
        isLoading = false
        errorMessage = nil
        totalPoints = 0
        recentPointRecords = []
        nationalRanking = []
        userNationalRank = nil
        teamRanking = []
        userTeamRank = nil
        currentTeamId = nil
    }
}
