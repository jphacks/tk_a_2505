//
//  MissionResultModel.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import CoreLocation
import Foundation

/// Represents a mission result record from the database
struct MissionResult: Codable, Identifiable, Equatable {
    let id: UUID
    let missionId: UUID
    let userId: UUID
    let shelterId: UUID?

    // Location Data
    let startLatitude: Double?
    let startLongitude: Double?
    let endLatitude: Double?
    let endLongitude: Double?

    // Performance Metrics
    let actualDistanceMeters: Double?
    let optimalDistanceMeters: Double?
    let steps: Int64?

    // Score Components
    let basePoints: Int64?
    let distancePoints: Int64?
    let bonusPoints: Int64?
    let routeEfficiencyMultiplier: Double?
    let finalPoints: Int64?

    // Timestamps
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case missionId = "mission_id"
        case userId = "user_id"
        case shelterId = "shelter_id"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case endLatitude = "end_latitude"
        case endLongitude = "end_longitude"
        case actualDistanceMeters = "actual_distance_meters"
        case optimalDistanceMeters = "optimal_distance_meters"
        case steps
        case basePoints = "base_points"
        case distancePoints = "distance_points"
        case bonusPoints = "bonus_points"
        case routeEfficiencyMultiplier = "route_efficiency_multiplier"
        case finalPoints = "final_points"
        case createdAt = "created_at"
    }
}

// MARK: - Helpers

extension MissionResult {
    var startLocation: CLLocation? {
        guard let lat = startLatitude, let lng = startLongitude else { return nil }
        return CLLocation(latitude: lat, longitude: lng)
    }

    var endLocation: CLLocation? {
        guard let lat = endLatitude, let lng = endLongitude else { return nil }
        return CLLocation(latitude: lat, longitude: lng)
    }

    var formattedDistance: String {
        guard let distance = actualDistanceMeters else { return "N/A" }
        return String(format: "%.2f km", distance / 1000.0)
    }

    var formattedSteps: String {
        guard let steps = steps else { return "N/A" }
        return NumberFormatter.localizedString(from: NSNumber(value: steps), number: .decimal)
    }

    var routeEfficiencyPercentage: String {
        guard let efficiency = routeEfficiencyMultiplier else { return "N/A" }
        return String(format: "%.0f%%", efficiency * 100)
    }

    var formattedFinalPoints: String {
        guard let points = finalPoints else { return "0" }
        return NumberFormatter.localizedString(from: NSNumber(value: points), number: .decimal)
    }
}

// MARK: - Score Calculator

enum MissionScoreCalculator {
    // Constants
    private static let BASE_POINTS_FIXED: Int64 = 1000
    private static let DISTANCE_MULTIPLIER: Double = 0.5
    private static let NEW_BADGE_BONUS: Int64 = 1500
    private static let MIN_DISTANCE_THRESHOLD: Double = 10.0 // meters

    struct ScoreComponents {
        let basePoints: Int64
        let distancePoints: Int64
        let bonusPoints: Int64
        let routeEfficiencyMultiplier: Double
        let finalPoints: Int64
    }

    /// Calculate final score based on mission data
    static func calculateScore(
        actualDistanceMeters: Double,
        optimalDistanceMeters: Double,
        isNewBadgeCreated: Bool
    ) -> ScoreComponents {
        // Calculate distance points
        let distancePoints = Int64(actualDistanceMeters * DISTANCE_MULTIPLIER)

        // Base Points = Fixed + Distance Points
        let basePoints = BASE_POINTS_FIXED + distancePoints

        // Bonus Points
        let bonusPoints = isNewBadgeCreated ? NEW_BADGE_BONUS : 0

        // Route Efficiency Multiplier (default to 1.0 if distance too short)
        let routeEfficiencyMultiplier = calculateRouteEfficiencyMultiplier(
            actualDistance: actualDistanceMeters,
            optimalDistance: optimalDistanceMeters
        )

        // Final Points = (Base + Bonus) × Route Efficiency
        let finalPoints = Int64(
            Double(basePoints + bonusPoints) * routeEfficiencyMultiplier
        )

        return ScoreComponents(
            basePoints: BASE_POINTS_FIXED,
            distancePoints: distancePoints,
            bonusPoints: bonusPoints,
            routeEfficiencyMultiplier: routeEfficiencyMultiplier,
            finalPoints: finalPoints
        )
    }

    /// Calculate route efficiency multiplier
    /// Formula: Max(0.7, Min(1.0, optimalDistance / actualDistance))
    /// Default: 1.0 for short distances
    private static func calculateRouteEfficiencyMultiplier(
        actualDistance: Double,
        optimalDistance: Double
    ) -> Double {
        // Edge case: actual distance too short - default to 1.0
        if actualDistance < MIN_DISTANCE_THRESHOLD {
            return 1.0
        }

        // Calculate efficiency ratio
        let efficiency = optimalDistance / actualDistance

        // Clamp between 0.7 and 1.0
        return max(0.7, min(1.0, efficiency))
    }
}
