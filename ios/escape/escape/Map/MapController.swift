//
//  MapController.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/12.
//

import MapKit
import Supabase
import SwiftUI

@MainActor
@Observable
class MapController {
    var shelters: [Shelter] = []
    var isLoading = false
    var errorMessage: String?
    var selectedDisasterTypes: Set<DisasterType> = []
    var reachedShelters: Set<String> = [] // Track shelters user has reached

    // Geofence properties - multiple polygons
    var geofencePolygons: [[CLLocationCoordinate2D]] = []
    var enteredPolygons: Set<Int> = [] // Track which polygons user has entered

    /// Filtered shelters based on selected disaster types
    var filteredShelters: [Shelter] {
        print("🔍 Filtering shelters:")
        print("   Total shelters: \(shelters.count)")
        print("   Selected disaster types: \(selectedDisasterTypes.map { $0.rawValue })")

        if selectedDisasterTypes.isEmpty {
            print("   ✅ No filters, returning all \(shelters.count) shelters")
            return shelters
        }

        let filtered = shelters.filter { shelter in
            let supports = selectedDisasterTypes.contains { disasterType in
                shelter.supports(disasterType: disasterType)
            }
            return supports
        }

        print("   ✅ Filtered to \(filtered.count) shelters")
        print("   Sample shelter - Name: \(filtered.first?.name ?? "none"), isShelter: \(filtered.first?.isShelter ?? false)")

        return filtered
    }

    /// Fetch all shelters from Supabase
    func fetchShelters() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedShelters: [Shelter] = try await supabase
                .from("shelters")
                .select()
                .execute()
                .value

            shelters = fetchedShelters
        } catch {
            debugPrint("Error fetching shelters: \(error)")
            errorMessage = "Failed to load shelters. Please try again."
        }
    }

    /// Fetch shelters near a specific location within a radius (in kilometers)
    func fetchNearbyShelters(latitude: Double, longitude: Double, radiusKm: Double = 50) async {
        print("fetching nearby shelther")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Calculate bounding box
            let latRange = radiusKm / 111.0 // 1 degree latitude ≈ 111 km
            let lonRange = radiusKm / (111.0 * cos(latitude * .pi / 180))

            let minLat = latitude - latRange
            let maxLat = latitude + latRange
            let minLon = longitude - lonRange
            let maxLon = longitude + lonRange

            // Fetch shelters within bounding box
            let fetchedShelters: [Shelter] = try await supabase
                .from("shelters")
                .select()
                .gte("latitude", value: minLat)
                .lte("latitude", value: maxLat)
                .gte("longitude", value: minLon)
                .lte("longitude", value: maxLon)
                .execute()
                .value

            // Further filter by exact distance for accuracy
            shelters = fetchedShelters.filter { shelter in
                let distance = calculateDistance(
                    lat1: latitude,
                    lon1: longitude,
                    lat2: shelter.latitude,
                    lon2: shelter.longitude
                )
                return distance <= radiusKm
            }
        } catch {
            debugPrint("Error fetching nearby shelters: \(error)")
            errorMessage = "Failed to load nearby shelters. Please try again."
        }
    }

    /// Calculate distance between two coordinates using Haversine formula (returns km)
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371.0 // km

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Toggle disaster type filter
    func toggleDisasterType(_ type: DisasterType) {
        if selectedDisasterTypes.contains(type) {
            selectedDisasterTypes.remove(type)
        } else {
            selectedDisasterTypes.insert(type)
        }
    }

    /// Clear all filters
    func clearFilters() {
        selectedDisasterTypes.removeAll()
    }

    /// Check if user has reached any shelters within a specified radius (in meters)
    /// Returns the shelter if reached and not previously tracked, nil otherwise
    func checkShelterProximity(userLatitude: Double, userLongitude: Double, radiusMeters: Double = 50.0) -> Shelter? {
        for shelter in shelters {
            // Skip if already reached
            if reachedShelters.contains(shelter.id) {
                continue
            }

            let distanceKm = calculateDistance(
                lat1: userLatitude,
                lon1: userLongitude,
                lat2: shelter.latitude,
                lon2: shelter.longitude
            )

            let distanceMeters = distanceKm * 1000

            if distanceMeters <= radiusMeters {
                reachedShelters.insert(shelter.id)
                return shelter
            }
        }
        return nil
    }

    /// Reset reached shelters tracking
    func resetReachedShelters() {
        reachedShelters.removeAll()
    }

    /// Generate multiple random polygons around the user's location
    func generateRandomGeofencePolygons(userLatitude: Double, userLongitude: Double) {
        geofencePolygons.removeAll()

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

            geofencePolygons.append(polygonPoints)
        }

        print("Generated \(geofencePolygons.count) random danger zone polygons")
    }

    /// Clear all geofence polygons
    func clearGeofence() {
        geofencePolygons.removeAll()
        enteredPolygons.removeAll()
    }

    /// Check if user location is inside any danger zone polygon
    /// Returns the index of the first polygon entered (if not already tracked)
    func checkPolygonEntry(userLatitude: Double, userLongitude: Double) -> Int? {
        let userPoint = CLLocationCoordinate2D(latitude: userLatitude, longitude: userLongitude)

        for (index, polygon) in geofencePolygons.enumerated() {
            // Skip if already entered this polygon
            if enteredPolygons.contains(index) {
                continue
            }

            // Check if point is inside polygon using ray casting algorithm
            if isPointInPolygon(point: userPoint, polygon: polygon) {
                enteredPolygons.insert(index)
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

    /// Reset entered polygons tracking
    func resetEnteredPolygons() {
        enteredPolygons.removeAll()
    }
}
