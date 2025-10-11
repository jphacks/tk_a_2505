//
//  Simple3DBadgeView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI
import UIKit

// MARK: - シンプル3Dバッジビュー（ホーム画面用）

struct Simple3DBadgeView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 背景の影
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.1),
                                Color.clear,
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                    .offset(x: 2, y: 2)
                    .blur(radius: 1)

                // メインの画像表示
                SimpleCoinFaceView(badge: badge, isFront: true)
                    .frame(width: 60, height: 60)

                // ハイライト効果
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.clear,
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .offset(x: -8, y: -8)
                    .opacity(0.7)
            }

            Text(badge.name)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - シンプルコインの表面ビュー

struct SimpleCoinFaceView: View {
    let badge: Badge
    let isFront: Bool

    var body: some View {
        ZStack {
            // アイコン（前面のみ）
            if isFront {
                if let imageName = badge.imageName, !imageName.isEmpty {
                    SimpleImageLoader(imageName: imageName)
                } else {
                    // 画像がない場合のみ背景円形を表示
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    badge.color.opacity(0.9),
                                    badge.color.opacity(0.7),
                                    badge.color.opacity(0.5),
                                    badge.color.opacity(0.3),
                                ]),
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.black.opacity(0.2),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )

                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
        }
    }
}

// MARK: - 画像ローダーコンポーネント

struct SimpleImageLoader: View {
    let imageName: String

    var body: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            } else if let bundlePath = Bundle.main.path(forResource: imageName, ofType: "png"),
                      let uiImage = UIImage(contentsOfFile: bundlePath)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            } else {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
        }
    }
}

#Preview {
    Simple3DBadgeView(badge: Badge(
        id: "1",
        name: "後楽園",
        icon: "star.fill",
        color: Color("brandOrange"),
        isUnlocked: true,
        imageName: "korakuen"
    ))
}
