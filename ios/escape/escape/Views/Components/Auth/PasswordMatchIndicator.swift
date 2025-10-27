//
//  PasswordMatchIndicator.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//

import SwiftUI

struct PasswordMatchIndicator: View {
    let passwordsMatch: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(passwordsMatch ? Color.accentColor : Color.red.opacity(0.7))

            Text(passwordsMatch ? "auth.passwords_match" : "auth.passwords_dont_match")
                .font(.system(size: 10))
                .foregroundColor(passwordsMatch ? Color.accentColor : Color.red.opacity(0.7))
        }
        .padding(.horizontal, 4)
    }
}
