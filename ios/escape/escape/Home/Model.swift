//
//  Model.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - Badge Model

struct Badge: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    let imageName: String?

    // Shelter related information
    let badgeNumber: String?
    let address: String?
    let municipality: String?
    let isShelter: Bool
    let isFlood: Bool
    let isLandslide: Bool
    let isStormSurge: Bool
    let isEarthquake: Bool
    let isTsunami: Bool
    let isFire: Bool
    let isInlandFlood: Bool
    let isVolcano: Bool
    let latitude: Double?
    let longitude: Double?

    var supportedDisasters: [(icon: String, name: String)] {
        var disasters: [(icon: String, name: String)] = []
        if isEarthquake {
            disasters.append((
                icon: DisasterType.earthquake.emergencyIcon,
                name: String(localized: "home.disaster.earthquake", table: "Localizable")
            ))
        }
        if isFlood {
            disasters.append((
                icon: DisasterType.flood.emergencyIcon,
                name: String(localized: "home.disaster.flood", table: "Localizable")
            ))
        }
        if isFire {
            disasters.append((
                icon: DisasterType.fire.emergencyIcon,
                name: String(localized: "home.disaster.fire", table: "Localizable")
            ))
        }
        if isTsunami {
            disasters.append((
                icon: DisasterType.tsunami.emergencyIcon,
                name: String(localized: "home.disaster.tsunami", table: "Localizable")
            ))
        }
        if isLandslide {
            disasters.append((
                icon: DisasterType.landslide.emergencyIcon,
                name: String(localized: "home.disaster.landslide", table: "Localizable")
            ))
        }
        if isStormSurge {
            disasters.append((
                icon: "wind",
                name: String(localized: "home.disaster.storm_surge", table: "Localizable")
            ))
        }
        if isInlandFlood {
            disasters.append((
                icon: "drop.fill",
                name: String(localized: "home.disaster.inland_flood", table: "Localizable")
            ))
        }
        if isVolcano {
            disasters.append((
                icon: "triangle.fill",
                name: String(localized: "home.disaster.volcano", table: "Localizable")
            ))
        }
        return disasters
    }

    var availableColors: [Color] {
        return [
            Color("brandOrange"),
            Color("brandDarkBlue"),
            Color("brandMediumBlue"),
            Color("brandRed"),
            Color("brandPeach"),
            Color.green,
            Color.purple,
            Color.brown,
            Color.gray,
            Color.blue,
        ]
    }

    var randomColor: Color {
        return availableColors.randomElement() ?? Color("brandOrange")
    }

    static var randomColor: Color {
        let colors = [
            Color("brandOrange"),
            Color("brandDarkBlue"),
            Color("brandMediumBlue"),
            Color("brandRed"),
            Color("brandPeach"),
            Color.green,
            Color.purple,
            Color.brown,
            Color.gray,
            Color.blue,
        ]
        return colors.randomElement() ?? Color("brandOrange")
    }
}
