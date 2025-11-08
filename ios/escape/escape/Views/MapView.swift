//
//  MapView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: View {
    @StateObject private var locationManager = LocationService()
    @State private var mapViewModel = MapViewModel()
    @State private var zombieService = ZombieService()
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
    @State private var showShelterInfo = false
    @State private var nearestShelter: Shelter?
    @State private var shelterCheckTimer: Timer?
    @State private var isViewActive = false
    @State private var selectedShelter: Shelter?

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
        .overlay {
            if showShelterReachedAlert, let shelter = reachedShelter {
                ShelterReachedAlertView(
                    isPresented: $showShelterReachedAlert,
                    shelterName: shelter.name,
                    onDismiss: {
                        showCompleteView = true
                    }
                )
            }
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
        .overlay {
            if showZombieAlert {
                ZombieHitAlertView(isPresented: $showZombieAlert)
            }
        }
        .sheet(isPresented: $showPinDetailsSheet) {
            pinDetailsSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showShelterInfo) {
            // Show info for either selected shelter (from tap) or nearest shelter (from proximity)
            if let shelter = selectedShelter ?? nearestShelter {
                ShelterInfoSheet(shelter: shelter)
                    .presentationDetents([.medium])
            }
        }
        .onChange(of: showShelterInfo) { _, newValue in
            // Clear selected shelter when sheet is dismissed
            if !newValue {
                selectedShelter = nil
            }
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
        .onChange(of: showCompleteView) { _, newValue in
            // When complete view is dismissed, switch back to zen mode if in mapless mode
            if !newValue && missionStateService.currentGameMode == .mapless {
                missionStateService.updateGameMode(.zen)
            }
        }
        .onAppear {
            isViewActive = true

            if locationManager.authorizationStatus == .notDetermined {
                // Will show permission request view first
            } else if locationManager.authorizationStatus == .authorized {
                locationManager.requestLocationAuthorization()
            }

            // Start Zen mode timer if no mission is active
            if missionStateService.currentMission == nil {
                missionStateService.updateGameMode(.zen)
                startShelterProximityTimer()
            }

            if let location = locationManager.location {
                handleNewLocation(location: location)
            }
        }
        .onDisappear {
            isViewActive = false
            stopShelterProximityTimer()
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

            // Fetch user's unlocked badges to display on map markers
            await mapViewModel.fetchUnlockedBadges()

            // Set disaster type filter based on current mission
            updateShelterFilter()
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

            // If no mission, automatically set to Zen mode and start shelter checking
            if newValue == nil {
                missionStateService.updateGameMode(.zen)
                startShelterProximityTimer()
            } else {
                stopShelterProximityTimer()
            }

            updateShelterFilter()

            // Update game mode in MapViewModel
            mapViewModel.currentGameMode = missionStateService.currentGameMode

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

            // Spawn zombies if zombie mission started (but not in Zen mode)
            if let mission = newValue,
               mission.disasterType == .zombie,
               mission.status == .active || mission.status == .inProgress,
               missionStateService.currentGameMode.hasZombies
            {
                if let location = locationManager.location {
                    zombieService.spawnZombies(around: location.coordinate)
                    zombieService.startZombieMovement(
                        userLocationProvider: { [weak locationManager] in locationManager?.location },
                        onZombieHit: { showZombieAlert = true }
                    )
                }
            } else {
                // Clear zombies if no zombie mission or Zen mode
                zombieService.clearZombies()
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
                radiusMeters: 100
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
        } else if missionStateService.currentGameMode == .zen {
            // In Zen mode, show info when close to any shelter
            checkNearbyShelterId(userLocation: location)
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

    private func checkNearbyShelterId(userLocation: CLLocation) {
        // Only show shelter info if view is active (user is on map tab)
        guard isViewActive else {
            print("🧘 View not active, skipping shelter check")
            return
        }

        // Find nearest shelter within 100 meters (increased for easier testing)
        let detectionRadius = 100.0
        let nearbyShelters = mapViewModel.filteredShelters.filter { shelter in
            let shelterLocation = CLLocation(latitude: shelter.latitude, longitude: shelter.longitude)
            let distance = userLocation.distance(from: shelterLocation)
            return distance <= detectionRadius
        }

        print("🧘 Zen mode check: Found \(nearbyShelters.count) shelters within \(detectionRadius)m")
        print("🧘 Total filtered shelters: \(mapViewModel.filteredShelters.count)")
        print(
            "🧘 User location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        print("🧘 Game mode: \(missionStateService.currentGameMode.rawValue)")

        if let closest = nearbyShelters.first {
            print("🧘 Closest shelter: \(closest.name) at distance")
            // Only show if it's a different shelter or first time
            if nearestShelter?.id != closest.id {
                nearestShelter = closest
                showShelterInfo = true
                print("🧘 Showing shelter info for: \(closest.name)")
            }
        } else {
            nearestShelter = nil
        }
    }

    // MARK: - Shelter Proximity Timer

    private func startShelterProximityTimer() {
        stopShelterProximityTimer()

        // Check every 3 seconds for nearby shelters in Zen mode
        shelterCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // Only check if in Zen mode and location is available
            if missionStateService.currentGameMode == .zen,
               let userLocation = locationManager.location
            {
                checkNearbyShelterId(userLocation: userLocation)
            }
        }

        print("🧘 Started shelter proximity timer for Zen mode")
    }

    private func stopShelterProximityTimer() {
        shelterCheckTimer?.invalidate()
        shelterCheckTimer = nil
        print("🧘 Stopped shelter proximity timer")
    }

    // MARK: - Helper Methods

    /// Updates the shelter filter based on the current mission's disaster type
    private func updateShelterFilter() {
        mapViewModel.clearFilters()

        // In Zen mode, show all shelters (no filtering)
        if missionStateService.currentGameMode == .zen {
            print("   🧘 Zen mode: Showing all shelters")
            return
        }

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
        ZStack {
            if missionStateService.currentGameMode.showsMap {
                // Standard map view
                MapKit.Map(position: $position, interactionModes: .all) {
                    UserAnnotation(anchor: .center)

                    // Display shelter annotations
                    ForEach(mapViewModel.filteredShelters, id: \.id) { shelter in
                        Annotation(
                            shelter.name,
                            coordinate: CLLocationCoordinate2D(
                                latitude: shelter.latitude,
                                longitude: shelter.longitude
                            )
                        ) {
                            Button(action: {
                                // Only allow tapping in Zen mode (no active mission)
                                if missionStateService.currentGameMode == .zen {
                                    selectedShelter = shelter
                                    showShelterInfo = true
                                }
                            }) {
                                // Check if user has unlocked this shelter's badge
                                if let unlockedBadge = mapViewModel.getBadgeForShelter(shelter.id),
                                   let imageUrl = unlockedBadge.getImageUrl()
                                {
                                    // Display badge image for unlocked shelters
                                    ZStack {
                                        // Badge image
                                        AsyncImage(url: URL(string: imageUrl)) { phase in
                                            switch phase {
                                            case .empty:
                                                // Loading state
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 40, height: 40)
                                                    .overlay {
                                                        ProgressView()
                                                            .tint(.white)
                                                    }
                                            case let .success(image):
                                                // Successfully loaded badge image
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                                    .overlay {
                                                        Circle()
                                                            .strokeBorder(Color.white, lineWidth: 2)
                                                    }
                                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                            case .failure:
                                                // Failed to load - show default icon
                                                Circle()
                                                    .fill(
                                                        shelter.isShelter == true ? Color("brandRed") : Color("brandOrange")
                                                    )
                                                    .frame(width: 40, height: 40)
                                                    .overlay {
                                                        Image(
                                                            systemName: shelter.isShelter == true
                                                                ? "building.2.fill" : "mappin.circle.fill"
                                                        )
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.white)
                                                    }
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                } else {
                                    // Default icon for shelters without unlocked badges
                                    ZStack {
                                        Circle()
                                            .fill(shelter.isShelter == true ? Color("brandRed") : Color("brandOrange"))
                                            .frame(width: 32, height: 32)

                                        Image(
                                            systemName: shelter.isShelter == true
                                                ? "building.2.fill" : "mappin.circle.fill"
                                        )
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Display geofence polygons if available
                    ForEach(mapViewModel.geofencePolygons.indices, id: \.self) { index in
                        MapPolygon(coordinates: mapViewModel.geofencePolygons[index])
                            .foregroundStyle(Color.red.opacity(0.25))
                            .stroke(Color.red, lineWidth: 2)
                    }

                    // Display zombies if zombie mission is active
                    ForEach(zombieService.zombies, id: \.id) { zombie in
                        Annotation("", coordinate: zombie.coordinate) {
                            ZStack {
                                // Pulsing outer ring
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 44, height: 44)

                                // Inner circle background
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)

                                // Zombie icon
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 1)
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
            } else {
                // Mapless mode - only show compass and distance info
                VStack {
                    Spacer()

                    VStack(spacing: 32) {
                        // Compass indicator
                        VStack(spacing: 16) {
                            ZStack {
                                // Compass background circle
                                Circle()
                                    .stroke(Color("brandOrange").opacity(0.3), lineWidth: 3)
                                    .frame(width: 120, height: 120)

                                // Compass rose marks
                                ForEach(0 ..< 4) { index in
                                    Rectangle()
                                        .fill(Color("brandOrange").opacity(0.5))
                                        .frame(width: 2, height: 15)
                                        .offset(y: -52.5)
                                        .rotationEffect(.degrees(Double(index) * 90))
                                }

                                // North arrow that rotates based on heading
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color("brandOrange"))
                                    .rotationEffect(.degrees(locationManager.heading?.trueHeading ?? 0))
                                    .animation(.easeInOut(duration: 0.3), value: locationManager.heading?.trueHeading)
                            }

                            // Show heading in degrees
                            if let heading = locationManager.heading {
                                Text("\(Int(heading.trueHeading))°")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("brandOrange"))
                            }

                            Text("map.mapless.compass_hint", bundle: .main)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 32)
                        }

                        // Distance to nearest shelter
                        if let nearestShelter = mapViewModel.filteredShelters.first,
                           let userLocation = locationManager.location
                        {
                            let distance = CLLocation(
                                latitude: nearestShelter.latitude,
                                longitude: nearestShelter.longitude
                            ).distance(from: userLocation)

                            VStack(spacing: 8) {
                                Text("map.mapless.nearest_shelter", bundle: .main)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(String(format: "%.0f m", distance))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("brandRed"))
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
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