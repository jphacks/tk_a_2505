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
                await mapController.fetchNearbyShelters(
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude,
                    radiusKm: 1.5
                )
            } else {
                // Fallback to fetching all shelters if location not available
                // await mapController.fetchShelters()
            }
        }
        .onChange(of: locationManager.location) { _, newValue in
            // Refresh shelters when location updates
            if let location = newValue {
                Task {
                    await mapController.fetchNearbyShelters(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        radiusKm: 1.5
                    )
                }
            }
        }
    }

    private var mapView: some View {
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
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaPadding(.top)
        .padding(.top)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()

            if mapController.isLoading {
                ProgressView()
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 2)
            }
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
}

#Preview {
    MapView()
}
