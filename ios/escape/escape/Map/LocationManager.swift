//
//  LocationManager.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import Combine
import CoreLocation
import UIKit

enum LocationAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @Published var authorizationStatus: LocationAuthorizationStatus = .notDetermined
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1

        // Set initial authorization status
        updateAuthorizationStatus()
    }

    private func updateAuthorizationStatus() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        case .restricted:
            authorizationStatus = .restricted
        @unknown default:
            authorizationStatus = .notDetermined
        }

        print("Location authorization status: \(status.rawValue) -> \(authorizationStatus)")
    }

    func requestLocationAuthorization() {
        // Check authorization status first before requesting
        let status = locationManager.authorizationStatus
        print("Requesting location authorization. Current status: \(status.rawValue)")

        switch status {
        case .notDetermined:
            // Only request when not determined
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, start updating location
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        case .denied, .restricted:
            print("Location access denied or restricted")
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Authorization changed to: \(manager.authorizationStatus.rawValue)")

        // Update published status
        updateAuthorizationStatus()

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        case .denied, .restricted:
            print("Location access denied or restricted")
            manager.stopUpdatingLocation()
            manager.stopUpdatingHeading()
        case .notDetermined:
            // Waiting for user decision
            break
        @unknown default:
            break
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation
        print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
