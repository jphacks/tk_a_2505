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
    }

    private var mapView: some View {
        Map(position: $position, interactionModes: .all) {
            UserAnnotation(anchor: .center)
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaPadding(.top)
        .padding(.top)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
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
