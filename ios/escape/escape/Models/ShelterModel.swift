//
//  ShelterModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/11.
//

import Foundation

struct Shelter: Codable, Identifiable {
    let id: Int64
    let commonId: String
    let name: String
    let address: String
    let municipality: String?
    let isShelter: Bool?
    let isFlood: Bool?
    let isLandslide: Bool?
    let isStormSurge: Bool?
    let isEarthquake: Bool?
    let isTsunami: Bool?
    let isFire: Bool?
    let isInlandFlood: Bool?
    let isVolcano: Bool?
    let isSameAddressAsShelter: Bool?
    let otherMunicipalNotes: String?
    let acceptedPeople: String?
    let latitude: Double
    let longitude: Double
    let remarks: String?
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case commonId = "common_id"
        case name
        case address
        case municipality
        case isShelter = "is_shelter"
        case isFlood = "is_flood"
        case isLandslide = "is_landslide"
        case isStormSurge = "is_storm_surge"
        case isEarthquake = "is_earthquake"
        case isTsunami = "is_tsunami"
        case isFire = "is_fire"
        case isInlandFlood = "is_inland_flood"
        case isVolcano = "is_volcano"
        case isSameAddressAsShelter = "is_same_address_as_shelter"
        case otherMunicipalNotes = "other_municipal_notes"
        case acceptedPeople = "accepted_people"
        case latitude
        case longitude
        case remarks
        case lastUpdated = "last_updated"
    }
}

// MARK: - Helper Extensions

extension Shelter {
    /// Returns a list of disaster types this shelter supports
    var supportedDisasterTypes: [String] {
        var types: [String] = []

        if isFlood == true { types.append("Flood") }
        if isLandslide == true { types.append("Landslide") }
        if isStormSurge == true { types.append("Storm Surge") }
        if isEarthquake == true { types.append("Earthquake") }
        if isTsunami == true { types.append("Tsunami") }
        if isFire == true { types.append("Fire") }
        if isInlandFlood == true { types.append("Inland Flood") }
        if isVolcano == true { types.append("Volcano") }

        return types
    }

    /// Returns true if the shelter supports the given disaster type
    func supports(disasterType: DisasterType) -> Bool {
        switch disasterType {
        case .flood:
            return isFlood == true
        case .landslide:
            return isLandslide == true
        case .stormSurge:
            return isStormSurge == true
        case .earthquake:
            return isEarthquake == true
        case .tsunami:
            return isTsunami == true
        case .fire:
            return isFire == true
        case .inlandFlood:
            return isInlandFlood == true
        case .volcano:
            return isVolcano == true
        }
    }
}

// MARK: - Disaster Type Enum

enum DisasterType: String, CaseIterable {
    case flood = "Flood"
    case landslide = "Landslide"
    case stormSurge = "Storm Surge"
    case earthquake = "Earthquake"
    case tsunami = "Tsunami"
    case fire = "Fire"
    case inlandFlood = "Inland Flood"
    case volcano = "Volcano"

    var iconName: String {
        switch self {
        case .flood:
            return "water.waves"
        case .landslide:
            return "mountain.2"
        case .stormSurge:
            return "wind"
        case .earthquake:
            return "waveform.path.ecg"
        case .tsunami:
            return "water.waves"
        case .fire:
            return "flame"
        case .inlandFlood:
            return "drop.fill"
        case .volcano:
            return "triangle.fill"
        }
    }
}
