#!/bin/bash

# GitHub Actions用のサービスアカウントとキーを作成するスクリプト

set -e

PROJECT_ID="ai-chat-481005"
SA_NAME="github-actions-deploy"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="github-actions-key.json"

echo "🔐 GitHub Actions用のサービスアカウントをセットアップします"
echo "   プロジェクトID: $PROJECT_ID"
echo ""

# 1. サービスアカウントの作成（既に存在する場合はスキップ）
echo "📋 ステップ 1: サービスアカウントを作成中..."
if gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
  echo "   ✅ サービスアカウントは既に存在します"
else
  gcloud iam service-accounts create $SA_NAME \
    --display-name="GitHub Actions Deploy" \
    --project=$PROJECT_ID
  echo "   ✅ サービスアカウントを作成しました"
fi

# 2. 必要なロールを付与
echo ""
echo "🔑 ステップ 2: 必要なロールを付与中..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin" \
  --condition=None || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.editor" \
  --condition=None || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer" \
  --condition=None || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser" \
  --condition=None || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/serviceusage.serviceUsageAdmin" \
  --condition=None || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin" \
  --condition=None || true

echo "   ✅ ロールを付与しました"

# 3. サービスアカウントキーの作成
echo ""
echo "🔐 ステップ 3: サービスアカウントキーを作成中..."
if [ -f "$KEY_FILE" ]; then
  echo "   ⚠️  $KEY_FILE は既に存在します"
  read -p "   上書きしますか？ (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   ❌ スキップしました"
    exit 0
  fi
  rm -f $KEY_FILE
fi

gcloud iam service-accounts keys create $KEY_FILE \
  --iam-account=$SA_EMAIL \
  --project=$PROJECT_ID

echo "   ✅ キーファイルを作成しました: $KEY_FILE"

# 4. キーの内容を表示
echo ""
echo "📋 ステップ 4: GitHub Secrets に設定する値"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "以下の内容を GitHub リポジトリの Secrets に設定してください："
echo ""
echo "1. GitHub リポジトリの Settings > Secrets and variables > Actions に移動"
echo ""
echo "2. 以下のシークレットを追加："
echo ""
echo "   🔑 GCP_SA_KEY:"
echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat $KEY_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   🔑 ANTHROPIC_API_KEY:"
echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   （.env.localから取得したANTHROPIC_API_KEYの値）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  重要: $KEY_FILE は機密情報です。Gitにコミットしないでください！"
echo ""
echo "✅ セットアップ完了！"


