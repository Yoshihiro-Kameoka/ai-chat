# AIチャットボット プロジェクト仕様書

## プロジェクト概要

エンターテイメント目的のAIチャットボットWebアプリケーション。一般ユーザーがClaudeと自由に対話できるシンプルなインターフェースを提供します。

## 想定ユーザー

- **ターゲット**: 一般の人々
- **利用シーン**: 娯楽、雑談、創作的な会話など
- **認証**: 不要（誰でも利用可能）

## 技術スタック

### フロントエンド
- **フレームワーク**: Next.js（App Router）
- **言語**: TypeScript
- **スタイリング**: 未定（Tailwind CSS推奨）

### バックエンド
- **フレームワーク**: Next.js App Router
- **APIレイヤー**: Hono
- **ORM**: Prisma.js
- **データベース**: MongoDB

### AI関連
- **AIモデル**: Anthropic Claude
- **エージェントフレームワーク**: Mastra
- **API**: Anthropic API

## 主要機能

### 必須機能
1. **テキストチャット機能**
   - ユーザーとClaudeの1対1の対話
   - リアルタイムでのメッセージ送受信
   - ストリーミングレスポンス対応

2. **会話履歴管理**
   - MongoDBへの会話保存
   - セッション管理
   - 過去の会話の表示・参照

### 対象外機能
- ユーザー認証・ログイン
- 多言語対応（日本語のみ）
- 画像認識・アップロード
- 音声入力・出力
- マルチモーダル機能

## システムアーキテクチャ

### データフロー
```
ユーザー → Next.js UI → Hono API → Mastra → Claude API
                           ↓
                      Prisma → MongoDB
```

### ディレクトリ構成（推奨）
```
ai-chat/
├── src/
│   ├── app/                 # Next.js App Router
│   │   ├── page.tsx        # メインチャット画面
│   │   ├── layout.tsx      # レイアウト
│   │   └── api/            # API Routes
│   ├── components/         # Reactコンポーネント
│   │   ├── Chat/
│   │   ├── Message/
│   │   └── Input/
│   ├── lib/
│   │   ├── hono/          # Hono API設定
│   │   ├── mastra/        # Mastraエージェント設定
│   │   └── prisma/        # Prisma設定
│   └── types/             # TypeScript型定義
├── prisma/
│   └── schema.prisma      # データベーススキーマ
├── public/                # 静的ファイル
└── package.json
```

## データモデル

### Conversation（会話セッション）
```prisma
model Conversation {
  id        String   @id @default(auto()) @map("_id") @db.ObjectId
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  messages  Message[]
}
```

### Message（メッセージ）
```prisma
model Message {
  id             String       @id @default(auto()) @map("_id") @db.ObjectId
  conversationId String       @db.ObjectId
  conversation   Conversation @relation(fields: [conversationId], references: [id])
  role           String       // "user" or "assistant"
  content        String
  createdAt      DateTime     @default(now())
}
```

## API仕様

### POST /api/chat
**リクエスト**
```json
{
  "message": "ユーザーのメッセージ",
  "conversationId": "会話ID（オプション）"
}
```

**レスポンス**
```json
{
  "conversationId": "会話ID",
  "message": {
    "role": "assistant",
    "content": "Claudeの応答"
  }
}
```

### GET /api/conversations/:id
会話履歴を取得

**レスポンス**
```json
{
  "conversation": {
    "id": "会話ID",
    "messages": [
      {
        "role": "user",
        "content": "メッセージ内容",
        "createdAt": "2025-12-12T00:00:00Z"
      }
    ]
  }
}
```

## UI/UX要件

### 画面構成
1. **メインチャット画面**
   - ヘッダー（タイトル、新規会話ボタン）
   - メッセージ表示エリア（スクロール可能）
   - メッセージ入力欄
   - 送信ボタン

### デザイン要件
- レスポンシブデザイン（モバイル・デスクトップ対応）
- ダークモード対応（オプション）
- シンプルで直感的なUI

## 非機能要件

### パフォーマンス
- メッセージ送信時の応答時間: 3秒以内（ストリーミング開始まで）
- ページ初回読み込み: 2秒以内

### セキュリティ
- API Keyは環境変数で管理
- CORS設定の適切な管理
- XSS対策

### スケーラビリティ
- MongoDB Atlasの使用を推奨
- Vercelへのデプロイを想定

## 環境変数

```env
# Claude API
ANTHROPIC_API_KEY=your_api_key_here

# Database
DATABASE_URL=mongodb+srv://...

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## 開発フェーズ

### Phase 1: 基本実装
- [ ] Next.js + Honoのセットアップ
- [ ] Prisma + MongoDBの接続
- [ ] Mastra + Claude APIの統合
- [ ] 基本的なチャットUI

### Phase 2: 会話履歴機能
- [ ] 会話の永続化
- [ ] 会話履歴の表示
- [ ] セッション管理

### Phase 3: UI/UX改善
- [ ] ストリーミングレスポンス
- [ ] ローディング表示
- [ ] エラーハンドリング
- [ ] レスポンシブデザイン調整

## 参考リソース

- [Next.js App Router Documentation](https://nextjs.org/docs/app)
- [Hono Documentation](https://hono.dev/)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Mastra Documentation](https://mastra.ai/docs)
- [Anthropic Claude API](https://docs.anthropic.com/)

## 備考

- ユーザー認証が不要なため、会話データの分離は行わない
- 将来的にユーザー認証を追加する場合は、Conversationモデルにuserフィールドを追加
- エンターテイメント用途のため、レート制限やコスト管理に注意
