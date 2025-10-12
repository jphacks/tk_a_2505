//
//  StatsController.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/12.
//

import Foundation
import Supabase

@Observable
class StatsController {
    var isLoading = false
    var errorMessage: String?
    var recentMissions: [Mission] = []

    // MARK: - Computed Statistics

    /// Count of completed missions
    var completedMissionsCount: Int {
        recentMissions.filter { $0.status == .completed }.count
    }

    /// Total distance from all completed missions (in km)
    var totalDistance: Double {
        recentMissions
            .filter { $0.status == .completed }
            .compactMap { $0.distances }
            .reduce(0, +)
    }

    /// Total steps from all completed missions
    var totalSteps: Int {
        recentMissions
            .filter { $0.status == .completed }
            .compactMap { mission in
                if let steps = mission.steps {
                    return Int(steps)
                }
                return nil
            }
            .reduce(0, +)
    }

    // MARK: - Data Fetching

    /// Fetches recent missions for a user from Supabase (only completed missions)
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of missions to fetch (default: 30)
    func fetchRecentMissions(userId: UUID, limit: Int = 30) async {
        isLoading = true
        errorMessage = nil

        do {
            print("📊 Fetching recent missions for stats - User: \(userId)")

            // Convert UUID to lowercase for database query
            let userIdLowercase = userId.uuidString.lowercased()

            // Fetch only completed missions ordered by created_at
            let response: [Mission] = try await supabase
                .from("missions")
                .select()
                .eq("user_id", value: userIdLowercase)
                .eq("status", value: "done") // Only fetch completed missions
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            recentMissions = response

            print("✅ Fetched \(response.count) completed mission(s) for stats")
            print("   Total steps: \(totalSteps)")
            print("   Total distance: \(String(format: "%.2f", totalDistance))km")

        } catch {
            errorMessage = "Failed to fetch missions: \(error.localizedDescription)"
            print("❌ Error fetching missions for stats: \(error)")
            recentMissions = []
        }

        isLoading = false
    }

    /// Fetches missions within a specific date range (only completed missions)
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    func fetchMissionsInDateRange(userId: UUID, startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)

            print("📊 Fetching completed missions in date range: \(startString) to \(endString)")

            let userIdLowercase = userId.uuidString.lowercased()

            let response: [Mission] = try await supabase
                .from("missions")
                .select()
                .eq("user_id", value: userIdLowercase)
                .eq("status", value: "done") // Only fetch completed missions
                .gte("created_at", value: startString)
                .lte("created_at", value: endString)
                .order("created_at", ascending: false)
                .execute()
                .value

            recentMissions = response

            print("✅ Fetched \(response.count) completed mission(s) in date range")

        } catch {
            errorMessage = "Failed to fetch missions: \(error.localizedDescription)"
            print("❌ Error fetching missions in date range: \(error)")
            recentMissions = []
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

    /// Average steps per day for the current missions
    var averageSteps: Double {
        guard !recentMissions.isEmpty else { return 0 }
        return Double(totalSteps) / Double(recentMissions.count)
    }

    /// Average distance per day for the current missions
    var averageDistance: Double {
        guard !recentMissions.isEmpty else { return 0 }
        return totalDistance / Double(recentMissions.count)
    }

    /// Resets the controller state
    func reset() {
        isLoading = false
        errorMessage = nil
        recentMissions = []
    }
}
