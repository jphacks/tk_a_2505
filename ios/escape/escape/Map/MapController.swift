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

    /// Filtered shelters based on selected disaster types
    var filteredShelters: [Shelter] {
        if selectedDisasterTypes.isEmpty {
            return shelters
        }
        return shelters.filter { shelter in
            selectedDisasterTypes.contains { disasterType in
                shelter.supports(disasterType: disasterType)
            }
        }
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
}
