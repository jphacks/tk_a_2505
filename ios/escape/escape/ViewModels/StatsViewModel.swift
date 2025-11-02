//
//  StatsViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation

@MainActor
@Observable
class StatsViewModel {
    var isLoading = false
    var errorMessage: String?
    var recentMissionResults: [MissionResult] = []

    // MARK: - Dependencies

    private let missionResultService: MissionResultSupabase

    // MARK: - Initialization

    init(missionResultService: MissionResultSupabase = MissionResultSupabase()) {
        self.missionResultService = missionResultService
    }

    // MARK: - Computed Statistics

    /// Count of completed missions
    var completedMissionsCount: Int {
        recentMissionResults.count
    }

    /// Total distance from all completed missions (in meters, converted to km)
    var totalDistance: Double {
        recentMissionResults
            .compactMap { $0.actualDistanceMeters }
            .reduce(0, +) / 1000.0 // Convert meters to km
    }

    /// Total steps from all completed missions
    var totalSteps: Int {
        recentMissionResults
            .compactMap { result in
                if let steps = result.steps {
                    return Int(steps)
                }
                return nil
            }
            .reduce(0, +)
    }

    // MARK: - Data Fetching

    /// Fetches recent mission results for a user from Supabase
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of mission results to fetch (default: 30)
    func fetchRecentMissions(userId: UUID, limit: Int = 30) async {
        isLoading = true
        errorMessage = nil

        do {
            recentMissionResults = try await missionResultService.fetchRecentMissionResults(userId: userId, limit: limit)

            print("✅ Fetched \(recentMissionResults.count) mission result(s)")
            print("   Total steps: \(totalSteps)")
            print("   Total distance: \(String(format: "%.2f", totalDistance))km")

        } catch {
            errorMessage = "Failed to fetch mission results: \(error.localizedDescription)"
            print("❌ Error fetching mission results for stats: \(error)")
            recentMissionResults = []
        }

        isLoading = false
    }

    /// Fetches mission results within a specific date range
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    func fetchMissionsInDateRange(userId: UUID, startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            recentMissionResults = try await missionResultService.fetchMissionResultsInDateRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )

            print("✅ Fetched \(recentMissionResults.count) mission result(s) in date range")

        } catch {
            errorMessage = "Failed to fetch mission results: \(error.localizedDescription)"
            print("❌ Error fetching mission results in date range: \(error)")
            recentMissionResults = []
        }

        isLoading = false
    }

    /// Fetches missions for the last N days (only completed missions)
    func fetchMissionsForLastDays(userId: UUID, days: Int) async {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now

        await fetchMissionsInDateRange(userId: userId, startDate: startDate, endDate: now)
    }

    /// Average steps per mission for the current results
    var averageSteps: Double {
        guard !recentMissionResults.isEmpty else { return 0 }
        return Double(totalSteps) / Double(recentMissionResults.count)
    }

    /// Average distance per mission for the current results (in km)
    var averageDistance: Double {
        guard !recentMissionResults.isEmpty else { return 0 }
        return totalDistance / Double(recentMissionResults.count)
    }

    /// Resets the controller state
    func reset() {
        isLoading = false
        errorMessage = nil
        recentMissionResults = []
    }
}
