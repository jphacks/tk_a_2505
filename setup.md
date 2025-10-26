# セットアップ手順

## 1. Supabaseセットアップ

### プロジェクトの作成
1. [Supabase](https://supabase.com)にアクセスし、新しいプロジェクトを作成
2. プロジェクトのURLとpublishable keyをメモ

### データベーススキーマのインポート
1. Supabaseダッシュボードで「SQL Editor」を開く
2. `supabase/schema/init.sql`の内容をコピーして実行

### Storageバケットの作成
`shelter_badges`という名前の公開バケットを作成

## 2. iOS環境設定

### Xcode設定ファイルのセットアップ
1. テンプレートから設定ファイルを作成:
   ```bash
   cp ios/escape/Config.xcconfig.example ios/escape/Config.xcconfig
   ```

2. `ios/escape/Config.xcconfig`を編集する。

**注意:** `Config.xcconfig`は機密情報を含むため、gitにコミットされません。各開発者が自分の値を設定してください。

### Supabase認証情報の設定
1. テンプレートからSwiftファイルを作成:
   ```bash
   cp ios/escape/escape/supabase.swift.example ios/escape/escape/supabase.swift
   ```

2. `ios/escape/escape/supabase.swift`を編集する。


**注意:** `supabase.swift`は機密情報を含むため、gitにコミットされません。各開発者が自分の値を設定してください。

## 3. 開発ツールのセットアップ

### Pre-commit Hooks
1. pre-commitをインストール:
   ```bash
   pip install pre-commit
   ```

2. SwiftFormatとjqをインストール:
   ```bash
   brew install swiftformat jq
   ```

3. pre-commit hooksを初期化:
   ```bash
   pre-commit install
   ```

4. 既存ファイルにhooksを適用（オプション）:
   ```bash
   pre-commit run --all-files
   ```

**Pre-commit hooksの内容:**
- SwiftFormatによるSwiftコードの自動フォーマット
- `Localizable.xcstrings`ファイルの自動ソート（マージコンフリクト防止）
