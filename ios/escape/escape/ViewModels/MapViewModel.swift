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

    // Mission tracking properties
    var missionStartLocation: CLLocationCoordinate2D?
    var missionStartTime: Date?
    var accumulatedDistance: Double = 0.0
    var previousLocation: CLLocation?
    var createdMissionResult: MissionResult?

    // MARK: - Dependencies

    private let shelterService: ShelterSupabase
    private let mapService: MapService
    private let missionResultService: MissionResultSupabase
    private let authService: AuthSupabase
    private let pointService: PointSupabase
    private let missionService: MissionSupabase

    // MARK: - Initialization

    init(
        shelterService: ShelterSupabase = ShelterSupabase(),
        mapService: MapService = MapService(),
        missionResultService: MissionResultSupabase = MissionResultSupabase(),
        authService: AuthSupabase = AuthSupabase(),
        pointService: PointSupabase = PointSupabase(),
        missionService: MissionSupabase = MissionSupabase()
    ) {
        self.shelterService = shelterService
        self.mapService = mapService
        self.missionResultService = missionResultService
        self.authService = authService
        self.pointService = pointService
        self.missionService = missionService
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

    // MARK: - Mission Result Creation

    /// Create mission result when user completes a mission
    /// - Parameters:
    ///   - mission: The completed mission
    ///   - shelter: The reached shelter
    ///   - startLocation: Starting location coordinates
    ///   - actualDistance: Actual distance traveled in meters
    ///   - steps: Step count
    ///   - isNewBadgeCreated: Whether user created a new badge
    /// - Returns: The created MissionResult
    func createMissionResult(
        mission: Mission,
        shelter: Shelter,
        startLocation: CLLocationCoordinate2D,
        actualDistance: Double,
        steps: Int64?,
        isNewBadgeCreated: Bool
    ) async throws -> MissionResult {
        print("🎯 Creating mission result...")

        // Calculate optimal distance (straight line)
        let endLocation = CLLocationCoordinate2D(
            latitude: shelter.latitude,
            longitude: shelter.longitude
        )
        let optimalDistance = mapService.calculateDistance(
            from: startLocation,
            to: endLocation
        )

        print("📏 Actual distance: \(actualDistance)m")
        print("📏 Optimal distance: \(optimalDistance)m")

        // Calculate score
        let scoreComponents = MissionScoreCalculator.calculateScore(
            actualDistanceMeters: actualDistance,
            optimalDistanceMeters: optimalDistance,
            isNewBadgeCreated: isNewBadgeCreated
        )

        print("🏆 Score breakdown:")
        print("   Base: \(scoreComponents.basePoints)")
        print("   Distance: \(scoreComponents.distancePoints)")
        print("   Bonus: \(scoreComponents.bonusPoints)")
        print("   Efficiency: \(scoreComponents.routeEfficiencyMultiplier)")
        print("   FINAL: \(scoreComponents.finalPoints)")

        // Get current user ID
        let currentUserId = try await authService.getCurrentUserId()

        // Convert shelter.id to UUID
        guard let shelterUUID = UUID(uuidString: shelter.id) else {
            throw MissionResultError.invalidShelterId
        }

        // Save mission result to database
        let result = try await missionResultService.createMissionResultWithScore(
            missionId: mission.id,
            userId: currentUserId,
            shelterId: shelterUUID,
            startLatitude: startLocation.latitude,
            startLongitude: startLocation.longitude,
            endLatitude: endLocation.latitude,
            endLongitude: endLocation.longitude,
            actualDistanceMeters: actualDistance,
            optimalDistanceMeters: optimalDistance,
            steps: steps,
            scoreComponents: scoreComponents
        )

        print("✅ Mission result created with ID: \(result.id)")
        print("   Final score: \(result.finalPoints ?? 0) points")

        return result
    }

    enum MissionResultError: LocalizedError {
        case invalidShelterId
        case noStartLocation

        var errorDescription: String? {
            switch self {
            case .invalidShelterId:
                return "Invalid shelter ID format"
            case .noStartLocation:
                return "No start location available"
            }
        }
    }

    // MARK: - Mission Tracking

    /// Starts tracking a mission when it becomes active
    func startMissionTracking(currentLocation: CLLocation?) {
        guard let location = currentLocation else {
            print("⚠️ Cannot start mission tracking: no location available")
            return
        }

        missionStartLocation = location.coordinate
        missionStartTime = Date()
        accumulatedDistance = 0.0
        previousLocation = location
        print("🎯 Mission tracking started at: \(location.coordinate)")
    }

    /// Updates location tracking during an active mission
    func updateLocationTracking(newLocation: CLLocation) {
        if let previous = previousLocation {
            let distance = newLocation.distance(from: previous)
            accumulatedDistance += distance
            print("📍 Distance increment: \(String(format: "%.2f", distance))m")
            print("📍 Total accumulated distance: \(String(format: "%.2f", accumulatedDistance))m")
        } else {
            print("📍 First location update for this mission")
        }
        previousLocation = newLocation
    }

    /// Handles mission completion when user reaches a shelter
    func handleShelterReached(
        mission: Mission,
        shelter: Shelter,
        currentLocation: CLLocation?,
        onComplete: @escaping (Shelter) -> Void
    ) async {
        // Ensure we have a start location
        var startLocation = missionStartLocation
        if startLocation == nil {
            print("⚠️ No start location recorded, using current location")
            if let current = currentLocation {
                startLocation = current.coordinate
                missionStartLocation = current.coordinate
            } else {
                print("❌ Cannot create mission result: no location available")
                return
            }
        }

        guard let finalStartLocation = startLocation else {
            print("❌ Cannot create mission result: no start location")
            return
        }

        print("🎯 Shelter reached! Creating mission result...")
        print("📊 Mission stats:")
        print("   Start location: \(finalStartLocation)")
        print("   Accumulated distance: \(String(format: "%.2f", accumulatedDistance))m")

        do {
            // Estimate steps based on distance (roughly 1400 steps per km)
            let estimatedSteps: Int64? = accumulatedDistance > 0
                ? Int64((accumulatedDistance / 1000.0) * 1400.0)
                : nil

            print("   Estimated steps: \(estimatedSteps ?? 0)")

            // Calculate optimal distance
            let endLocation = CLLocationCoordinate2D(
                latitude: shelter.latitude,
                longitude: shelter.longitude
            )
            let optimalDistance = mapService.calculateDistance(
                from: finalStartLocation,
                to: endLocation
            )

            print("📏 Actual distance: \(accumulatedDistance)m")
            print("📏 Optimal distance: \(optimalDistance)m")

            // Calculate score
            let scoreComponents = MissionScoreCalculator.calculateScore(
                actualDistanceMeters: accumulatedDistance,
                optimalDistanceMeters: optimalDistance,
                isNewBadgeCreated: false // Will be updated after badge generation
            )

            print("🏆 Score breakdown:")
            print("   Base: \(scoreComponents.basePoints)")
            print("   Distance: \(scoreComponents.distancePoints)")
            print("   Bonus: \(scoreComponents.bonusPoints)")
            print("   Efficiency: \(scoreComponents.routeEfficiencyMultiplier)")
            print("   FINAL: \(scoreComponents.finalPoints)")

            // Get current user ID
            let currentUserId = try await authService.getCurrentUserId()

            // Convert shelter.id to UUID
            guard let shelterUUID = UUID(uuidString: shelter.id) else {
                throw MissionResultError.invalidShelterId
            }

            // Save mission result to database
            let result = try await missionResultService.createMissionResultWithScore(
                missionId: mission.id,
                userId: currentUserId,
                shelterId: shelterUUID,
                startLatitude: finalStartLocation.latitude,
                startLongitude: finalStartLocation.longitude,
                endLatitude: endLocation.latitude,
                endLongitude: endLocation.longitude,
                actualDistanceMeters: accumulatedDistance,
                optimalDistanceMeters: optimalDistance,
                steps: estimatedSteps,
                scoreComponents: scoreComponents
            )

            // Store result for display
            createdMissionResult = result

            // Add point record to database
            if let finalPoints = result.finalPoints {
                _ = try await pointService.addPointRecord(
                    userId: currentUserId,
                    points: finalPoints
                )
                print("💰 Added \(finalPoints) points to user account")
            }

            // Update mission status to completed
            try await missionService.updateMissionStatus(
                missionId: mission.id,
                status: .completed
            )

            print("✅ Mission result created successfully!")
            print("   Final score: \(result.finalPoints ?? 0) points")

            // Notify view to show completion UI
            onComplete(shelter)

        } catch {
            print("❌ Error creating mission result: \(error)")
            errorMessage = "Failed to complete mission: \(error.localizedDescription)"
            // Still notify view to show alert
            onComplete(shelter)
        }
    }

    /// Resets mission tracking when mission ends
    func resetMissionTracking() {
        missionStartLocation = nil
        missionStartTime = nil
        accumulatedDistance = 0.0
        previousLocation = nil
        createdMissionResult = nil
        print("🔄 Mission tracking reset")
    }
}
