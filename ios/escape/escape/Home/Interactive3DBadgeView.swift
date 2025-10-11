//
//  Interactive3DBadgeView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI
import UIKit

// MARK: - インタラクティブ3Dバッジビュー

struct Interactive3DBadgeView: View {
    let badge: Badge

    // 3D回転の状態
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0

    // スケールとオフセット
    @State private var scale: Double = 1.0
    @State private var offset: CGSize = .zero

    // ジェスチャーの状態
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero
    @State private var isDragging: Bool = false

    // アニメーション状態
    @State private var isAnimating: Bool = false
    @State private var autoRotation: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 背景の影（3D効果を強調）
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.1),
                                Color.clear,
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 120, height: 120)
                    .offset(x: 3 + offset.width * 0.1, y: 3 + offset.height * 0.1)
                    .blur(radius: 2)
                    .scaleEffect(scale)

                // メインの画像表示
                CoinFaceView(badge: badge, isFront: true)
                    .frame(width: 100, height: 100)
                    .rotation3DEffect(
                        .degrees(rotationX),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(rotationY),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(rotationZ),
                        axis: (x: 0, y: 0, z: 1)
                    )
                    .scaleEffect(scale)
                    .offset(offset)
                    .offset(dragOffset)
                    .animation(
                        isDragging ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) :
                            .spring(response: 0.6, dampingFraction: 0.8),
                        value: rotationX
                    )
                    .animation(
                        isDragging ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) :
                            .spring(response: 0.6, dampingFraction: 0.8),
                        value: rotationY
                    )
                    .animation(
                        isDragging ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) :
                            .spring(response: 0.6, dampingFraction: 0.8),
                        value: rotationZ
                    )
                    .animation(
                        isDragging ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) :
                            .spring(response: 0.6, dampingFraction: 0.8),
                        value: scale
                    )
                    .animation(
                        isDragging ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) :
                            .spring(response: 0.6, dampingFraction: 0.8),
                        value: offset.width
                    )
                    .animation(
                        isDragging ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) :
                            .spring(response: 0.6, dampingFraction: 0.8),
                        value: dragOffset.width
                    )

                // ハイライト効果（3D感を強調）
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.3),
                                Color.clear,
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .offset(x: -10, y: -10)
                    .rotation3DEffect(
                        .degrees(rotationX),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(rotationY),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .opacity(0.7)
            }
            .onTapGesture {
                triggerTapAnimation()
            }
            .gesture(
                SimultaneousGesture(
                    // ドラッグジェスチャー（3D回転）
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            autoRotation = false

                            let deltaX = value.translation.width - lastDragValue.width
                            let deltaY = value.translation.height - lastDragValue.height

                            // ドラッグ量に応じて3D回転
                            rotationY += deltaX * 0.5
                            rotationX -= deltaY * 0.5

                            // ドラッグ中の軽微な移動
                            dragOffset = CGSize(
                                width: value.translation.width * 0.1,
                                height: value.translation.height * 0.1
                            )

                            lastDragValue = value.translation
                        }
                        .onEnded { _ in
                            isDragging = false

                            // ドラッグ終了時の慣性効果
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                dragOffset = .zero
                                // 自動回転を再開
                                autoRotation = true
                            }
                        },

                    // ピンチジェスチャー（ズーム）
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(0.5, min(2.0, value))
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                scale = 1.0
                            }
                        }
                )
            )
            .onAppear {
                startAutoRotation()
            }

            Text(badge.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    private func triggerTapAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            rotationY += 360
        }

        // 軽いバウンス効果
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }

    private func startAutoRotation() {
        guard autoRotation else { return }

        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationY = 360
        }

        // 軽い上下の動き
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            offset = CGSize(width: 0, height: -2)
        }
    }
}

// MARK: - コインの表面ビュー

struct CoinFaceView: View {
    let badge: Badge
    let isFront: Bool

    var body: some View {
        ZStack {
            // アイコン（前面のみ）
            if isFront {
                if let imageName = badge.imageName, !imageName.isEmpty {
                    InteractiveImageLoader(imageName: imageName)
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

// MARK: - インタラクティブ画像ローダーコンポーネント

struct InteractiveImageLoader: View {
    let imageName: String

    var body: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
            } else if let bundlePath = Bundle.main.path(forResource: imageName, ofType: "png"),
                      let uiImage = UIImage(contentsOfFile: bundlePath)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
            } else {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
            }
        }
    }
}

#Preview {
    Interactive3DBadgeView(badge: Badge(
        id: "1",
        name: "後楽園",
        icon: "star.fill",
        color: Color("brandOrange"),
        isUnlocked: true,
        imageName: "korakuen"
    ))
}
