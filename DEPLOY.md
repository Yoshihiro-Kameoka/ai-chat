# AI Chat デプロイガイド

## 前提条件

1. **Google Cloud SDKのインストール**
   ```bash
   # macOSの場合
   brew install google-cloud-sdk
   # または https://cloud.google.com/sdk/docs/install からインストール
   ```

2. **認証とプロジェクト設定**
   ```bash
   gcloud auth login
   gcloud config set project ai-chat-481005
   ```

3. **Anthropic APIキーの準備**
   - https://console.anthropic.com/ からAPIキーを取得

---

## デプロイ方法

### 方法1: GitHub Actions（推奨・CI/CD）

GitHubにpushするだけで自動デプロイされます。

#### セットアップ

**自動セットアップ（推奨）:**
```bash
bash scripts/setup-workload-identity.sh
```

このスクリプトが以下を自動実行します：
- Workload Identity Federationの設定
- サービスアカウントの作成と権限付与
- 必要なリポジトリの権限設定

**GitHub Secretsの設定:**
リポジトリの **Settings** > **Secrets and variables** > **Actions** で以下を設定：
- `ANTHROPIC_API_KEY`: Anthropic APIキー

#### デプロイ

`main`ブランチにpushすると自動的にデプロイされます。または、GitHub Actionsタブから手動実行も可能です。

---

### 方法2: 自動デプロイスクリプト

```bash
./deploy-simple.sh
# プロンプトに従ってANTHROPIC_API_KEYを入力
```

---

### 方法3: Makefileを使用

```bash
export ANTHROPIC_API_KEY=your-api-key-here
make deploy-gcp PROJECT_ID=ai-chat-481005
```

---

### 方法4: 手動デプロイ

```bash
# 必要なAPIを有効化
gcloud services enable cloudbuild.googleapis.com run.googleapis.com

# ソースから直接デプロイ
gcloud run deploy ai-chat \
  --source . \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --set-env-vars "ANTHROPIC_API_KEY=your-api-key-here"
```

---

## デプロイ後の確認

### サービスURLの取得
```bash
gcloud run services describe ai-chat \
  --region asia-northeast1 \
  --format 'value(status.url)'
```

### ログの確認
```bash
gcloud logs read --service ai-chat --region asia-northeast1 --limit 50
```

### Cloud Runコンソール
https://console.cloud.google.com/run?project=ai-chat-481005

---

## 環境変数の更新

```bash
gcloud run services update ai-chat \
  --region asia-northeast1 \
  --set-env-vars "ANTHROPIC_API_KEY=new-api-key"
```

---

## Secret Managerを使用（セキュリティ向上）

### 1. Secretを作成
```bash
echo -n "your-api-key" | gcloud secrets create anthropic-api-key --data-file=-
```

### 2. サービスアカウントに権限を付与
```bash
PROJECT_NUMBER=$(gcloud projects describe ai-chat-481005 --format="value(projectNumber)")
gcloud secrets add-iam-policy-binding anthropic-api-key \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 3. Secretを使用してデプロイ
```bash
gcloud run deploy ai-chat \
  --region asia-northeast1 \
  --set-secrets "ANTHROPIC_API_KEY=anthropic-api-key:latest"
```

---

## トラブルシューティング

### Artifact Registry権限エラー

**エラー:**
```
ERROR: denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
```

**原因:**
`gcloud run deploy --source`が使用するサービスアカウントにArtifact Registryへの書き込み権限が不足しています。

**解決方法:**

以下のスクリプトで一括設定できます：

```bash
#!/bin/bash
PROJECT_ID="ai-chat-481005"
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
REGION="asia-northeast1"

# プロジェクトレベルの権限
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# リポジトリレベルの権限（ai-chatとcloud-run-source-deployの両方）
for REPO in ai-chat cloud-run-source-deploy; do
  gcloud artifacts repositories add-iam-policy-binding ${REPO} \
    --location=${REGION} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/artifactregistry.writer" \
    --project=${PROJECT_ID}
  
  gcloud artifacts repositories add-iam-policy-binding ${REPO} \
    --location=${REGION} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/artifactregistry.writer" \
    --project=${PROJECT_ID}
  
  gcloud artifacts repositories add-iam-policy-binding ${REPO} \
    --location=${REGION} \
    --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer" \
    --project=${PROJECT_ID}
done

# サービスアカウント借用権限
gcloud iam service-accounts add-iam-policy-binding ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --project=${PROJECT_ID}

gcloud iam service-accounts add-iam-policy-binding ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --project=${PROJECT_ID}
```

**重要なポイント:**
- プロジェクトレベルとリポジトリレベルの両方に権限が必要
- `gcloud run deploy --source`はCompute Engineデフォルトサービスアカウントを使用
- 権限の反映には数分かかる場合がある

---

### Cloud Storageバケット権限エラー

**エラー:**
```
ERROR: does not have storage.buckets.get access to the Google Cloud Storage bucket
```

**解決方法:**

```bash
# プロジェクトレベルの権限
gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# バケットレベルの権限（バケットが既に存在する場合）
BUCKET_NAME="run-sources-ai-chat-481005-asia-northeast1"
gcloud storage buckets add-iam-policy-binding gs://${BUCKET_NAME} \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/storage.admin" \
  --project=ai-chat-481005
```

---

### ビルドエラーの確認

```bash
# 最新のビルドログを確認
BUILD_ID=$(gcloud builds list --limit=1 --format="value(id)" --project=ai-chat-481005)
gcloud builds log ${BUILD_ID} --project=ai-chat-481005 | tail -100
```

---

### デプロイエラーの確認

```bash
# サービスの状態を確認
gcloud run services describe ai-chat --region asia-northeast1

# ログを確認
gcloud logs read --service ai-chat --region asia-northeast1 --limit 50
```

---

## コスト見積もり

### Cloud Run料金（2025年）
- **リクエスト**: 最初の200万リクエスト/月は無料
- **CPU**: $0.00002400/vCPU秒
- **メモリ**: $0.00000250/GiB秒

### 月間コスト試算（想定：1日100リクエスト）
- リクエスト数: 3,000/月 → **$0**（無料枠内）
- CPU・メモリ: 1分/リクエスト → **約$2-5/月**

**合計: 約$2-5/月**

---

## 次のステップ

1. カスタムドメインの設定
2. Cloud CDNの有効化
3. Cloud Armorでセキュリティ強化
4. Cloud Monitoringでアラート設定
