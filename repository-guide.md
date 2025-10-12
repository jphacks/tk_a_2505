# HiNan! リポジトリ構成ガイド

## 全体像
このリポジトリは「歩いて避難訓練を習慣にする」iOS アプリ HiNan! のソースコードと、AI 連携を担う Supabase エッジ関数をまとめたプロジェクトです。SwiftUI で構築したモバイルクライアントと、ミッション生成・バッジ画像生成の自動化が主な要素です。

## ルート直下
- `README.md` — プロダクトの狙いや特徴をまとめたトップページ。
- `setup.md` — pre-commit と SwiftFormat を導入するための手順メモ。
- `media/` — プレゼン資料で使うヘッダー画像やアプリアイコン。
- `LICENSE` — MIT ライセンス文書。
- `ios/` — iOS アプリ本体（後述）。
- `supabase/` — Supabase Edge Functions のソースコード。

## iOS アプリ (`ios/escape`)
- `escape.xcodeproj` — Xcode で開くプロジェクトファイル。
- `escape/` — アプリのコアとなる SwiftUI コード。
    - `escapeApp.swift` / `AppView.swift` — アプリのエントリーポイント。
    - `Auth/`, `Home/`, `Map/`, `Mission/`, `Profile/`, `Setting/` — 画面ごとに分割されたビューとロジック。MapKit を使った地図表示やミッション結果画面が含まれます。
    - `Models/` — ミッション・避難所バッジなどのデータモデル。
    - `Utils/` — Supabase 連携やミッション生成を行うヘルパー類。
    - `Supabase.swift` — モバイルクライアントから Supabase に接続するための設定。
    - `Localizable.xcstrings`, `en.lproj`, `ja.lproj` — 英日対応のローカライズリソース。
- `escapeTests/`, `escapeUITests/` — 単体テストと UI テストのテンプレート。
- `korakuen.jpg`, `todaimae.jpg` — デモ用の避難所写真サンプル。

## Supabase Edge Functions (`supabase/edge_functions`)
- `generate_mission/index.ts` — Gemini を呼び出し日本語ミッションを生成して `missions` テーブルへ保存する関数。
- `gemini-llm/index.ts` — Gemini 2.5 Flash へのプロキシ。任意のプロンプトを安全に実行するための窓口。
- `flux-schnell/index.ts`, `test.ts` — Replicate の Flux.1 Schnell を使い避難所バッジ画像を生成する関数と補助スクリプト。

## 開発を支える設定
- `.github/workflows/pr-review.yml` — プルリクエスト時の自動チェック用 GitHub Actions ワークフロー。
- `.vscode/settings.json` — VS Code で Swift 開発をする際の推奨設定。

