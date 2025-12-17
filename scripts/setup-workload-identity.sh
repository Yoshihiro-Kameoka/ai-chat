#!/bin/bash

# GitHub Actions用のWorkload Identity Federationをセットアップするスクリプト

set -e

PROJECT_ID="ai-chat-481005"
SA_NAME="github-actions-deploy"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-actions-provider"
REPO="Yoshihiro-Kameoka/ai-chat"

echo "🔐 GitHub Actions用のWorkload Identity Federationをセットアップします"
echo "   プロジェクトID: $PROJECT_ID"
echo "   リポジトリ: $REPO"
echo ""

# 1. Workload Identity Poolの作成
echo "📋 ステップ 1: Workload Identity Poolを作成中..."
if gcloud iam workload-identity-pools describe $POOL_NAME \
  --location="global" \
  --project=$PROJECT_ID &>/dev/null; then
  echo "   ✅ Workload Identity Poolは既に存在します"
else
  gcloud iam workload-identity-pools create $POOL_NAME \
    --location="global" \
    --display-name="GitHub Actions Pool" \
    --project=$PROJECT_ID
  echo "   ✅ Workload Identity Poolを作成しました"
fi

# 2. Workload Identity Providerの作成
echo ""
echo "📋 ステップ 2: Workload Identity Providerを作成中..."
if gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
  --workload-identity-pool=$POOL_NAME \
  --location="global" \
  --project=$PROJECT_ID &>/dev/null; then
  echo "   ✅ Workload Identity Providerは既に存在します"
else
  gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
    --workload-identity-pool=$POOL_NAME \
    --location="global" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == \"$REPO\"" \
    --project=$PROJECT_ID
  echo "   ✅ Workload Identity Providerを作成しました"
fi

# 3. サービスアカウントへの権限付与
echo ""
echo "🔑 ステップ 3: サービスアカウントへの権限を付与中..."
POOL_ID=$(gcloud iam workload-identity-pools describe $POOL_NAME \
  --location="global" \
  --project=$PROJECT_ID \
  --format="value(name)" | sed 's/.*\///')

gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/$REPO" || true

echo "   ✅ 権限を付与しました"

# 4. 設定情報の表示
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Workload Identity Federationのセットアップが完了しました！"
echo ""
echo "📋 次のステップ:"
echo ""
echo "1. GitHubリポジトリの Settings > Secrets and variables > Actions で以下を設定："
echo ""
echo "   🔑 ANTHROPIC_API_KEY: Anthropic APIキー"
echo ""
echo "2. ワークフローファイルは既にWorkload Identity Federationを使用するように"
echo "   設定されています。次回のpushで自動的にデプロイされます。"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

