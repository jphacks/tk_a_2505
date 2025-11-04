//
//  ZombieService.swift
//  escape
//
//  Created by Claude on 11/4/2025.
//

import CoreLocation
import Foundation

// MARK: - Zombie Model

struct Zombie: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var angle: Double // Direction of movement
    var speed: Double // Speed in meters per second
}

// MARK: - Zombie Service

@Observable
class ZombieService {
    var zombies: [Zombie] = []
    var hitByZombieIds: Set<UUID> = []
    private var movementTimer: Timer?

    // MARK: - Configuration

    private let zombieCount = 10
    private let minSpawnDistance: Double = 50 // meters
    private let maxSpawnDistance: Double = 300 // meters
    private let minSpeed: Double = 0.5 // m/s
    private let maxSpeed: Double = 2.0 // m/s
    private let hitDistance: Double = 4.0 // meters
    private let followStrength: Double = 0.7
    private let updateInterval: TimeInterval = 1.0

    // MARK: - Public Methods

    /// Spawn zombies around a center location
    func spawnZombies(around center: CLLocationCoordinate2D) {
        zombies.removeAll()
        hitByZombieIds.removeAll()

        for _ in 0 ..< zombieCount {
            let distance = Double.random(in: minSpawnDistance ... maxSpawnDistance)
            let angle = Double.random(in: 0 ... (2 * .pi))

            // Convert distance and angle to coordinate offset
            let latOffset = (distance * cos(angle)) / 111_000 // 1 degree ≈ 111km
            let lonOffset = (distance * sin(angle)) / (111_000 * cos(center.latitude * .pi / 180))

            let zombieCoord = CLLocationCoordinate2D(
                latitude: center.latitude + latOffset,
                longitude: center.longitude + lonOffset
            )

            let zombie = Zombie(
                coordinate: zombieCoord,
                angle: Double.random(in: 0 ... (2 * .pi)),
                speed: Double.random(in: minSpeed ... maxSpeed)
            )

            zombies.append(zombie)
        }

        print("🧟 Spawned \(zombies.count) zombies!")
    }

    /// Start zombie movement toward user location
    func startZombieMovement(
        userLocationProvider: @escaping () -> CLLocation?,
        onZombieHit: @escaping () -> Void
    ) {
        stopZombieMovement()

        movementTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.moveZombies(userLocation: userLocationProvider(), onZombieHit: onZombieHit)
        }
    }

    /// Stop zombie movement
    func stopZombieMovement() {
        movementTimer?.invalidate()
        movementTimer = nil
    }

    /// Clear all zombies
    func clearZombies() {
        stopZombieMovement()
        zombies.removeAll()
        hitByZombieIds.removeAll()
    }

    // MARK: - Private Methods

    private func moveZombies(userLocation: CLLocation?, onZombieHit: @escaping () -> Void) {
        guard let userLocation = userLocation else { return }

        for i in 0 ..< zombies.count {
            // Calculate direction to user
            let deltaLat = userLocation.coordinate.latitude - zombies[i].coordinate.latitude
            let deltaLon = userLocation.coordinate.longitude - zombies[i].coordinate.longitude
            let angleToUser = atan2(deltaLon, deltaLat)

            // Check distance to user
            let distanceToUser = calculateDistance(
                from: zombies[i].coordinate,
                to: userLocation.coordinate
            )

            // If zombie is close to user and hasn't hit before
            if distanceToUser <= hitDistance, !hitByZombieIds.contains(zombies[i].id) {
                hitByZombieIds.insert(zombies[i].id)
                onZombieHit()
                print("🧟 Zombie hit! Distance: \(distanceToUser)m")
            }

            // Mix following behavior with random movement
            let randomAngle = Double.random(in: -0.5 ... 0.5)
            zombies[i].angle = angleToUser * followStrength
                + zombies[i].angle * (1 - followStrength)
                + randomAngle

            // Move zombie based on speed and angle
            let distance = zombies[i].speed * updateInterval
            let latOffset = (distance * cos(zombies[i].angle)) / 111_000
            let lonOffset = (distance * sin(zombies[i].angle))
                / (111_000 * cos(zombies[i].coordinate.latitude * .pi / 180))

            zombies[i].coordinate = CLLocationCoordinate2D(
                latitude: zombies[i].coordinate.latitude + latOffset,
                longitude: zombies[i].coordinate.longitude + lonOffset
            )
        }
    }

    private func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadius = 6_371_000.0 // meters

        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(from.latitude * .pi / 180) * cos(to.latitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}
