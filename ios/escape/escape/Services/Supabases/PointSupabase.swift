//
//  PointSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/02.
//

import Foundation
import Supabase

class PointSupabase {
    // MARK: - Create Operations

    /// Adds a point record for a user
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - points: The points to add (positive or negative)
    /// - Returns: The created Point record
    /// - Throws: Database error if creation fails
    func addPointRecord(userId: UUID, points: Int64) async throws -> Point {
        print("💰 Adding point record for user: \(userId), points: \(points)")

        struct PointPayload: Encodable {
            let userId: String
            let point: Int64

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case point
            }
        }

        let payload = PointPayload(
            userId: userId.uuidString.lowercased(),
            point: points
        )

        let response: Point = try await supabase
            .from("points")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        print("✅ Successfully added point record with ID: \(response.id)")

        return response
    }

    // MARK: - Fetch Operations

    /// Gets the total points for a user by summing all point records
    /// - Parameter userId: The user's UUID
    /// - Returns: Total points
    /// - Throws: Database error if fetch fails
    func getTotalPoints(userId: UUID) async throws -> Int64 {
        print("📊 Fetching total points for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [Point] = try await supabase
            .from("points")
            .select()
            .eq("user_id", value: userIdLowercase)
            .execute()
            .value

        let total = response.reduce(0) { $0 + ($1.point ?? 0) }

        print("✅ Total points for user: \(total)")

        return total
    }

    /// Fetches recent point records for a user
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of records to fetch (default: 50)
    /// - Returns: Array of Point objects
    /// - Throws: Database error if fetch fails
    func getRecentPointRecords(userId: UUID, limit: Int = 50) async throws -> [Point] {
        print("📊 Fetching recent point records for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [Point] = try await supabase
            .from("points")
            .select()
            .eq("user_id", value: userIdLowercase)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(response.count) point record(s)")

        return response
    }

    // MARK: - Error Handling

    enum PointError: LocalizedError {
        case creationFailed
        case fetchFailed
        case userNotAuthenticated

        var errorDescription: String? {
            switch self {
            case .creationFailed:
                return "Failed to create point record"
            case .fetchFailed:
                return "Failed to fetch points"
            case .userNotAuthenticated:
                return "User is not authenticated"
            }
        }
    }
}
