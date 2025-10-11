//
//  MapView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        var locationManager: CLLocationManager
        var hasSetInitialLocation = false
        weak var mapView: MKMapView?

        init(_ parent: MapView) {
            self.parent = parent
            locationManager = CLLocationManager()
            super.init()

            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 10
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                manager.stopUpdatingLocation()
                manager.stopUpdatingHeading()
            }
        }

        func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last, !hasSetInitialLocation else { return }

            // Set initial location only once
            guard let mapView = mapView else { return }

            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
            hasSetInitialLocation = true
        }

        func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            guard let mapView = mapView else { return }

            // Update map camera heading if in follow mode
            if mapView.userTrackingMode == .followWithHeading {
                let heading = newHeading.magneticHeading
                mapView.camera.heading = heading
            }
        }

        @objc func locationButtonTapped() {
            guard let location = locationManager.location else { return }
            guard let mapView = mapView else { return }

            // Set tracking mode to follow with heading (shows blue beam)
            mapView.setUserTrackingMode(.followWithHeading, animated: true)

            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false

        // Store reference in coordinator
        context.coordinator.mapView = mapView

        // Request location authorization
        context.coordinator.locationManager.requestWhenInUseAuthorization()

        // Setup compass button
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible
        compass.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(compass)

        // Setup location button
        let locationButton = createLocationButton(coordinator: context.coordinator)
        mapView.addSubview(locationButton)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Compass
            compass.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 20),
            compass.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),

            // Location button
            locationButton.topAnchor.constraint(equalTo: compass.bottomAnchor, constant: 20),
            locationButton.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            locationButton.widthAnchor.constraint(equalToConstant: 40),
            locationButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        return mapView
    }

    func updateUIView(_: MKMapView, context _: Context) {
        // Update map view if needed
    }

    private func createLocationButton(coordinator: Coordinator) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4

        let image = UIImage(systemName: "location.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(coordinator, action: #selector(Coordinator.locationButtonTapped), for: .touchUpInside)

        return button
    }
}

#Preview {
    MapView()
}
