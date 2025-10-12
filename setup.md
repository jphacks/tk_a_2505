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

### Supabase認証情報の設定
1. テンプレートから設定ファイルを作成:
   ```bash
   cp ios/escape/escape/Supabase.swift.template ios/escape/escape/Supabase.swift
   ```

2. `ios/escape/escape/Supabase.swift`を編集し、Supabase認証情報を入力:
   ```swift
   let supabase = SupabaseClient(
       supabaseURL: URL(string: "https://your-project.supabase.co")!,
       supabaseKey: "your_supabase_publishable_key_here"
   )
   ```

**注意:** `Supabase.swift`は機密情報を含むため、gitにコミットされません。

## 3. 開発ツールのセットアップ

### Pre-commit Hooks
1. pre-commitをインストール:
   ```bash
   pip install pre-commit
   ```

2. SwiftFormatをインストール:
   ```bash
   brew install swiftformat
   ```

3. pre-commit hooksを初期化:
   ```bash
   pre-commit install
   ```
