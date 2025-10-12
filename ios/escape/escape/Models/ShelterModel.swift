//
//  ShelterModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/11.
//

import Foundation

struct Shelter: Codable, Identifiable, Hashable {
    let id: String
    let number: Int64?
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
        case number
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
    /// If isShelter is true, it supports all disaster types
    /// Zombie type accepts any shelter (even non-shelters)
    func supports(disasterType: DisasterType) -> Bool {
        if disasterType == .zombie {
            return true
        }

        if isShelter == true {
            return true
        }

        // Otherwise check specific disaster type support
        let supported: Bool
        switch disasterType {
        case .flood:
            supported = isFlood == true
        case .landslide:
            supported = isLandslide == true
        case .stormSurge:
            supported = isStormSurge == true
        case .earthquake:
            supported = isEarthquake == true
        case .tsunami:
            supported = isTsunami == true
        case .fire:
            supported = isFire == true
        case .inlandFlood:
            supported = isInlandFlood == true
        case .volcano:
            supported = isVolcano == true
        case .zombie:
            // Already handled above
            supported = true
        }

        return supported
    }
}

// MARK: - Disaster Type Enum

enum DisasterType: String, CaseIterable, Codable {
    case flood = "Flood"
    case landslide = "Landslide"
    case stormSurge = "Storm Surge"
    case earthquake = "Earthquake"
    case tsunami = "Tsunami"
    case fire = "Fire"
    case inlandFlood = "Inland Flood"
    case volcano = "Volcano"
    case zombie = "Zombie"

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
        case .zombie:
            return "cross.case.fill"
        }
    }
}

// MARK: - UI Extensions for DisasterType

import SwiftUI

extension DisasterType {
    var emergencyIcon: String {
        switch self {
        case .earthquake:
            return "house.and.flag.fill"
        case .flood, .inlandFlood:
            return "drop.fill"
        case .fire:
            return "flame.circle.fill"
        case .stormSurge:
            return "wind"
        case .tsunami:
            return "water.waves.and.arrow.up"
        case .landslide:
            return "arrow.down.to.line"
        case .volcano:
            return "smoke.fill"
        case .zombie:
            return "brain.fill"
        }
    }

    var color: Color {
        switch self {
        case .earthquake:
            return Color("brandOrange")
        case .flood, .inlandFlood:
            return Color("brandDarkBlue")
        case .fire:
            return Color("brandRed")
        case .stormSurge:
            return Color("brandMediumBlue")
        case .tsunami:
            return Color("brandDarkBlue")
        case .landslide:
            return Color("brandPeach")
        case .volcano:
            return Color("brandRed")
        case .zombie:
            return Color.green
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .earthquake:
            return [Color("brandOrange"), Color("brandRed")]
        case .flood, .inlandFlood:
            return [Color("brandDarkBlue"), Color("brandMediumBlue")]
        case .fire:
            return [Color("brandRed"), Color("brandOrange")]
        case .stormSurge:
            return [Color("brandMediumBlue"), Color("brandDarkBlue")]
        case .tsunami:
            return [Color("brandDarkBlue"), Color("brandMediumBlue")]
        case .landslide:
            return [Color("brandPeach"), Color("brandOrange")]
        case .volcano:
            return [Color("brandRed"), Color("brandOrange")]
        case .zombie:
            return [Color.green, Color.mint]
        }
    }

    var localizedName: String {
        switch self {
        case .earthquake:
            return String(localized: "home.disaster.earthquake", table: "Localizable")
        case .flood:
            return String(localized: "home.disaster.flood", table: "Localizable")
        case .fire:
            return String(localized: "home.disaster.fire", table: "Localizable")
        case .stormSurge:
            return String(localized: "home.disaster.typhoon", table: "Localizable")
        case .tsunami:
            return String(localized: "home.disaster.tsunami", table: "Localizable")
        case .landslide:
            return String(localized: "home.disaster.landslide", table: "Localizable")
        case .inlandFlood:
            return String(localized: "home.disaster.inland_flood", table: "Localizable")
        case .volcano:
            return String(localized: "home.disaster.volcano", table: "Localizable")
        case .zombie:
            return String(localized: "home.disaster.zombie", table: "Localizable")
        }
    }
}
