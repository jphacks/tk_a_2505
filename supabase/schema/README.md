# Database Schema Organization

元の `init.sql` ファイルがテーブルごとに分割されました。これにより、各テーブルとその関連機能の理解と保守が容易になります。

## ファイル構造

```
supabase/schema/
├── README.md                    # このファイル
├── init.sql                     # 新しいモジュラー式初期化ファイル
├── init_legacy.sql            # 元のモノリシックファイル (バックアップ)
├── 00_setup.sql                # データベース基本設定
├── 01_extensions.sql           # PostgreSQL拡張機能
├── 02_types.sql                # カスタム型定義
├── 99_grants.sql               # 最終権限設定
├── tables/                     # テーブル定義
│   ├── users.sql
│   ├── groups.sql
│   ├── group_members.sql
│   ├── missions.sql
│   ├── mission_results.sql
│   ├── shelters.sql
│   ├── shelter_badges.sql
│   ├── user_shelter_badges.sql
│   └── points.sql
├── functions/                  # ストアドファンクション
│   ├── auth_functions.sql
│   └── group_functions.sql
└── policies/                   # Row Level Security ポリシー
    ├── user_policies.sql
    ├── group_policies.sql
    └── general_policies.sql
```

## 使用方法

### 新しいモジュラー式の初期化

```bash
psql -f supabase/schema/init_modular.sql
```

### 個別テーブルの操作

特定のテーブルのみを操作したい場合：

```bash
# ユーザーテーブルのみを再作成
psql -f supabase/schema/tables/users.sql

# グループ関連の機能のみを更新
psql -f supabase/schema/functions/group_functions.sql
psql -f supabase/schema/tables/groups.sql
psql -f supabase/schema/tables/group_members.sql
psql -f supabase/schema/policies/group_policies.sql
```

## 利点

1. **可読性向上**: 各テーブルとその関連機能が明確に分離
2. **保守性向上**: 特定のテーブルの変更時に該当ファイルのみを編集
3. **開発効率**: 人間とAIの両方が関連するSQLスクリプトを素早く特定可能
4. **バージョン管理**: 各コンポーネントの変更履歴を個別に追跡
5. **テスト容易性**: 個別のコンポーネントを独立してテスト可能

## マイグレーション

新しい構造に移行する際は：

1. 現在の `init.sql` は `init_legacy.sql` として保持
2. 新しい環境では `init_modular.sql` を使用
3. 既存の環境は段階的に移行を検討
