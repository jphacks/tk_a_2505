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
    @StateObject private var locationManager = LocationManager()
    @State private var mapController = MapController()
    @State private var position: MapCameraPosition = .userLocation(
        followsHeading: true,
        fallback: .automatic
    )
    @State private var showShelterReachedAlert = false
    @State private var reachedShelter: Shelter?
    @State private var showDangerZoneAlert = false
    @State private var dangerZoneIndex: Int?
    @State private var showPinDetailsSheet = false
    @Environment(\.missionStateManager) var missionStateManager

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
            Button(String(localized: "map.shelter.ok_button", bundle: .main), role: .cancel) {}
        } message: { shelter in
            Text(String(format: NSLocalizedString("map.shelter.reached_message", bundle: .main, comment: ""), shelter.name))
        }
        .alert(
            String(localized: "map.danger_zone.alert_title", bundle: .main),
            isPresented: $showDangerZoneAlert,
            presenting: dangerZoneIndex
        ) { _ in
            Button(String(localized: "map.shelter.ok_button", bundle: .main), role: .cancel) {}
        } message: { _ in
            Text(String(localized: "map.danger_zone.alert_message", bundle: .main))
        }
        .sheet(isPresented: $showPinDetailsSheet) {
            pinDetailsSheet
                .presentationDetents([.medium, .large])
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
                await mapController.fetchNearbyShelters(
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
        .onChange(of: locationManager.location) { _, newValue in
            // Refresh shelters when location updates
            if let location = newValue {
                Task {
                    // TODO: radius
                    await mapController.fetchNearbyShelters(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        radiusKm: 1.5
                    )
                }

                // Check if user has reached any shelter
                // TODO: CHANGE THE NUMBER FOR RADIUS
                if missionStateManager.currentMissionState == .inProgress {
                    if let shelter = mapController.checkShelterProximity(
                        userLatitude: location.coordinate.latitude,
                        userLongitude: location.coordinate.longitude,
                        radiusMeters: 1.0
                    ) {
                        reachedShelter = shelter
                        showShelterReachedAlert = true
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
        }
        .onChange(of: missionStateManager.currentMission) {
            // Update shelter filter when mission changes
            updateShelterFilter()
        }
    }

    // MARK: - Helper Methods

    /// Updates the shelter filter based on the current mission's disaster type
    private func updateShelterFilter() {
        print("🔄 updateShelterFilter called")

        // Clear existing filters first
        mapController.clearFilters()
        print("   Cleared existing filters")

        // If there's an active or in-progress mission with a disaster type, filter shelters
        if let mission = missionStateManager.currentMission {
            print("   Current mission found:")
            print("   - Status: \(mission.status.rawValue)")
            print("   - Disaster type: \(mission.disasterType?.rawValue ?? "nil")")

            if mission.status == .active || mission.status == .inProgress {
                if let disasterType = mission.disasterType {
                    mapController.selectedDisasterTypes.insert(disasterType)
                    print("   ✅ Set disaster type filter: \(disasterType.rawValue)")
                } else {
                    print("   ⚠️ Mission has no disaster type")
                }
            } else {
                print("   ⚠️ Mission is not active or in progress")
            }
        } else {
            print("   ⚠️ No current mission")
        }
        // Otherwise show all shelters (no filter)
    }

    private var mapView: some View {
        // Map layer
        Map(position: $position, interactionModes: .all) {
            UserAnnotation(anchor: .center)

            // Display shelter annotations
            ForEach(mapController.filteredShelters) { shelter in
                Marker(
                    shelter.name,
                    systemImage: shelter.isShelter == true ? "building.2.fill" : "mappin.circle.fill",
                    coordinate: CLLocationCoordinate2D(latitude: shelter.latitude, longitude: shelter.longitude)
                )
                .tint(shelter.isShelter == true ? Color("brandRed") : Color("brandOrange"))
                .tag(shelter)
            }

            // Display geofence polygons if available
            ForEach(mapController.geofencePolygons.indices, id: \.self) { index in
                MapPolygon(coordinates: mapController.geofencePolygons[index])
                    .foregroundStyle(Color.red.opacity(0.25))
                    .stroke(Color.red, lineWidth: 2)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaPadding(.top)
        .padding(.top)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }

        .overlay(alignment: .trailing) {
            VStack {
                if mapController.isLoading {
                    ProgressView()
                        .padding(8)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                }

                if missionStateManager.currentMissionState == .active,
                   let mission = missionStateManager.currentMission
                {
                    EmergencyOverlay(
                        disasterType: mission.disasterType ?? .earthquake,
                        evacuationRegion: mission.evacuationRegion ?? "Unknown Region",
                        status: .active,
                        onTap: {
                            // TODO: Add action when tapped
                            print("Emergency overlay tapped")
                        }
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: missionStateManager.currentMissionState)
                }

                // Pin details button
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
            .padding(.trailing)
        }
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
                                Text("map.pin_details.hinanjo.title", bundle: .main)
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text("map.pin_details.hinanjo.subtitle", bundle: .main)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("map.pin_details.hinanjo.description", bundle: .main)
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
                                Text("map.pin_details.hinanbasho.title", bundle: .main)
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text("map.pin_details.hinanbasho.subtitle", bundle: .main)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("map.pin_details.hinanbasho.description", bundle: .main)
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
            .navigationTitle(String(localized: "map.pin_details.navigation_title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "map.pin_details.done", bundle: .main)) {
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
