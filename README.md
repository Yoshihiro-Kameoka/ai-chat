# AI Chat

エンターテイメント目的のAIチャットボットWebアプリケーション。Claude-3-sonnetを使用した自然な対話を提供します。

## 技術スタック

- **フロントエンド**: Next.js (App Router) + React + TailwindCSS
- **バックエンド**: Next.js + Hono
- **ORM**: Prisma.js
- **AIエージェント**: Mastra
- **AIモデル**: Claude-3-sonnet (Anthropic)
- **データベース**: MongoDB

## クイックスタート

### Makefileを使う場合（推奨）

```bash
# 初期セットアップ
make setup

# .env.localにANTHROPIC_API_KEYを設定
# 例: ANTHROPIC_API_KEY=sk-ant-api03-xxxxx

# 開発サーバー起動
make dev
```

### 手動セットアップ

#### 1. 依存関係のインストール

```bash
npm install
```

#### 2. 環境変数の設定

`.env.local` ファイルを作成し、以下の環境変数を設定してください：

```bash
cp .env.example .env.local
```

以下の値を設定：

- `ANTHROPIC_API_KEY`: Anthropic APIキー（[console.anthropic.com](https://console.anthropic.com/)で取得）
- `MONGODB_URI`: MongoDB接続文字列（オプション）
- `NEXT_PUBLIC_APP_URL`: アプリケーションのURL（開発環境では`http://localhost:3000`）

#### 3. Prisma Clientの生成

```bash
npx prisma generate
```

#### 4. 開発サーバーの起動

```bash
npm run dev
```

ブラウザで [http://localhost:3000](http://localhost:3000) を開いてアプリケーションを確認できます。

## Makefileコマンド一覧

```bash
make help              # ヘルプを表示
make install           # 依存パッケージをインストール
make setup             # 初期セットアップ（install + prisma-generate）
make dev               # 開発サーバーを起動
make build             # 本番用ビルド
make start             # 本番サーバーを起動
make lint              # ESLintを実行
make clean             # ビルド成果物を削除

# Prisma関連
make prisma-generate   # Prisma Clientを生成
make prisma-push       # Prisma SchemaをDBに反映
make prisma-studio     # Prisma Studioを起動

# Docker/デプロイ関連
make docker-build      # Dockerイメージをビルド
make deploy-gcp        # Google Cloud Runにデプロイ
make env-check         # 環境変数をチェック
```

## プロジェクト構造

```
ai-chat/
├── app/                    # Next.js App Router
│   ├── api/               # API Routes
│   ├── globals.css        # グローバルスタイル
│   ├── layout.tsx         # ルートレイアウト
│   └── page.tsx           # メインページ
├── components/            # Reactコンポーネント
├── lib/                   # ライブラリ・ユーティリティ
│   ├── hono/             # Hono API設定
│   ├── mastra/           # Mastra設定
│   └── prisma/           # Prisma設定
├── prisma/               # Prismaスキーマ
├── types/                # TypeScript型定義
└── public/               # 静的ファイル
```

## スクリプト

- `npm run dev`: 開発サーバー起動
- `npm run build`: プロダクションビルド
- `npm start`: プロダクションサーバー起動
- `npm run lint`: ESLint実行

## デプロイ

### Google Cloud Runへのデプロイ

```bash
# Google Cloud SDKの認証
gcloud auth login

# プロジェクトを設定
gcloud config set project YOUR_PROJECT_ID

# デプロイ（Makefileを使用）
make deploy-gcp PROJECT_ID=YOUR_PROJECT_ID

# または手動デプロイ
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/ai-chat
gcloud run deploy ai-chat \
  --image gcr.io/YOUR_PROJECT_ID/ai-chat \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated
```

### 環境変数の設定（Cloud Run）

デプロイ後、Cloud Runのコンソールで以下の環境変数を設定：

- `ANTHROPIC_API_KEY`: Anthropic APIキー（Secret Managerの使用を推奨）
- `NEXT_PUBLIC_APP_URL`: デプロイされたアプリのURL

### Dockerでのローカル実行

```bash
# イメージをビルド
make docker-build

# コンテナを実行
docker run -p 3000:3000 \
  -e ANTHROPIC_API_KEY=your-api-key \
  ai-chat:latest
```

## ライセンス

MIT
