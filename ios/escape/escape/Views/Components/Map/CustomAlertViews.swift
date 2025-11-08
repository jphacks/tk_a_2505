//
//  CustomAlertViews.swift
//  escape
//
//  Created by Claude on 11/4/2025.
//

import SwiftUI
import Supabase

// MARK: - Shelter Reached Alert View

struct ShelterReachedAlertView: View {
    @Binding var isPresented: Bool
    let shelterName: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                    onDismiss()
                }

            VStack(spacing: 20) {
                // Success icon with green background
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }

                VStack(spacing: 12) {
                    Text("map.shelter.reached_title", bundle: .main)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(
                        String(
                            format: NSLocalizedString(
                                "map.shelter.reached_message",
                                bundle: .main,
                                comment: ""
                            ),
                            shelterName
                        )
                    )
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                }

                Button(action: {
                    isPresented = false
                    onDismiss()
                }) {
                    Text("map.shelter.ok_button", bundle: .main)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

// MARK: - Zombie Hit Alert View

struct ZombieHitAlertView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 20) {
                // Zombie icon with red background
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "brain.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }

                VStack(spacing: 12) {
                    Text("map.zombie.alert_title", bundle: .main)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("map.zombie.alert_message", bundle: .main)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Button(action: {
                    isPresented = false
                }) {
                    Text("map.shelter.ok_button", bundle: .main)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

// MARK: - Shelter Info Sheet (Zen Mode)

struct ShelterInfoSheet: View {
    let shelter: Shelter
    @State private var shelterBadge: ShelterBadge?
    @State private var hasUserBadge = false
    @State private var isLoadingBadge = false
    @State private var ratingViewModel = RatingViewModel()
    @State private var currentUserId: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with icon
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill((shelter.isShelter == true ? Color("brandRed") : Color("brandOrange")).opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: shelter.isShelter == true ? "building.2.fill" : "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(shelter.isShelter == true ? Color("brandRed") : Color("brandOrange"))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(shelter.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(shelter.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Rating summary - always show (displays empty state if no ratings)
                            if !ratingViewModel.isLoadingRatings {
                                if let summary = ratingViewModel.ratingSummary, summary.hasRatings {
                                    RatingSummaryCard(summary: summary, style: .compact)
                                        .padding(.top, 4)
                                } else {
                                    // Empty state - no ratings yet
                                    HStack(spacing: 4) {
                                        Image(systemName: "star")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("rating.empty.no_ratings_yet", bundle: .main)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }

                    // Navigation to reviews - always show so users can rate
                    if !ratingViewModel.isLoadingRatings {
                        NavigationLink {
                            ShelterReviewsView(shelter: shelter, viewModel: ratingViewModel)
                        } label: {
                            HStack {
                                if let summary = ratingViewModel.ratingSummary, summary.hasRatings {
                                    Text("rating.action.see_all_reviews", bundle: .main)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("rating.action.rate_this_shelter", bundle: .main)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                        }
                    }

                    Divider()

                    // DEBUG PANEL - Shows authorization status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔍 DEBUG INFO")
                            .font(.headline)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 8) {
                            DebugInfoRow(label: "User ID", value: currentUserId)
                            DebugInfoRow(label: "Shelter ID", value: shelter.id)
                            DebugInfoRow(label: "Shelter UUID", value: UUID(uuidString: shelter.id)?.uuidString ?? "Invalid")
                            DebugInfoRow(label: "Has Badge (local)", value: String(hasUserBadge))
                            DebugInfoRow(label: "Has Badge (rating VM)", value: String(ratingViewModel.hasBadge))
                            DebugInfoRow(label: "Can Rate", value: String(ratingViewModel.canRate))
                            DebugInfoRow(label: "Has Existing Rating", value: String(ratingViewModel.hasExistingRating))
                        }
                        .font(.caption)
                        .padding(12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow, lineWidth: 1)
                        )
                    }
                    .padding(.vertical, 8)

                    Divider()

                    // Badge section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("map.shelter_info.badge_title", bundle: .main)
                            .font(.headline)

                        if isLoadingBadge {
                            HStack {
                                ProgressView()
                                Text("map.shelter_info.loading_badge", bundle: .main)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if let badge = shelterBadge {
                            HStack(spacing: 16) {
                                // Badge image or placeholder
                                if let imageUrl = badge.getImageUrl() {
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.2))
                                            ProgressView()
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(12)
                                } else {
                                    Image(systemName: badge.determineIcon())
                                        .font(.system(size: 36))
                                        .foregroundColor(badge.determineColor())
                                        .frame(width: 80, height: 80)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(hasUserBadge ? "map.shelter_info.badge_collected" : "map.shelter_info.badge_not_collected", bundle: .main)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(hasUserBadge ? .green : .orange)

                                        if hasUserBadge {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }

                                    Text("map.shelter_info.badge_hint", bundle: .main)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            // No badge exists yet - show call to action
                            HStack(spacing: 16) {
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color("brandOrange"))
                                    .frame(width: 80, height: 80)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("map.shelter_info.no_badge_title", bundle: .main)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Text("map.shelter_info.no_badge_message", bundle: .main)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()

                    Divider()

                    // Disaster capabilities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("map.pin_details.disaster_coverage", bundle: .main)
                            .font(.headline)

                        VStack(spacing: 12) {
                            CapabilityRow(
                                icon: "building.2.crop.circle",
                                titleKey: "home.disaster.earthquake",
                                isSupported: shelter.isShelter == true ? true : (shelter.isEarthquake ?? false)
                            )

                            CapabilityRow(
                                icon: "water.waves",
                                titleKey: "home.disaster.tsunami",
                                isSupported: shelter.isShelter == true ? true : (shelter.isTsunami ?? false)
                            )

                            CapabilityRow(
                                icon: "drop.fill",
                                titleKey: "home.disaster.flood",
                                isSupported: shelter.isShelter == true ? true : (shelter.isFlood ?? false)
                            )

                            CapabilityRow(
                                icon: "flame.fill",
                                titleKey: "home.disaster.fire",
                                isSupported: shelter.isShelter == true ? true : (shelter.isFire ?? false)
                            )

                            CapabilityRow(
                                icon: "mountain.2.fill",
                                titleKey: "home.disaster.landslide",
                                isSupported: shelter.isShelter == true ? true : (shelter.isLandslide ?? false)
                            )

                            CapabilityRow(
                                icon: "mountain.2.fill",
                                titleKey: "home.disaster.volcano",
                                isSupported: shelter.isShelter == true ? true : (shelter.isVolcano ?? false)
                            )

                            CapabilityRow(
                                icon: "tornado",
                                titleKey: "home.disaster.storm_surge",
                                isSupported: shelter.isShelter == true ? true : (shelter.isStormSurge ?? false)
                            )

                            CapabilityRow(
                                icon: "cloud.rain.fill",
                                titleKey: "home.disaster.inland_flood",
                                isSupported: shelter.isShelter == true ? true : (shelter.isInlandFlood ?? false)
                            )
                        }
                    }

                    // Location info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("badge.location", bundle: .main)
                            .font(.headline)

                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.secondary)
                            Text("Lat: \(shelter.latitude, specifier: "%.4f"), Lon: \(shelter.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "map.shelter_info.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetchUserId()
                await fetchBadgeInfo()
                await loadRatingData()
            }
        }
    }

    private func fetchUserId() async {
        do {
            let user = try await supabase.auth.session.user
            currentUserId = user.id.uuidString
        } catch {
            currentUserId = "Error: \(error.localizedDescription)"
        }
    }

    private func fetchBadgeInfo() async {
        isLoadingBadge = true
        defer { isLoadingBadge = false }

        // Check if shelter.id can be converted to UUID
        guard let shelterUUID = UUID(uuidString: shelter.id) else {
            print("⚠️ Shelter ID is not a valid UUID: \(shelter.id)")
            return
        }

        do {
            let badgeService = BadgeSupabase()

            // Fetch the badge for this shelter
            if let badge = try await badgeService.getBadgeForShelter(shelterId: shelterUUID) {
                shelterBadge = badge

                // Check if the current user has unlocked this badge
                hasUserBadge = try await badgeService.hasUnlockedBadge(badgeId: badge.id)
            } else {
                // No badge exists for this shelter yet
                print("ℹ️ No badge found for shelter: \(shelter.name)")
                shelterBadge = nil
                hasUserBadge = false
            }
        } catch {
            print("❌ Failed to fetch badge info: \(error)")
            shelterBadge = nil
            hasUserBadge = false
        }
    }

    private func loadRatingData() async {
        guard let shelterUUID = UUID(uuidString: shelter.id) else {
            print("⚠️ Cannot load ratings: Shelter ID is not a valid UUID: \(shelter.id)")
            return
        }

        print("✅ Loading rating data for shelter:")
        print("   Shelter name: \(shelter.name)")
        print("   Shelter ID (string): \(shelter.id)")
        print("   Shelter UUID: \(shelterUUID)")

        // Load rating summary and user's rating status
        await ratingViewModel.loadAllData(for: shelterUUID)

        print("   Rating check complete:")
        print("   - Can rate: \(ratingViewModel.canRate)")
        print("   - Has badge: \(ratingViewModel.hasBadge)")
        print("   - Has existing rating: \(ratingViewModel.hasExistingRating)")
    }
}

struct CapabilityRow: View {
    let icon: String
    let titleKey: String
    let isSupported: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 30)

            Text(verbatim: NSLocalizedString(titleKey, bundle: .main, comment: ""))
                .font(.body)

            Spacer()

            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Debug Info Row

struct DebugInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Shelter Reached Alert") {
    ShelterReachedAlertView(
        isPresented: .constant(true),
        shelterName: "Tokyo Central Shelter",
        onDismiss: {}
    )
}

#Preview("Zombie Hit Alert") {
    ZombieHitAlertView(isPresented: .constant(true))
}

#Preview("Shelter Info Sheet") {
    ShelterInfoSheet(
        shelter: Shelter(
            id: "1",
            number: 100,
            commonId: "TC001",
            name: "Tokyo Central Evacuation Center",
            address: "1-2-3 Chiyoda, Tokyo",
            municipality: "Chiyoda-ku",
            isShelter: true,
            isFlood: true,
            isLandslide: false,
            isStormSurge: false,
            isEarthquake: true,
            isTsunami: false,
            isFire: true,
            isInlandFlood: false,
            isVolcano: false,
            isSameAddressAsShelter: true,
            otherMunicipalNotes: nil,
            acceptedPeople: "500",
            latitude: 35.6812,
            longitude: 139.7671,
            remarks: "Main evacuation center",
            lastUpdated: Date()
        )
    )
}
