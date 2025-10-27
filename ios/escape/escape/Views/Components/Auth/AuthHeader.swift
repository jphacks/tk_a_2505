//
//  AuthHeader.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//

import SwiftUI

struct AuthHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("auth.welcome")
                .font(.title2.bold())
        }
        .padding(.top, 64)
        .padding(.bottom, 48)
    }
}
