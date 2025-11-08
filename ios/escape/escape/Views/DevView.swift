//
//  DevView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Supabase
import SwiftUI

struct DevView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.missionStateService) var missionStateService
    @State private var badgeViewModel = BadgeViewModel()
    @State private var missionGeneratorViewModel = MissionGeneratorViewModel()
    @State private var locationName = ""
    @State private var showImagePreview = false
    @State private var missionContext = ""
    @State private var selectedDisasterType: DisasterType?
    @State private var showMissionResult = false
    @State private var realShelters: [Shelter] = []
    @State private var realBadges: [Badge] = []
    @State private var selectedShelter: Shelter?

    // Developer Settings
    @State private var shelterProximityRadius: Double = DeveloperSettings.shared
        .shelterProximityRadius
    @State private var showRadiusArea: Bool = DeveloperSettings.shared.showRadiusArea

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("dev.location_name", text: $locationName)
                        .autocorrectionDisabled()
                } header: {
                    Text("dev.badge_generator_header")
                        .textCase(nil)
                } footer: {
                    Text("AI will automatically generate the description and color theme")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(action: generateBadge) {
                        HStack {
                            Spacer()
                            if badgeViewModel.isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("dev.generate_badge")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(badgeViewModel.isGenerating || locationName.isEmpty)
                }

                if let errorMessage = badgeViewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }

                if let imageUrl = badgeViewModel.generatedBadgeUrl {
                    Section {
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                case let .success(image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            showImagePreview = true
                                        }
                                case .failure:
                                    Image(systemName: "photo.fill")
                                        .foregroundColor(.gray)
                                        .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }

                            Button(action: {
                                UIPasteboard.general.string = imageUrl
                            }) {
                                Label("dev.copy_url", systemImage: "doc.on.doc")
                            }
                        }
                    } header: {
                        Text("dev.generated_badge")
                    }
                }

                Section {
                    Button("dev.test_korakuen") {
                        loadKorakuenPreset()
                    }

                    Button("dev.clear_fields") {
                        clearFields()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("dev.presets")
                }

                // Developer Settings Section
                developerSettingsSection

                missionParametersSection

                realDataSection

                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Current State:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(missionStateService.currentMissionState.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(stateColor(for: missionStateService.currentMissionState))
                                .cornerRadius(6)
                        }

                        Button(action: generateMission) {
                            HStack {
                                Spacer()
                                if missionGeneratorViewModel.isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Generate Mission")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(missionGeneratorViewModel.isGenerating)

                        Button("Reset Mission") {
                            missionStateService.resetMission()
                            missionGeneratorViewModel.reset()
                            missionContext = ""
                            selectedDisasterType = nil
                        }
                        .foregroundColor(.orange)
                    }

                    if let errorMessage = missionGeneratorViewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Mission Generator")
                }

                // Current Mission Details
                if let mission = missionStateService.currentMission {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            // Title
                            if let title = mission.title {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Title:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                            }

                            // Overview
                            if let overview = mission.overview {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Overview:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(overview)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }

                            Divider()

                            // Disaster Type
                            HStack {
                                Text("Disaster Type:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let disasterType = mission.disasterType {
                                    HStack(spacing: 4) {
                                        Image(systemName: disasterType.iconName)
                                            .font(.caption)
                                        Text(disasterType.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.orange)
                                } else {
                                    Text("None")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Status
                            HStack {
                                Text("Status:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(mission.status.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(stateColor(for: mission.status))
                                    .cornerRadius(4)
                            }

                            Divider()

                            // Note: Stats (steps, distances) are now in mission_results table
                            Text("View mission results for detailed stats")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)

                            Divider()

                            // Metadata
                            VStack(spacing: 4) {
                                HStack {
                                    Text("ID:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(mission.id.uuidString)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Created:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(mission.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Current Mission Details")
                    }
                }
            }
            .navigationTitle("dev.title")
            .onAppear {
                // Initialize developer settings from UserDefaults
                shelterProximityRadius = DeveloperSettings.shared.shelterProximityRadius
                showRadiusArea = DeveloperSettings.shared.showRadiusArea
            }
            .sheet(isPresented: $showImagePreview) {
                if let imageUrl = badgeViewModel.generatedBadgeUrl {
                    ImagePreviewView(imageUrl: imageUrl)
                }
            }
            .sheet(isPresented: $showMissionResult) {
                MissionResultView(
                    mission: sampleMission,
                    shelter: selectedShelter ?? sampleShelter
                )
            }
        }
    }

    private var missionParametersSection: some View {
        Section {
            TextField("Mission context (optional)", text: $missionContext, axis: .vertical)
                .lineLimit(2 ... 4)
                .autocorrectionDisabled()

            Picker("Disaster Type (optional)", selection: $selectedDisasterType) {
                Text("Random").tag(nil as DisasterType?)
                ForEach(DisasterType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type as DisasterType?)
                }
            }
        } header: {
            Text("Mission Parameters")
        }
    }

    private var realDataSection: some View {
        Section {
            Button("dev.load_real_shelters") {
                Task {
                    await loadRealShelters()
                }
            }

            Button("Load Direct Shelters") {
                Task {
                    await loadDirectShelters()
                }
            }

            if !realBadges.isEmpty {
                badgeScrollView
            }

            if !realShelters.isEmpty {
                shelterButtonsView
            }

            Button("dev.test_mission_result") {
                Task {
                    await loadSpecificShelter()
                    showMissionResult = true
                }
            }
            .fontWeight(.semibold)
        } header: {
            Text("dev.ui_components")
        }
    }

    private var developerSettingsSection: some View {
        Section {
            // Shelter Proximity Radius Setting
            HStack {
                Text("Shelter Proximity Radius")
                    .font(.body)
                Spacer()
                Text("\(Int(shelterProximityRadius)) m")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Stepper(
                    value: $shelterProximityRadius,
                    in: 1 ... 100,
                    step: 1
                ) {
                    Text("Shelter Proximity Radius: \(Int(shelterProximityRadius)) m")
                        .font(.body)
                }
                .onChange(of: shelterProximityRadius) { _, newValue in
                    DeveloperSettings.shared.shelterProximityRadius = newValue
                }

                Text("Controls how close you need to be to a shelter to trigger detection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Show Radius Area Toggle
            Toggle(isOn: $showRadiusArea) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Radius Area on Map")
                        .font(.body)
                    Text("Displays a blue circle around your location showing the detection radius")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: showRadiusArea) { _, newValue in
                DeveloperSettings.shared.showRadiusArea = newValue
            }

            Button("Reset to Default") {
                shelterProximityRadius = 10.0
                showRadiusArea = false
                DeveloperSettings.shared.shelterProximityRadius = 10.0
                DeveloperSettings.shared.showRadiusArea = false
            }
            .foregroundColor(.red)
        } header: {
            Text("Map Settings")
        } footer: {
            Text("These settings persist across app launches and affect shelter detection behavior.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var badgeScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(realBadges.prefix(5)) { badge in
                    BadgeItemView(badge: badge)
                        .onTapGesture {
                            handleBadgeTap(badge)
                        }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 200)
    }

    private var shelterButtonsView: some View {
        ForEach(realShelters.prefix(3), id: \.id) { shelter in
            Button("Test: \(shelter.name)") {
                selectedShelter = shelter
                showMissionResult = true
            }
            .font(.caption)
        }
    }

    private func handleBadgeTap(_ badge: Badge) {
        if let shelterId = UUID(uuidString: badge.id),
           let shelter = realShelters.first(where: { $0.id == shelterId.uuidString })
        {
            selectedShelter = shelter
            showMissionResult = true
        }
    }

    private func generateBadge() {
        Task {
            await badgeViewModel.generateBadgeFromLocationName(locationName)
        }
    }

    private func loadKorakuenPreset() {
        locationName = "後楽園"
    }

    private func clearFields() {
        locationName = ""
        badgeViewModel.reset()
    }

    private func generateMission() {
        Task {
            // Generate the mission using the edge function
            let context = missionContext.isEmpty ? nil : missionContext
            await missionGeneratorViewModel.generateMission(
                context: context,
                disasterTypeHint: selectedDisasterType
            )

            // If successful, update the mission state manager
            if let mission = missionGeneratorViewModel.generatedMission {
                missionStateService.updateMission(mission)
            }
        }
    }

    private func stateColor(for state: MissionState) -> Color {
        switch state {
        case .noMission:
            return .gray.opacity(0.2)
        case .inProgress:
            return .blue.opacity(0.2)
        case .active:
            return .green.opacity(0.2)
        case .completed:
            return .purple.opacity(0.2)
        }
    }

    private func loadRealShelters() async {
        do {
            // Load shelter badges with their associated shelter information
            let shelterBadges: [ShelterBadgeWithDetails] =
                try await supabase
                    .from("shelter_badges")
                    .select(
                        """
                            id,
                            badge_name,
                            shelter_id,
                            first_user_id,
                            created_at,
                            shelter:shelters(
                                id,
                                number,
                                common_id,
                                name,
                                address,
                                municipality,
                                is_shelter,
                                is_flood,
                                is_landslide,
                                is_storm_surge,
                                is_earthquake,
                                is_tsunami,
                                is_fire,
                                is_inland_flood,
                                is_volcano,
                                is_same_address_as_shelter,
                                other_municipal_notes,
                                accepted_people,
                                latitude,
                                longitude,
                                remarks,
                                last_updated
                            )
                        """
                    )
                    .limit(5)
                    .execute()
                    .value

            await MainActor.run {
                // Extract shelters and convert shelter badges to UI badges
                realShelters = shelterBadges.compactMap { $0.shelter }
                realBadges = shelterBadges.compactMap { shelterBadgeDetail in
                    guard let shelter = shelterBadgeDetail.shelter else { return nil }

                    // Create a Badge object using shelter information and badge data
                    return Badge(
                        id: shelterBadgeDetail.shelterId.uuidString,
                        name: shelter.name,
                        icon: determineIcon(for: shelterBadgeDetail.badgeName),
                        color: determineColor(for: shelterBadgeDetail.badgeName),
                        isUnlocked: true,
                        imageName: determineImageName(for: shelter.name),
                        imageUrl: constructImageUrl(for: shelterBadgeDetail.badgeName),
                        badgeNumber: shelter.commonId,
                        address: shelter.address,
                        municipality: shelter.municipality,
                        isShelter: shelter.isShelter ?? false,
                        isFlood: shelter.isFlood ?? false,
                        isLandslide: shelter.isLandslide ?? false,
                        isStormSurge: shelter.isStormSurge ?? false,
                        isEarthquake: shelter.isEarthquake ?? false,
                        isTsunami: shelter.isTsunami ?? false,
                        isFire: shelter.isFire ?? false,
                        isInlandFlood: shelter.isInlandFlood ?? false,
                        isVolcano: shelter.isVolcano ?? false,
                        latitude: shelter.latitude,
                        longitude: shelter.longitude,
                        firstUserName: nil
                    )
                }
            }
        } catch {
            print("Failed to load shelter badges: \(error)")
        }
    }

    private func determineIcon(for badgeName: String) -> String {
        let lowerName = badgeName.lowercased()

        if lowerName.contains("first") || lowerName.contains("pioneer") {
            return "star.fill"
        } else if lowerName.contains("shelter") || lowerName.contains("避難所") {
            return "house.fill"
        } else if lowerName.contains("earthquake") || lowerName.contains("地震") {
            return "waveform.path.ecg"
        } else if lowerName.contains("flood") || lowerName.contains("洪水") {
            return "water.waves"
        } else if lowerName.contains("fire") || lowerName.contains("火災") {
            return "flame.fill"
        } else {
            return "medal.fill"
        }
    }

    private func determineColor(for badgeName: String) -> Color {
        let lowerName = badgeName.lowercased()

        if lowerName.contains("first") || lowerName.contains("pioneer") {
            return Color("brandOrange")
        } else if lowerName.contains("earthquake") || lowerName.contains("地震") {
            return Color("brandOrange")
        } else if lowerName.contains("flood") || lowerName.contains("tsunami")
            || lowerName.contains("洪水") || lowerName.contains("津波")
        {
            return Color("brandDarkBlue")
        } else if lowerName.contains("fire") || lowerName.contains("火災") {
            return Color("brandRed")
        } else {
            return Color("brandPeach")
        }
    }

    private func determineImageName(for shelterName: String) -> String? {
        let lowerName = shelterName.lowercased()

        if lowerName.contains("後楽園") || lowerName.contains("korakuen") {
            return "korakuen"
        } else if lowerName.contains("東大") || lowerName.contains("todai") {
            return "todaimae"
        } else if lowerName.contains("ロゴ") || lowerName.contains("logo") {
            return "logo"
        }

        return nil
    }

    private func constructImageUrl(for badgeName: String) -> String? {
        guard !badgeName.isEmpty else { return nil }
        let baseUrl = "https://wmmddehrriniwxsgnwqy.supabase.co/storage/v1/object/public/shelter_badges"
        return "\(baseUrl)/\(badgeName)"
    }

    private func loadDirectShelters() async {
        do {
            // Load shelters directly from shelters table
            let shelters: [Shelter] =
                try await supabase
                    .from("shelters")
                    .select()
                    .limit(10)
                    .execute()
                    .value

            await MainActor.run {
                realShelters = shelters
                realBadges = [] // Clear badges since we're loading shelters directly
                print("Loaded \(shelters.count) direct shelters")
                if let firstShelter = shelters.first {
                    print("First shelter: \(firstShelter.name) - \(firstShelter.address)")
                }
            }
        } catch {
            print("Failed to load direct shelters: \(error)")
        }
    }

    private func loadSpecificShelter() async {
        do {
            // Load the specific shelter by ID from database
            let testShelterId = "808f4c01-049f-4512-b9d2-95540b3fe8d8"
            guard let shelterUUID = UUID(uuidString: testShelterId) else {
                print("Invalid shelter UUID")
                return
            }

            let shelter: Shelter =
                try await supabase
                    .from("shelters")
                    .select()
                    .eq("id", value: shelterUUID)
                    .single()
                    .execute()
                    .value

            await MainActor.run {
                selectedShelter = shelter
                print("Loaded specific shelter: \(shelter.name) - \(shelter.address)")
            }
        } catch {
            print("Failed to load specific shelter: \(error)")
            // Fallback to sample shelter if database fetch fails
            await MainActor.run {
                selectedShelter = sampleShelter
            }
        }
    }

    // MARK: - Sample Data for Testing

    private var sampleMission: Mission {
        Mission(
            id: UUID(),
            userId: UUID(),
            title: "地震避難訓練",
            overview: "マグニチュード7.3の地震が発生しました。最寄りの避難所へ安全に避難してください。",
            disasterType: .earthquake,
            status: .completed,
            createdAt: Date()
        )
    }

    private var sampleShelter: Shelter {
        // Fallback shelter - try to use real data first
        let testShelterId = "808f4c01-049f-4512-b9d2-95540b3fe8d8"

        return Shelter(
            id: testShelterId,
            number: 1,
            commonId: "SAMPLE001",
            name: "サンプル避難所",
            address: "サンプル住所",
            municipality: "サンプル区",
            isShelter: true,
            isFlood: false,
            isLandslide: false,
            isStormSurge: false,
            isEarthquake: true,
            isTsunami: false,
            isFire: true,
            isInlandFlood: false,
            isVolcano: false,
            isSameAddressAsShelter: true,
            otherMunicipalNotes: nil,
            acceptedPeople: "避難住民",
            latitude: 35.7056,
            longitude: 139.7519,
            remarks: "フェッチしたデータを使用することを推奨",
            lastUpdated: Date()
        )
    }
}

struct ImagePreviewView: View {
    let imageUrl: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "photo.fill")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("dev.close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DevView()
}
