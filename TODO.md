# AIチャットボット開発TODO

## フェーズ1: 環境構築 ✅
### 1. プロジェクトの初期セットアップ
- [x] Next.jsプロジェクトの作成（App Router使用）
- [x] TypeScriptの設定
- [x] ディレクトリ構造の作成
- [x] .gitignoreの設定

### 2. 必要なパッケージのインストール
- [x] 基本パッケージ
　- [x] `npm install hono @hono/node-server`
　- [x] `npm install prisma @prisma/client`
　- [x] `npm install @mastra/core@beta zod`
　- [x] `npm install @anthropic-ai/sdk`
- [x] UI関連パッケージ
　- [x] `npm install -D tailwindcss postcss autoprefixer`
　- [x] `npm install lucide-react`
- [x] 開発用パッケージ
　- [x] `npm install -D @types/node`

### 3. 環境変数の設定
- [x] .env.localファイルの作成
- [x] ANTHROPIC_API_KEYの設定
- [x] MONGODB_URIの設定
- [x] NEXT_PUBLIC_APP_URLの設定

## フェーズ2: バックエンド開発 ✅
### 4. MongoDBの接続設定とPrismaスキーマの作成
- [x] Prismaスキーマファイルの作成
- [x] MongoDBプロバイダーの設定
- [x] Message/Sessionモデルの定義
- [x] Prismaクライアントの生成
- [x] Prismaクライアントのシングルトン作成

### 5. Mastraエージェントの設定
- [x] Mastraの初期化設定
- [x] Claude-3.5-sonnetモデルの設定
- [x] エージェントinstructionsの設定
- [x] エラーハンドリングの実装

### 6. チャットAPIの実装
- [x] Honoアプリケーションの作成
- [x] POST /api/chat エンドポイントの作成
- [x] POST /api/chat/stream エンドポイントの作成（ストリーミング対応）
- [x] 型定義の作成（ChatRequest, ChatResponse）
- [x] Next.js API Routesとの統合

## フェーズ3: フロントエンド開発 ✅
### 7. UIコンポーネントの作成
- [x] Buttonコンポーネントの作成
- [x] Spinnerコンポーネントの作成

### 8. チャットUIコンポーネントの作成
- [x] MessageBubbleコンポーネントの作成
- [x] MessageListコンポーネントの作成
- [x] MessageInputコンポーネントの作成
- [x] ChatContainerコンポーネントの作成

### 9. カスタムフックの実装
- [x] useChatフックの作成
- [x] メッセージ送信機能
- [x] セッションストレージでの会話履歴保持
- [x] エラーハンドリング

### 10. メインページの実装
- [x] ChatContainerの統合
- [x] useChatフックの利用
- [x] レスポンシブデザインの適用

### 11. スタイリングの調整
- [x] グローバルスタイルの調整
- [x] ビジネスライクなデザインの適用
- [x] レスポンシブ対応

## 追加タスク（必要に応じて）
- [ ] ストリーミングレスポンス機能の追加
- [ ] Markdownレンダリング対応
- [ ] コードブロックのシンタックスハイライト
- [ ] セッションクリーンアップのcron job設定
- [ ] APIレート制限の実装
- [ ] アナリティクスの設定
- [ ] バックアップ戦略の策定