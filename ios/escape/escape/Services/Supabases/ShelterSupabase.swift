//
//  ShelterSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import MapKit
import Supabase

class ShelterSupabase {
    // MARK: - Fetch Operations

    /// Fetch all shelters from Supabase
    /// - Returns: Array of Shelter objects
    /// - Throws: Database error if fetch fails
    func fetchShelters() async throws -> [Shelter] {
        let fetchedShelters: [Shelter] = try await supabase
            .from("shelters")
            .select()
            .execute()
            .value

        return fetchedShelters
    }

    /// Fetch shelters near a specific location within a radius (in kilometers)
    /// - Parameters:
    ///   - latitude: Latitude of the center point
    ///   - longitude: Longitude of the center point
    ///   - radiusKm: Radius in kilometers (default: 50km)
    /// - Returns: Array of Shelter objects within the specified radius
    /// - Throws: Database error if fetch fails
    func fetchNearbyShelters(latitude: Double, longitude: Double, radiusKm: Double = 50) async throws -> [Shelter] {
        // Calculate bounding box
        let latRange = radiusKm / 111.0 // 1 degree latitude ≈ 111 km
        let lonRange = radiusKm / (111.0 * cos(latitude * .pi / 180))

        let minLat = latitude - latRange
        let maxLat = latitude + latRange
        let minLon = longitude - lonRange
        let maxLon = longitude + lonRange

        // Fetch shelters within bounding box
        let fetchedShelters: [Shelter] = try await supabase
            .from("shelters")
            .select()
            .gte("latitude", value: minLat)
            .lte("latitude", value: maxLat)
            .gte("longitude", value: minLon)
            .lte("longitude", value: maxLon)
            .execute()
            .value

        // Further filter by exact distance for accuracy
        let filteredShelters = fetchedShelters.filter { shelter in
            let distance = DistancesHelper.calculateDistance(
                lat1: latitude,
                lon1: longitude,
                lat2: shelter.latitude,
                lon2: shelter.longitude
            )
            return distance <= radiusKm
        }

        return filteredShelters
    }

    /// Fetch a specific shelter by ID (String format)
    /// - Parameter shelterId: The shelter's UUID as a string
    /// - Returns: Shelter object, or nil if not found
    /// - Throws: Database error if fetch fails
    func getShelter(by shelterId: String) async throws -> Shelter? {
        guard let shelterUUID = UUID(uuidString: shelterId) else {
            return nil
        }

        let shelter: Shelter = try await supabase
            .from("shelters")
            .select()
            .eq("id", value: shelterUUID)
            .single()
            .execute()
            .value

        return shelter
    }

    /// Fetch a specific shelter by UUID
    /// - Parameter shelterUUID: The shelter's UUID
    /// - Returns: Shelter object
    /// - Throws: Database error if fetch fails or not found
    func getShelter(by shelterUUID: UUID) async throws -> Shelter {
        let shelter: Shelter = try await supabase
            .from("shelters")
            .select()
            .eq("id", value: shelterUUID)
            .single()
            .execute()
            .value

        return shelter
    }

    /// Verifies if a shelter exists in the database
    /// - Parameter shelterUUID: The shelter's UUID
    /// - Returns: True if shelter exists, false otherwise
    func verifyShelterExists(shelterUUID: UUID) async throws -> Bool {
        do {
            _ = try await getShelter(by: shelterUUID)
            return true
        } catch {
            return false
        }
    }
}
