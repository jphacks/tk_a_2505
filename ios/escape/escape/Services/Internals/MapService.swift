//
//  MapService.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import MapKit

/// Service for map-related business logic (proximity checks, geofencing, distance calculations)
class MapService {
    // MARK: - Distance Calculation

    /// Calculate straight-line distance between two coordinates (in meters)
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) // Returns distance in meters
    }

    // MARK: - Proximity Checking

    /// Check if user has reached any shelters within a specified radius (in meters)
    /// Returns the shelter if reached and not previously tracked, nil otherwise
    /// Only checks filtered shelters (based on current disaster type)
    func checkShelterProximity(
        shelters: [Shelter],
        userLatitude: Double,
        userLongitude: Double,
        radiusMeters: Double,
        reachedShelters: Set<String>
    ) -> Shelter? {
        print("🔍 Checking shelter proximity:")
        print("   Checking \(shelters.count) shelters")
        print("   Radius: \(radiusMeters)m")

        for shelter in shelters {
            // Skip if already reached
            if reachedShelters.contains(shelter.id) {
                continue
            }

            let distanceKm = DistancesHelper.calculateDistance(
                lat1: userLatitude,
                lon1: userLongitude,
                lat2: shelter.latitude,
                lon2: shelter.longitude
            )

            let distanceMeters = distanceKm * 1000

            print("   Shelter: '\(shelter.name)' - Distance: \(String(format: "%.1f", distanceMeters))m")

            if distanceMeters <= radiusMeters {
                print("   ✅ REACHED SHELTER: '\(shelter.name)'")
                return shelter
            }
        }
        print("   ❌ No shelter within radius")
        return nil
    }

    // MARK: - Geofence Generation

    /// Generate multiple random polygons around the user's location
    func generateRandomGeofencePolygons(userLatitude: Double, userLongitude: Double) -> [[CLLocationCoordinate2D]] {
        var polygons: [[CLLocationCoordinate2D]] = []

        // Generate 5-8 random polygons
        let polygonCount = Int.random(in: 5 ... 8)

        for _ in 0 ..< polygonCount {
            // Random polygon size (50-150m radius)
            let polygonSize = Double.random(in: 50 ... 150) // meters

            // Random offset from user (100m to 800m away)
            let offsetDistance = Double.random(in: 100 ... 800)
            let randomAngle = Double.random(in: 0 ... (2 * .pi))

            // Calculate center point offset in degrees
            let latOffset = (offsetDistance * cos(randomAngle)) / 111_000
            let lonOffset = (offsetDistance * sin(randomAngle)) / (111_000 * cos(userLatitude * .pi / 180))

            let centerLat = userLatitude + latOffset
            let centerLon = userLongitude + lonOffset

            // Create irregular polygon with 4-7 sides
            let sides = Int.random(in: 4 ... 7)
            var polygonPoints: [CLLocationCoordinate2D] = []

            for i in 0 ..< sides {
                let angle = (Double(i) / Double(sides)) * 2 * .pi

                // Add some randomness to the radius for irregular shape
                let radiusVariation = Double.random(in: 0.7 ... 1.3)
                let pointRadius = polygonSize * radiusVariation

                // Calculate point coordinates
                let pointLatOffset = (pointRadius * cos(angle)) / 111_000
                let pointLonOffset = (pointRadius * sin(angle)) / (111_000 * cos(centerLat * .pi / 180))

                let coordinate = CLLocationCoordinate2D(
                    latitude: centerLat + pointLatOffset,
                    longitude: centerLon + pointLonOffset
                )
                polygonPoints.append(coordinate)
            }

            polygons.append(polygonPoints)
        }

        print("Generated \(polygons.count) random danger zone polygons")
        return polygons
    }

    // MARK: - Polygon Checking

    /// Check if user location is inside any danger zone polygon
    /// Returns the index of the first polygon entered (if not already tracked)
    func checkPolygonEntry(
        userLatitude: Double,
        userLongitude: Double,
        polygons: [[CLLocationCoordinate2D]],
        enteredPolygons: Set<Int>
    ) -> Int? {
        let userPoint = CLLocationCoordinate2D(latitude: userLatitude, longitude: userLongitude)

        for (index, polygon) in polygons.enumerated() {
            // Skip if already entered this polygon
            if enteredPolygons.contains(index) {
                continue
            }

            // Check if point is inside polygon using ray casting algorithm
            if isPointInPolygon(point: userPoint, polygon: polygon) {
                return index
            }
        }

        return nil
    }

    /// Ray casting algorithm to determine if a point is inside a polygon
    private func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        var j = polygon.count - 1

        for i in 0 ..< polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            let intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
                (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)

            if intersect {
                inside.toggle()
            }

            j = i
        }

        return inside
    }
}
