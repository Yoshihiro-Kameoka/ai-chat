#!/bin/bash

# AI Chat シンプルデプロイスクリプト for Google Cloud Run

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

# 3. 環境変数の確認
echo ""
echo "⚠️  重要: 環境変数の設定が必要です"
echo ""
read -p "ANTHROPIC_API_KEYを入力してください: " ANTHROPIC_API_KEY

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ ANTHROPIC_API_KEYが設定されていません"
  exit 1
fi

# 4. ソースからCloud Runにデプロイ
echo "☁️  ステップ 3: Cloud Runにソースからデプロイ中..."
gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --min-instances 0 \
  --set-env-vars "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"

# 5. デプロイ完了
echo ""
echo "✅ デプロイ完了！"
echo ""
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)')
echo "🌐 アプリケーションURL: $SERVICE_URL"
echo ""
echo "📊 Cloud Runコンソール:"
echo "   https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME?project=$PROJECT_ID"

