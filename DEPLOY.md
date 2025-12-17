# AI Chat デプロイガイド

## Google Cloud Runへのデプロイ手順

### 前提条件

1. **Google Cloud SDKのインストール**
   ```bash
   # macOSの場合brew install google-cloud-sdk
   

   # またはhttps://cloud.google.com/sdk/docs/install からインストール
   ```

2. **認証とプロジェクト設定**
   ```bash
   # Google Cloudにログイン
   gcloud auth login

   # プロジェクトを設定
   gcloud config set project ai-chat-481005
   ```

3. **Anthropic APIキーの準備**
   - https://console.anthropic.com/ からAPIキーを取得

---

## 方法1: GitHub Actions（推奨・CI/CD）

GitHubにpushするだけで自動デプロイされます。

### セットアップ手順

#### 1. Google Cloud サービスアカウントキーの作成

**方法A: 自動セットアップスクリプト（推奨）**

```bash
# セットアップスクリプトを実行
bash scripts/setup-github-actions.sh
```

このスクリプトが以下を自動で実行します：
- サービスアカウントの作成
- 必要なロールの付与
- キーファイルの作成
- GitHub Secrets設定用の指示を表示

**方法B: 手動セットアップ**

```bash
# サービスアカウントを作成（既に存在する場合はスキップ）
gcloud iam service-accounts create github-actions-deploy \
  --display-name="GitHub Actions Deploy" \
  --project=ai-chat-481005

# 必要なロールを付与
gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# サービスアカウントキーを作成
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com

# キーの内容をコピー（次のステップで使用）
cat github-actions-key.json
```

#### 2. GitHub Secrets の設定

GitHubリポジトリの **Settings** > **Secrets and variables** > **Actions** で以下を設定：

- **`GCP_SA_KEY`**: 上記で作成したJSONキーファイルの内容（全体をコピー）
- **`ANTHROPIC_API_KEY`**: Anthropic APIキー

#### 3. デプロイ

`main`ブランチにpushすると自動的にデプロイされます：

```bash
git add .
git commit -m "Deploy to Cloud Run"
git push origin main
```

または、GitHub Actionsタブから手動実行も可能です。

---
## 方法2: 自動デプロイスクリプト

最も簡単な方法です。

```bash
# デプロイスクリプトを実行
./deploy-simple.sh

# プロンプトに従ってANTHROPIC_API_KEYを入力
```

スクリプトが以下を自動で実行します：
- 必要なAPIの有効化
- ソースから直接ビルド＆デプロイ
- 環境変数の設定

---

## 方法3: Makefileを使用

```bash
# 事前にAPIキーを環境変数に設定
export ANTHROPIC_API_KEY=your-api-key-here

# デプロイ実行
make deploy-gcp PROJECT_ID=ai-chat-481005
```

---

## 方法4: 手動デプロイ

### ステップ1: 必要なAPIを有効化

```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### ステップ2: Dockerイメージをビルド

```bash
# Cloud Buildを使用してビルド
gcloud builds submit --tag gcr.io/ai-chat-481005/ai-chat

# またはcloudbuild.yamlを使用
gcloud builds submit --config cloudbuild.yaml
```

### ステップ3: Cloud Runにデプロイ

```bash
gcloud run deploy ai-chat \
  --image gcr.io/ai-chat-481005/ai-chat:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --set-env-vars ANTHROPIC_API_KEY=your-api-key-here
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
gcloud logs read --service ai-chat --region asia-northeast1
```

### Cloud Runコンソールで確認

https://console.cloud.google.com/run?project=ai-chat-481005

---

## 環境変数の更新

デプロイ後に環境変数を変更する場合：

```bash
gcloud run services update ai-chat \
  --region asia-northeast1 \
  --set-env-vars ANTHROPIC_API_KEY=new-api-key
```

---

## Secret Managerを使用（セキュリティ向上）

### 1. Secretを作成

```bash
echo -n "your-api-key" | gcloud secrets create anthropic-api-key --data-file=-
```

### 2. Cloud RunサービスアカウントにSecret Accessorロールを付与

```bash
PROJECT_NUMBER=$(gcloud projects describe ai-chat-481005 --format="value(projectNumber)")

gcloud secrets add-iam-policy-binding anthropic-api-key \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 3. Secretを使用してデプロイ

```bash
gcloud run deploy ai-chat \
  --image gcr.io/ai-chat-481005/ai-chat:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --set-secrets ANTHROPIC_API_KEY=anthropic-api-key:latest
```

---

## トラブルシューティング

### Cloud Storageバケット権限エラー

`gcloud run deploy --source` を使用する際、以下のエラーが発生することがあります：

```
ERROR: does not have storage.buckets.get access to the Google Cloud Storage bucket
```

#### 原因

`gcloud run deploy --source` は、ソースコードをアップロードするために `run-sources-{PROJECT_ID}-{REGION}` というCloud Storageバケットを使用します。このバケットへのアクセス権限が不足している場合に発生します。

#### 解決手順

##### ステップ1: プロジェクトレベルの権限を確認・付与

```bash
# Storage Admin権限を付与（プロジェクトレベル）
gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

##### ステップ2: バケットレベルの権限を付与（重要）

バケットが既に存在する場合、バケットレベルでも明示的に権限を付与する必要があります：

```bash
# バケット名を確認（通常は run-sources-{PROJECT_ID}-{REGION}）
BUCKET_NAME="run-sources-ai-chat-481005-asia-northeast1"

# バケットレベルのStorage Admin権限を付与
gcloud storage buckets add-iam-policy-binding gs://${BUCKET_NAME} \
  --member="serviceAccount:github-actions-deploy@ai-chat-481005.iam.gserviceaccount.com" \
  --role="roles/storage.admin" \
  --project=ai-chat-481005
```

**注意**: バケットは `gcloud run deploy --source` が初回実行時に自動的に作成します。バケットが存在しない場合は、まずプロジェクトレベルの権限を付与してからデプロイを実行してください。

---

### Artifact Registry権限エラー（重要）

`gcloud run deploy --source` を使用する際、以下のエラーが発生することがあります：

```
ERROR: denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
```

#### 原因

`gcloud run deploy --source` は自動的に `cloud-run-source-deploy` リポジトリを作成しますが、以下のサービスアカウントに権限が不足している可能性があります：

1. **Compute Engineデフォルトサービスアカウント** (`{PROJECT_NUMBER}-compute@developer.gserviceaccount.com`)
   - `gcloud run deploy --source` が実際に使用するサービスアカウント
2. **Cloud Buildサービスアカウント** (`{PROJECT_NUMBER}@cloudbuild.gserviceaccount.com`)
3. **Cloud Buildサービスエージェント** (`service-{PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com`)

#### 解決手順

##### ステップ1: プロジェクト番号を確認

```bash
PROJECT_NUMBER=$(gcloud projects describe ai-chat-481005 --format="value(projectNumber)")
echo $PROJECT_NUMBER
```

##### ステップ2: プロジェクトレベルの権限を付与

```bash
# Cloud BuildサービスアカウントにEditor権限（広範囲の権限）
gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/editor"

# Cloud BuildサービスアカウントにArtifact Registry Writer権限
gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Cloud BuildサービスエージェントにArtifact Registry Writer権限
gcloud projects add-iam-policy-binding ai-chat-481005 \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

##### ステップ3: リポジトリレベルの権限を付与（重要）

`cloud-run-source-deploy` リポジトリに、**3つのサービスアカウントすべて**に権限を付与する必要があります：

```bash
# Compute Engineデフォルトサービスアカウント（最も重要！）
gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
  --location=asia-northeast1 \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --project=ai-chat-481005

# Cloud Buildサービスアカウント
gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
  --location=asia-northeast1 \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --project=ai-chat-481005

# Cloud Buildサービスエージェント
gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
  --location=asia-northeast1 \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --project=ai-chat-481005
```

##### ステップ4: サービスアカウント借用権限を付与

Cloud BuildサービスアカウントがCloud Runサービスアカウントを借用できるようにする：

```bash
# Cloud Buildサービスアカウント → Cloud Runサービスアカウント
gcloud iam service-accounts add-iam-policy-binding ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --project=ai-chat-481005

# Cloud Buildサービスエージェント → Cloud Runサービスアカウント
gcloud iam service-accounts add-iam-policy-binding ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --project=ai-chat-481005
```

##### ステップ5: 実際に使用されているサービスアカウントを確認

ビルドが失敗した場合、どのサービスアカウントが使用されているか確認：

```bash
# 最新のビルドIDを取得
BUILD_ID=$(gcloud builds list --limit=1 --format="value(id)" --region=asia-northeast1)

# 使用されているサービスアカウントを確認
gcloud builds describe ${BUILD_ID} --region=asia-northeast1 --format="yaml(serviceAccount)"
```

##### ステップ6: 権限の確認

リポジトリの権限が正しく付与されているか確認：

```bash
gcloud artifacts repositories get-iam-policy cloud-run-source-deploy \
  --location=asia-northeast1 \
  --project=ai-chat-481005
```

#### 重要なポイント

1. **プロジェクトレベルとリポジトリレベルの両方に権限が必要**
   - プロジェクトレベルの権限だけでは不十分
   - リポジトリレベルの権限も必須

2. **`gcloud run deploy --source` は Compute Engineデフォルトサービスアカウントを使用**
   - Cloud Buildサービスアカウントではない
   - このサービスアカウントにも権限が必要

3. **権限の反映には時間がかかる場合がある**
   - 通常は数分以内だが、最大10-15分かかることもある
   - 権限を付与した直後にデプロイを再試行しても失敗する場合は、少し待ってから再試行

4. **複数のサービスアカウントが関与**
   - 3つのサービスアカウントすべてに権限を付与する必要がある
   - 1つでも不足しているとエラーが発生する

#### 一括設定スクリプト

以下のスクリプトで一括設定できます：

```bash
#!/bin/bash
PROJECT_ID="ai-chat-481005"
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
REGION="asia-northeast1"

echo "プロジェクト番号: ${PROJECT_NUMBER}"

# プロジェクトレベルの権限
echo "プロジェクトレベルの権限を付与中..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# リポジトリレベルの権限
echo "リポジトリレベルの権限を付与中..."
gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
  --location=${REGION} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --project=${PROJECT_ID}

gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
  --location=${REGION} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --project=${PROJECT_ID}

gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
  --location=${REGION} \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --project=${PROJECT_ID}

# サービスアカウント借用権限
echo "サービスアカウント借用権限を付与中..."
gcloud iam service-accounts add-iam-policy-binding ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --project=${PROJECT_ID}

gcloud iam service-accounts add-iam-policy-binding ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --project=${PROJECT_ID}

echo "完了！"
```

### ビルドエラー

```bash
# ログを確認
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")

# 詳細なエラーログを確認
BUILD_ID=$(gcloud builds list --limit=1 --format="value(id)" --region=asia-northeast1)
gcloud logging read "resource.type=build AND resource.labels.build_id=${BUILD_ID}" \
  --project=ai-chat-481005 \
  --limit=50 \
  --format="value(textPayload)" | grep -E "(ERROR|error|denied)"
```

### デプロイエラー

```bash
# サービスの状態を確認
gcloud run services describe ai-chat --region asia-northeast1

# ログを確認
gcloud logs read --service ai-chat --limit 50
```

### コンテナが起動しない

- メモリ不足の場合は`--memory 1Gi`に変更
- タイムアウトの場合は`--timeout 300`を追加

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
