# AIチャットボット 実装TODO

## Phase 1: プロジェクトセットアップ

### 1.1 プロジェクト初期化
- [ ] Next.js プロジェクトの作成（App Router使用）
  ```bash
  npx create-next-app@latest ai-chat --typescript --tailwind --app
  ```
- [ ] GitHubリポジトリの作成とプッシュ
- [ ] `.gitignore` の確認・更新（.env, node_modules等）
- [ ] `README.md` の作成（プロジェクト説明、セットアップ手順）

### 1.2 依存パッケージのインストール
- [ ] Hono のインストール
  ```bash
  npm install hono
  ```
- [ ] Prisma のインストールと初期化
  ```bash
  npm install prisma @prisma/client
  npx prisma init
  ```
- [ ] Mastra のインストール
  ```bash
  npm install @mastra/core
  ```
- [ ] Anthropic SDK のインストール
  ```bash
  npm install @anthropic-ai/sdk
  ```
- [ ] その他の必要なパッケージ
  ```bash
  npm install zod clsx
  npm install -D @types/node
  ```

### 1.3 環境変数の設定
- [ ] `.env.local` ファイルの作成
- [ ] 必要な環境変数を定義
  - `ANTHROPIC_API_KEY`
  - `DATABASE_URL`（MongoDB接続文字列）
  - `NEXT_PUBLIC_APP_URL`
- [ ] `.env.example` ファイルの作成（テンプレート用）

---

## Phase 2: データベース設定

### 2.1 MongoDB セットアップ
- [ ] MongoDB Atlas アカウントの作成（未作成の場合）
- [ ] 新規クラスターの作成（Free tier可）
- [ ] データベースユーザーの作成
- [ ] IP アドレスのホワイトリスト設定
- [ ] 接続文字列の取得と `.env.local` への追加

### 2.2 Prisma スキーマ定義
- [ ] `prisma/schema.prisma` の編集
  - MongoDB用のprovider設定
  - Conversationモデルの定義
  - Messageモデルの定義
- [ ] Prisma Client の生成
  ```bash
  npx prisma generate
  ```
- [ ] データベースのプッシュ
  ```bash
  npx prisma db push
  ```

### 2.3 Prisma クライアントのセットアップ
- [ ] `src/lib/prisma.ts` の作成（シングルトンインスタンス）
- [ ] Prisma Client の初期化とエクスポート

---

## Phase 3: バックエンド実装

### 3.1 Mastra エージェントの設定
- [ ] `src/lib/mastra/config.ts` の作成
- [ ] Claude APIとの接続設定
- [ ] エージェントの初期化処理の実装
- [ ] プロンプトテンプレートの作成

### 3.2 Hono API の実装
- [ ] `src/lib/hono/app.ts` の作成（Honoアプリケーション）
- [ ] CORS設定の追加
- [ ] エラーハンドリングミドルウェアの実装

### 3.3 API エンドポイントの実装
- [ ] `POST /api/chat` エンドポイントの実装
  - リクエストバリデーション（Zod使用）
  - Mastraエージェントの呼び出し
  - 会話履歴の保存
  - ストリーミングレスポンス対応
  - エラーハンドリング

- [ ] `GET /api/conversations/:id` エンドポイントの実装
  - 会話履歴の取得
  - エラーハンドリング

- [ ] Next.js API Routesとの統合
  - `src/app/api/[[...route]]/route.ts` の作成

### 3.4 型定義の作成
- [ ] `src/types/chat.ts` の作成
  - Message型
  - Conversation型
  - APIリクエスト/レスポンス型

---

## Phase 4: フロントエンド実装

### 4.1 レイアウト・基盤の構築
- [ ] `src/app/layout.tsx` の編集
  - メタデータの設定
  - TailwindCSSのインポート
  - フォント設定

- [ ] TailwindCSS設定のカスタマイズ
  - ビジネスライクな色設定
  - レスポンシブブレークポイント

### 4.2 UI コンポーネントの作成

#### 基本コンポーネント
- [ ] `src/components/ui/Button.tsx`
  - プライマリ・セカンダリボタン
  - ローディング状態

- [ ] `src/components/ui/Input.tsx`
  - テキスト入力フィールド
  - バリデーション表示

- [ ] `src/components/ui/Spinner.tsx`
  - ローディングインジケーター

#### チャット専用コンポーネント
- [ ] `src/components/chat/MessageBubble.tsx`
  - ユーザーメッセージ表示
  - AIメッセージ表示
  - タイムスタンプ表示
  - Markdown対応（オプション）

- [ ] `src/components/chat/MessageList.tsx`
  - メッセージ一覧の表示
  - 自動スクロール機能
  - 空状態の表示

- [ ] `src/components/chat/MessageInput.tsx`
  - メッセージ入力フォーム
  - 送信ボタン
  - Enter キー送信対応
  - Shift+Enter で改行

- [ ] `src/components/chat/ChatContainer.tsx`
  - 全体のチャットレイアウト
  - ヘッダー（タイトル、新規会話ボタン）
  - メッセージリスト
  - 入力エリア

### 4.3 状態管理の実装
- [ ] `src/hooks/useChat.ts` カスタムフックの作成
  - メッセージ送信処理
  - 会話履歴の管理
  - ローディング状態
  - エラー状態
  - セッションストレージでの永続化

### 4.4 メインページの実装
- [ ] `src/app/page.tsx` の実装
  - ChatContainerの配置
  - useChatフックの利用
  - エラー表示

---

## Phase 5: UI/UX の改善

### 5.1 スタイリングの調整
- [ ] レスポンシブデザインの実装
  - モバイル（〜640px）
  - タブレット（641px〜1024px）
  - デスクトップ（1025px〜）

- [ ] ビジネスライクなデザイン適用
  - 配色の調整
  - タイポグラフィ
  - 余白・間隔の調整

### 5.2 UX機能の追加
- [ ] ストリーミングレスポンス表示
  - 段階的なテキスト表示
  - タイピングインジケーター

- [ ] エラーハンドリングUI
  - エラーメッセージの表示
  - リトライボタン

- [ ] ローディング状態の表示
  - メッセージ送信中のインジケーター
  - スケルトンローディング

- [ ] 新規会話機能
  - 会話のリセット処理
  - セッションストレージのクリア

---

## Phase 6: テスト・デバッグ

### 6.1 ローカル動作確認
- [ ] 開発サーバーの起動確認
- [ ] API エンドポイントの動作確認
  - `/api/chat` のテスト
  - エラーケースのテスト

- [ ] UI の動作確認
  - メッセージ送受信
  - 会話履歴の保持
  - レスポンシブ動作

### 6.2 エラーハンドリングのテスト
- [ ] API キー未設定時の挙動
- [ ] ネットワークエラー時の挙動
- [ ] データベース接続エラー時の挙動
- [ ] 不正な入力時の挙動

### 6.3 パフォーマンステスト
- [ ] ページ読み込み速度の確認
- [ ] API レスポンス速度の確認
- [ ] 長い会話時の動作確認

---

## Phase 7: デプロイ準備

### 7.1 Dockerfile の作成
- [ ] `Dockerfile` の作成
  - Node.js ベースイメージの選択
  - 依存関係のインストール
  - ビルド処理
  - 起動コマンド

- [ ] `.dockerignore` の作成
  - node_modules
  - .next
  - .env*

### 7.2 Google Cloud 設定
- [ ] Google Cloud Project の作成
- [ ] Cloud Run API の有効化
- [ ] サービスアカウントの作成
- [ ] 権限の設定

### 7.3 デプロイスクリプトの作成
- [ ] `deploy.sh` スクリプトの作成
  - Docker イメージのビルド
  - Google Container Registry へのプッシュ
  - Cloud Run へのデプロイ

- [ ] 環境変数の Cloud Run への設定
  - ANTHROPIC_API_KEY
  - DATABASE_URL

### 7.4 デプロイの実行
- [ ] 初回デプロイの実行
- [ ] デプロイ後の動作確認
- [ ] カスタムドメインの設定（オプション）

---

## Phase 8: ドキュメント整備

### 8.1 README の完成
- [ ] プロジェクト概要の追記
- [ ] セットアップ手順の記載
- [ ] 環境変数の説明
- [ ] デプロイ手順の記載

### 8.2 コメントの追加
- [ ] 複雑なロジックへのコメント追加
- [ ] 型定義への説明コメント
- [ ] API エンドポイントのドキュメント化

---

## Phase 9: 最終チェック

### 9.1 本番環境での確認
- [ ] 全機能の動作確認
- [ ] エラーハンドリングの確認
- [ ] レスポンシブデザインの確認
- [ ] パフォーマンスの確認

### 9.2 セキュリティチェック
- [ ] 環境変数の漏洩チェック
- [ ] CORS 設定の確認
- [ ] XSS 対策の確認
- [ ] API レート制限の検討

### 9.3 リリース準備
- [ ] バージョンタグの作成
- [ ] CHANGELOG の作成
- [ ] リリースノートの作成

---

## オプション機能（時間がある場合）

- [ ] ダークモード対応
- [ ] キーボードショートカット
- [ ] メッセージのMarkdown表示
- [ ] コードブロックのシンタックスハイライト
- [ ] 会話のエクスポート機能（JSON/テキスト）
- [ ] システムプロンプトのカスタマイズ機能
- [ ] モニタリング・ログ機能の追加

---

## 注意事項

- MongoDB Atlas の無料枠の制限に注意
- Anthropic API の使用量・コストに注意
- Google Cloud Run の無料枠を確認
- セッションストレージの容量制限（通常5MB）に注意
- 想定同時接続数（5-10人）を超える場合のスケーリング検討

---

## 完了基準

✅ ローカル環境で正常動作すること
✅ Cloud Run にデプロイされ、アクセス可能なこと
✅ Claude との対話が正常に機能すること
✅ レスポンシブデザインが適切に動作すること
✅ エラーハンドリングが適切に実装されていること
✅ ドキュメントが整備されていること
