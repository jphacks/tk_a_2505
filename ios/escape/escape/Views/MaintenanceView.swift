//
//  MaintenanceView.swift
//  escape
//
//  Created by Claude on 1/11/2025.
//

import SwiftUI

struct MaintenanceView: View {
    let message: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            // Title
            Text("maintenance_mode_title")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Message (only show if provided)
            if let message = message {
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Info text
            Text("maintenance_mode_info")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview("MaintenanceView - English") {
    MaintenanceView(message: "We're currently performing scheduled maintenance. Please check back soon!")
        .environment(\.locale, .init(identifier: "en"))
}

#Preview("MaintenanceView - Japanese") {
    MaintenanceView(message: "現在、定期メンテナンスを実施しております。しばらくしてから再度お試しください。")
        .environment(\.locale, .init(identifier: "ja"))
}
