# GitHub Actions ワークフロー

## セットアップ手順

### 1. Google Cloud サービスアカウントキーの作成

1. Google Cloud Consoleにアクセス
2. **IAM & Admin** > **Service Accounts** に移動
3. 新しいサービスアカウントを作成、または既存のものを使用
4. サービスアカウントに以下のロールを付与：
   - Cloud Run Admin
   - Cloud Build Editor
   - Artifact Registry Writer
   - Service Account User

5. サービスアカウントのキーを作成：
   ```bash
   gcloud iam service-accounts keys create key.json \
     --iam-account=your-service-account@your-project.iam.gserviceaccount.com
   ```

### 2. GitHub Secrets の設定

GitHubリポジトリの **Settings** > **Secrets and variables** > **Actions** で以下を設定：

- `GCP_SA_KEY`: サービスアカウントキーのJSONファイルの内容（全体をコピー）
- `ANTHROPIC_API_KEY`: Anthropic APIキー

### 3. ワークフローの動作

- **mainブランチへのpush**: 自動的にデプロイ
- **手動実行**: Actionsタブから手動で実行可能
- **プルリクエスト**: デプロイはスキップ（必要に応じて変更可能）

## トラブルシューティング

### 権限エラーが発生する場合

`setup-gcp-permissions` を実行して権限を設定：

```bash
make setup-gcp-permissions PROJECT_ID=ai-chat-481005
```

または、`DEPLOY.md`の「Artifact Registry権限エラー」セクションを参照してください。


