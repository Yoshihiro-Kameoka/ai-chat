#!/bin/bash

# AI Chat デプロイスクリプト for Google Cloud Run

set -e

PROJECT_ID="ai-chat-481005"
REGION="asia-northeast1"
SERVICE_NAME="ai-chat"

echo "🚀 AI Chat を Google Cloud Run にデプロイします"
echo "   プロジェクトID: $PROJECT_ID"
echo "   リージョン: $REGION"
echo ""

# 1. プロジェクト設定の確認
echo "📋 ステップ 1: プロジェクト設定を確認中..."
gcloud config set project $PROJECT_ID

# 2. 必要なAPIの有効化
echo "🔧 ステップ 2: 必要なAPIを有効化中..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# 3. Cloud Buildでイメージをビルド
echo "🏗️  ステップ 3: Dockerイメージをビルド中..."
gcloud builds submit --config cloudbuild.yaml .

# ビルドが完了するまで少し待機
echo "⏳ ビルド完了を待機中..."
sleep 10

# 4. 環境変数の確認
echo ""
echo "⚠️  重要: 環境変数の設定が必要です"
echo ""
read -p "ANTHROPIC_API_KEYを入力してください: " ANTHROPIC_API_KEY

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ ANTHROPIC_API_KEYが設定されていません"
  exit 1
fi

# 5. Cloud Runにデプロイ（環境変数付き）
echo "☁️  ステップ 4: Cloud Runにデプロイ中..."
gcloud run deploy $SERVICE_NAME \
  --image asia-northeast1-docker.pkg.dev/$PROJECT_ID/ai-chat/ai-chat:latest \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --min-instances 0 \
  --set-env-vars "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" \
  --set-env-vars "NEXT_PUBLIC_APP_URL=https://$SERVICE_NAME-$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)' 2>/dev/null || echo 'pending')"

# 6. デプロイ完了
echo ""
echo "✅ デプロイ完了！"
echo ""
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)')
echo "🌐 アプリケーションURL: $SERVICE_URL"
echo ""
echo "📊 Cloud Runコンソール:"
echo "   https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME?project=$PROJECT_ID"
