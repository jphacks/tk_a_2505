//
//  MissionViews.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - ミッションカードビュー

struct MissionCardView: View {
    let mission: Mission?
    let onTap: () -> Void
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日のミッション")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()
            }

            if let mission = mission {
                Button(action: onTap) {
                    ZStack {
                        // グラデーション背景
                        LinearGradient(
                            gradient: Gradient(colors: mission.disasterType.gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(20)

                        // コンテンツ
                        VStack(alignment: .leading, spacing: 16) {
                            // ヘッダー部分
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: mission.disasterType.emergencyIcon)
                                            .font(.title)
                                            .foregroundColor(.white)

                                        Text(mission.disasterType.localizedName)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.9))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.25))
                                            .cornerRadius(8)
                                    }

                                    Text(mission.title)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                VStack(spacing: 4) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            // 説明文
                            Text(mission.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(20)
                    }
                    .shadow(color: mission.disasterType.color.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // ミッション完了状態
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color("brandMediumBlue"), Color("brandDarkBlue")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20)

                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text("すべてのミッションが完了しました！")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("新しいミッションは24時間後に更新されます")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                }
                .shadow(color: Color("brandMediumBlue").opacity(0.3), radius: 15, x: 0, y: 8)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - ミッション詳細ビュー

struct MissionDetailView: View {
    let mission: Mission?
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let mission = mission {
                    // 背景グラデーション
                    LinearGradient(
                        gradient: Gradient(colors: mission.disasterType.gradientColors + [.black.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 24) {
                            // ヘッダーセクション
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: mission.disasterType.emergencyIcon)
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 8) {}
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mission.disasterType.localizedName)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.25))
                                        .cornerRadius(12)

                                    Text(mission.title)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // 詳細情報セクション
                            VStack(spacing: 20) {
                                // 説明文
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ミッション概要")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text(mission.description)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(4)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)

                                // ミッション情報
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ミッション情報")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.white.opacity(0.8))

                                        Text("開催日時: \(mission.aiGeneratedAt, formatter: dateFormatter)")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)

                            // アクションボタン
                            VStack(spacing: 16) {
                                Button(action: {
                                    // TODO: ミッション開始処理
                                }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)

                                        Text("ミッション開始")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(mission.disasterType.color)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

#Preview {
    MissionCardView(
        mission: Mission(
            id: "1",
            title: "震度6強の地震発生！避難所へ緊急避難せよ",
            name: "緊急地震避難訓練",
            description: "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            estimatedDuration: 15,
            distance: 800,
            severity: .critical,
            isUrgent: true,
            aiGeneratedAt: Date()
        ),
        onTap: {}
    )
}
