//
//  MapView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import CoreLocation
import MapKit
import SwiftUI

// MARK: - Zombie Model

struct Zombie: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var angle: Double // Direction of movement
    var speed: Double // Speed in meters per second
}

struct MapView: View {
    @StateObject private var locationManager = LocationService()
    @State private var mapViewModel = MapViewModel()
    @State private var position: MapCameraPosition = .userLocation(
        followsHeading: true,
        fallback: .automatic
    )
    @State private var showShelterReachedAlert = false
    @State private var reachedShelter: Shelter?
    @State private var showDangerZoneAlert = false
    @State private var dangerZoneIndex: Int?
    @State private var showPinDetailsSheet = false
    @State private var showCompleteView = false
    @State private var showZombieAlert = false
    @State private var zombies: [Zombie] = []
    @State private var hitByZombieIds: Set<UUID> = []

    @Environment(\.missionStateService) var missionStateService // need when you want to listen to the mission state changes

    var body: some View {
        ZStack {
            switch locationManager.authorizationStatus {
            case .authorized:
                mapView
            case .notDetermined:
                permissionRequestView
            case .denied, .restricted:
                permissionDeniedView
            }
        }
        .alert(
            String(localized: "map.shelter.reached_title", bundle: .main),
            isPresented: $showShelterReachedAlert,
            presenting: reachedShelter
        ) { _ in
            Button(
                String(localized: "map.shelter.ok_button", bundle: .main),
                role: .cancel
            ) {
                showCompleteView = true
            }
        } message: { shelter in
            Text(
                String(
                    format: NSLocalizedString(
                        "map.shelter.reached_message",
                        bundle: .main,
                        comment: ""
                    ),
                    shelter.name
                )
            )
        }
        .alert(
            String(localized: "map.danger_zone.alert_title", bundle: .main),
            isPresented: $showDangerZoneAlert,
            presenting: dangerZoneIndex
        ) { _ in
            Button(
                String(localized: "map.shelter.ok_button", bundle: .main),
                role: .cancel
            ) {}
        } message: { _ in
            Text(
                String(
                    localized: "map.danger_zone.alert_message",
                    bundle: .main
                )
            )
        }
        .alert(
            String(localized: "map.zombie.alert_title", bundle: .main),
            isPresented: $showZombieAlert
        ) {
            Button(
                String(localized: "map.shelter.ok_button", bundle: .main),
                role: .cancel
            ) {}
        } message: {
            Text(String(localized: "map.zombie.alert_message", bundle: .main))
        }
        .sheet(isPresented: $showPinDetailsSheet) {
            pinDetailsSheet
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showCompleteView) {
            if let shelter = reachedShelter,
               let currentMission = missionStateService.currentMission
            {
                MissionResultView(
                    mission: currentMission,
                    shelter: shelter,
                    missionResult: mapViewModel.createdMissionResult
                )
            }
        }
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                // Will show permission request view first
            } else if locationManager.authorizationStatus == .authorized {
                locationManager.requestLocationAuthorization()
            }
        }
        .task {
            // Fetch shelters near user's location if available
            if let userLocation = locationManager.location {
                // TODO: radius
                await mapViewModel.fetchNearbyShelters(
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude,
                    radiusKm: 1.5
                )

                // Generate random geofence polygons for demo
                //                mapController.generateRandomGeofencePolygons(
                //                    userLatitude: userLocation.coordinate.latitude,
                //                    userLongitude: userLocation.coordinate.longitude
                //                )
            } else {
                // Fallback to fetching all shelters if location not available
                // await mapController.fetchShelters()
            }

            // Set disaster type filter based on current mission
            updateShelterFilter()
        }
        .onAppear {
            if let location = locationManager.location {
                handleNewLocation(location: location)
            }
        }
        .onChange(of: locationManager.location) { _, newValue in
            // Refresh shelters when location updates
            print("AAAA")
            if let location = newValue {
                handleNewLocation(location: location)
            }
        }
        .onChange(of: missionStateService.currentMission) { oldValue, newValue in
            // Update shelter filter when mission changes
            print("BBBBB")
            updateShelterFilter()

            // Initialize mission tracking when mission becomes active
            if let mission = newValue,
               mission.status == .active || mission.status == .inProgress
            {
                // Only initialize if we're starting a NEW mission (not just state change)
                if oldValue?.id != newValue?.id {
                    mapViewModel.startMissionTracking(currentLocation: locationManager.location)
                }
            } else if newValue == nil {
                // Mission was reset/removed - clean up tracking
                mapViewModel.resetMissionTracking()
            }
            // Note: Don't reset tracking when status becomes .completed
            // Tracking data is needed for MissionResultView

            // Spawn zombies if zombie mission started
            if let mission = newValue,
               mission.disasterType == .zombie,
               mission.status == .active || mission.status == .inProgress
            {
                if let location = locationManager.location {
                    spawnZombies(around: location.coordinate)
                    startZombieMovement()
                }
            } else {
                // Clear zombies if no zombie mission
                zombies.removeAll()
            }
        }
    }

    private func handleNewLocation(location: CLLocation) {
        // Track distance during active mission
        if let mission = missionStateService.currentMission,
           mission.status == .active || mission.status == .inProgress
        {
            mapViewModel.updateLocationTracking(newLocation: location)
        }

        Task {
            // TODO: radius
            await mapViewModel.fetchNearbyShelters(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radiusKm: 1.5
            )
        }

        // Check if user has reached any shelter
        // TODO: CHANGE THE NUMBER FOR RADIUS
        print("HERE!!")
        if let mission = missionStateService.currentMission,
           mission.status == .active || mission.status == .inProgress
        {
            if let shelter = mapViewModel.checkShelterProximity(
                userLatitude: location.coordinate.latitude,
                userLongitude: location.coordinate.longitude,
                radiusMeters: 30
            ) {
                Task {
                    await mapViewModel.handleShelterReached(
                        mission: mission,
                        shelter: shelter,
                        currentLocation: location
                    ) { completedShelter in
                        // UI updates after mission completion
                        reachedShelter = completedShelter
                        showShelterReachedAlert = true
                        missionStateService.updateMissionState(.completed)
                    }
                }
            }
        }

        // Check if user has entered any danger zone polygon
        //                if let polygonIndex = mapController.checkPolygonEntry(
        //                    userLatitude: location.coordinate.latitude,
        //                    userLongitude: location.coordinate.longitude
        //                ) {
        //                    dangerZoneIndex = polygonIndex
        //                    showDangerZoneAlert = true
        //                }
    }

    // MARK: - Helper Methods

    /// Updates the shelter filter based on the current mission's disaster type
    private func updateShelterFilter() {
        mapViewModel.clearFilters()

        // If there's an active or in-progress mission with a disaster type, filter shelters
        if let mission = missionStateService.currentMission {
            if mission.status == .active || mission.status == .inProgress {
                if let disasterType = mission.disasterType {
                    mapViewModel.selectedDisasterTypes.insert(disasterType)
                }
            }
        } else {
            print("   ⚠️ No current mission")
        }
    }

    /// Spawn zombies around user location
    private func spawnZombies(
        around center: CLLocationCoordinate2D,
        count: Int = 10
    ) {
        zombies.removeAll()
        hitByZombieIds.removeAll()

        for _ in 0 ..< count {
            // Random distance from user (50m to 300m)
            let distance = Double.random(in: 50 ... 300) // meters
            let angle = Double.random(in: 0 ... (2 * .pi))

            // Convert distance and angle to coordinate offset
            let latOffset = (distance * cos(angle)) / 111_000 // 1 degree ≈ 111km
            let lonOffset =
                (distance * sin(angle))
                    / (111_000 * cos(center.latitude * .pi / 180))

            let zombieCoord = CLLocationCoordinate2D(
                latitude: center.latitude + latOffset,
                longitude: center.longitude + lonOffset
            )

            let zombie = Zombie(
                coordinate: zombieCoord,
                angle: Double.random(in: 0 ... (2 * .pi)),
                speed: Double.random(in: 0.5 ... 2.0) // 0.5-2 m/s
            )

            zombies.append(zombie)
        }

        print("🧟 Spawned \(zombies.count) zombies!")
    }

    /// Start zombie movement timer
    private func startZombieMovement() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            // Stop if no zombie mission
            guard let mission = missionStateService.currentMission,
                  mission.disasterType == .zombie,
                  mission.status == .active || mission.status == .inProgress
            else {
                timer.invalidate()
                return
            }

            moveZombies()
        }
    }

    /// Move zombies toward the user with some randomness
    private func moveZombies() {
        guard let userLocation = locationManager.location else { return }

        for i in 0 ..< zombies.count {
            // Calculate direction to user
            let deltaLat =
                userLocation.coordinate.latitude
                    - zombies[i].coordinate.latitude
            let deltaLon =
                userLocation.coordinate.longitude
                    - zombies[i].coordinate.longitude
            let angleToUser = atan2(deltaLon, deltaLat)

            // Check distance to user
            let distanceToUser = calculateDistanceInMeters(
                from: zombies[i].coordinate,
                to: userLocation.coordinate
            )

            // If zombie is close to user (within 2 meters) and hasn't hit before
            if distanceToUser <= 4, !hitByZombieIds.contains(zombies[i].id) {
                hitByZombieIds.insert(zombies[i].id)
                showZombieAlert = true
                print("🧟 Zombie hit! Distance: \(distanceToUser)m")
            }

            // Mix following behavior with random movement
            // 70% toward user, 30% random
            let followStrength = 0.7
            let randomAngle = Double.random(in: -0.5 ... 0.5) // Add some randomness
            zombies[i].angle =
                angleToUser * followStrength + zombies[i].angle
                    * (1 - followStrength) + randomAngle

            // Move zombie based on speed and angle
            let distance = zombies[i].speed * 1.0 // 1 second interval
            let latOffset = (distance * cos(zombies[i].angle)) / 111_000
            let lonOffset =
                (distance * sin(zombies[i].angle))
                    / (111_000 * cos(zombies[i].coordinate.latitude * .pi / 180))

            zombies[i].coordinate = CLLocationCoordinate2D(
                latitude: zombies[i].coordinate.latitude + latOffset,
                longitude: zombies[i].coordinate.longitude + lonOffset
            )
        }
    }

    /// Calculate distance between two coordinates in meters
    private func calculateDistanceInMeters(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadius = 6_371_000.0 // meters

        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let a =
            sin(dLat / 2) * sin(dLat / 2) + cos(from.latitude * .pi / 180)
                * cos(to.latitude * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Mission details card shown on top left of map
    @ViewBuilder
    private func missionDetailsCard(mission: Mission) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Disaster type badge
            HStack(spacing: 8) {
                if let disasterType = mission.disasterType {
                    Image(systemName: disasterType.emergencyIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)

                    Text(disasterType.localizedName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(mission.disasterType?.color ?? Color.red)
            .cornerRadius(8)

            // Mission title
            if let title = mission.title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            // Current tracking stats (in-progress mission)
            if mapViewModel.accumulatedDistance > 0 {
                HStack(spacing: 16) {
                    // Distance tracked
                    HStack(spacing: 4) {
                        Image(systemName: "map")
                            .font(.caption2)
                        Text(String(format: "%.2f km", mapViewModel.accumulatedDistance / 1000))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
        .frame(maxWidth: 280)
    }

    private var mapView: some View {
        mapContent
            .overlay(alignment: .trailing) {
                mapOverlayContent
            }
    }

    private var mapContent: some View {
        Map(position: $position, interactionModes: .all) {
            UserAnnotation(anchor: .center)

            // Display shelter annotations
            ForEach(mapViewModel.filteredShelters) { shelter in
                Marker(
                    shelter.name,
                    systemImage: shelter.isShelter == true
                        ? "building.2.fill" : "mappin.circle.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: shelter.latitude,
                        longitude: shelter.longitude
                    )
                )
                .tint(
                    shelter.isShelter == true
                        ? Color("brandRed") : Color("brandOrange")
                )
                .tag(shelter)
            }

            // Display geofence polygons if available
            ForEach(mapViewModel.geofencePolygons.indices, id: \.self) {
                index in
                MapPolygon(coordinates: mapViewModel.geofencePolygons[index])
                    .foregroundStyle(Color.red.opacity(0.25))
                    .stroke(Color.red, lineWidth: 2)
            }

            // Display zombies if zombie mission is active
            ForEach(zombies) { zombie in
                Annotation("", coordinate: zombie.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 36, height: 36)

                        Image(systemName: "brain.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaPadding(.top)
        .padding(.top)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    private var mapOverlayContent: some View {
        VStack {
            if mapViewModel.isLoading {
                ProgressView()
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 2)
            }

            if let mission = missionStateService.currentMission {
                emergencyOverlayView(for: mission)
            }

            pinDetailsButton
        }
        .padding(.trailing)
    }

    private func emergencyOverlayView(for mission: Mission) -> some View {
        EmergencyOverlay(
            disasterType: mission.disasterType ?? .earthquake,
            evacuationRegion: "Mission Area",
            status: .active,
            onTap: {
                print("Emergency overlay tapped")
            }
        )
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8),
            value: missionStateService.currentMissionState
        )
    }

    private var pinDetailsButton: some View {
        Button(action: {
            showPinDetailsSheet = true
        }) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.primary)
                .frame(width: 50, height: 50)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding(.bottom, 16)
    }

    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("map.permission.request_title", bundle: .main)
                    .font(.title)
                    .fontWeight(.bold)

                Text("map.permission.request_description", bundle: .main)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                locationManager.requestLocationAuthorization()
            }) {
                Text("map.permission.enable_button", bundle: .main)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            VStack(spacing: 12) {
                Text("map.permission.denied_title", bundle: .main)
                    .font(.title)
                    .fontWeight(.bold)

                Text("map.permission.denied_description", bundle: .main)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                locationManager.openSettings()
            }) {
                Text("map.permission.open_settings_button", bundle: .main)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var pinDetailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("map.pin_details.legend_title", bundle: .main)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)

                    // Shelter (Red) Pin
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color("brandRed"))
                                .frame(width: 50, height: 50)
                                .background(Color("brandRed").opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    "map.pin_details.hinanjo.title",
                                    bundle: .main
                                )
                                .font(.headline)
                                .fontWeight(.semibold)

                                Text(
                                    "map.pin_details.hinanjo.subtitle",
                                    bundle: .main
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }

                        Text(
                            "map.pin_details.hinanjo.description",
                            bundle: .main
                        )
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.leading, 66)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Non-Shelter (Orange) Pin
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color("brandOrange"))
                                .frame(width: 50, height: 50)
                                .background(Color("brandOrange").opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    "map.pin_details.hinanbasho.title",
                                    bundle: .main
                                )
                                .font(.headline)
                                .fontWeight(.semibold)

                                Text(
                                    "map.pin_details.hinanbasho.subtitle",
                                    bundle: .main
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }

                        Text(
                            "map.pin_details.hinanbasho.description",
                            bundle: .main
                        )
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.leading, 66)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(
                String(
                    localized: "map.pin_details.navigation_title",
                    bundle: .main
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        String(localized: "map.pin_details.done", bundle: .main)
                    ) {
                        showPinDetailsSheet = false
                    }
                }
            }
        }
    }
}

#Preview {
    MapView()
}
