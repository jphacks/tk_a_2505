//
//  DistancesHelper.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation

/// Utility class for distance calculations using Haversine formula
class DistancesHelper {
    /// Calculate distance between two coordinates using Haversine formula
    /// - Parameters:
    ///   - lat1: First point latitude
    ///   - lon1: First point longitude
    ///   - lat2: Second point latitude
    ///   - lon2: Second point longitude
    /// - Returns: Distance in kilometers
    static func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371.0 // km

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Calculate distance in meters
    /// - Parameters:
    ///   - lat1: First point latitude
    ///   - lon1: First point longitude
    ///   - lat2: Second point latitude
    ///   - lon2: Second point longitude
    /// - Returns: Distance in meters
    static func calculateDistanceInMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        return calculateDistance(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) * 1000
    }
}
