//
//  AuthFooter.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//

import SwiftUI

struct AuthFooter: View {
    let openURL: (URL) -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("auth.by_continuing")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))

            HStack(spacing: 3) {
                Button(action: {
                    if let url = URL(string: "https://jphacks.github.io/tk_a_2505/tos") {
                        openURL(url)
                    }
                }) {
                    Text("auth.terms_of_service")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor.opacity(0.9))
                }

                Text("auth.and")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))

                Button(action: {
                    if let url = URL(string: "https://jphacks.github.io/tk_a_2505/privacy") {
                        openURL(url)
                    }
                }) {
                    Text("auth.privacy_policy")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor.opacity(0.9))
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }
}
