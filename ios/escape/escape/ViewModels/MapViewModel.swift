//
//  MapViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import MapKit
import SwiftUI

@MainActor
@Observable
class MapViewModel {
    var shelters: [Shelter] = []
    var isLoading = false
    var errorMessage: String?
    var selectedDisasterTypes: Set<DisasterType> = []
    var reachedShelters: Set<String> = [] // Track shelters user has reached

    // Geofence properties - multiple polygons
    var geofencePolygons: [[CLLocationCoordinate2D]] = []
    var enteredPolygons: Set<Int> = [] // Track which polygons user has entered

    // MARK: - Dependencies

    private let shelterService: ShelterSupabase
    private let mapService: MapService

    // MARK: - Initialization

    init(
        shelterService: ShelterSupabase = ShelterSupabase(),
        mapService: MapService = MapService()
    ) {
        self.shelterService = shelterService
        self.mapService = mapService
    }

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

    // MARK: - Shelter Fetching

    /// Fetch all shelters from Supabase
    func fetchShelters() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            shelters = try await shelterService.fetchShelters()
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
            shelters = try await shelterService.fetchNearbyShelters(
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm
            )
        } catch {
            debugPrint("Error fetching nearby shelters: \(error)")
            errorMessage = "Failed to load nearby shelters. Please try again."
        }
    }

    // MARK: - Filter Management

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

    // MARK: - Proximity Checking (delegates to MapService)

    /// Check if user has reached any shelters within a specified radius (in meters)
    /// Returns the shelter if reached and not previously tracked, nil otherwise
    /// Only checks filtered shelters (based on current disaster type)
    func checkShelterProximity(userLatitude: Double, userLongitude: Double, radiusMeters: Double = 50.0) -> Shelter? {
        let shelter = mapService.checkShelterProximity(
            shelters: filteredShelters,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            radiusMeters: radiusMeters,
            reachedShelters: reachedShelters
        )

        // Update state if shelter was reached
        if let reachedShelter = shelter {
            reachedShelters.insert(reachedShelter.id)
        }

        return shelter
    }

    /// Reset reached shelters tracking
    func resetReachedShelters() {
        reachedShelters.removeAll()
    }

    // MARK: - Geofence Management (delegates to MapService)

    /// Generate multiple random polygons around the user's location
    func generateRandomGeofencePolygons(userLatitude: Double, userLongitude: Double) {
        geofencePolygons = mapService.generateRandomGeofencePolygons(
            userLatitude: userLatitude,
            userLongitude: userLongitude
        )
    }

    /// Clear all geofence polygons
    func clearGeofence() {
        geofencePolygons.removeAll()
        enteredPolygons.removeAll()
    }

    /// Check if user location is inside any danger zone polygon
    /// Returns the index of the first polygon entered (if not already tracked)
    func checkPolygonEntry(userLatitude: Double, userLongitude: Double) -> Int? {
        let index = mapService.checkPolygonEntry(
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            polygons: geofencePolygons,
            enteredPolygons: enteredPolygons
        )

        // Update state if polygon was entered
        if let enteredIndex = index {
            enteredPolygons.insert(enteredIndex)
        }

        return index
    }

    /// Reset entered polygons tracking
    func resetEnteredPolygons() {
        enteredPolygons.removeAll()
    }
}
