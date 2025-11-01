//
//  ForceUpdateView.swift
//  escape
//
//  Created by Claude on 1/11/2025.
//

import SwiftUI

struct ForceUpdateView: View {
    let message: String?
    let appStoreURL: String = "https://apps.apple.com/app/idYOUR_APP_ID" // TODO: Replace with actual App Store URL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            Text("update_required_title")
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

            // Update button
            Button(action: {
                if let url = URL(string: appStoreURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("update_now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview("ForceUpdateView - English") {
    ForceUpdateView(message: "Please update to the latest version to continue using the app.")
        .environment(\.locale, .init(identifier: "en"))
}

#Preview("ForceUpdateView - Japanese") {
    ForceUpdateView(message: "アプリを引き続き使用するには、最新バージョンに更新してください。")
        .environment(\.locale, .init(identifier: "ja"))
}
