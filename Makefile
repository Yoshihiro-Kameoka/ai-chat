.PHONY: help install dev build clean deploy setup env-check prisma-generate prisma-push deploy-gcp setup-gcp-permissions

# デフォルトターゲット：ヘルプを表示
help:
	@echo "AI Chat - 利用可能なコマンド:"
	@echo ""
	@echo "  make install          - 依存パッケージをインストール"
	@echo "  make setup            - 初期セットアップ（install + prisma-generate + env確認）"
	@echo "  make dev              - 開発サーバーを起動"
	@echo "  make build            - 本番用ビルド"
	@echo "  make start            - 本番サーバーを起動"
	@echo "  make lint             - ESLintを実行"
	@echo "  make clean            - ビルド成果物を削除"
	@echo ""
	@echo "  make prisma-generate  - Prisma Clientを生成"
	@echo "  make prisma-push      - Prisma SchemaをDBに反映"
	@echo "  make prisma-studio    - Prisma Studioを起動"
	@echo ""
	@echo "  make docker-build          - Dockerイメージをビルド"
	@echo "  make deploy-gcp            - Google Cloud Runにデプロイ"
	@echo "  make setup-gcp-permissions - GCPデプロイ用権限を設定（初回のみ）"
	@echo "  make env-check             - 環境変数をチェック"

# 依存パッケージのインストール
install:
	@echo "📦 依存パッケージをインストール中..."
	npm install

# 初期セットアップ
setup: install prisma-generate env-check
	@echo "✅ セットアップ完了！"
	@echo ""
	@echo "次のステップ："
	@echo "  1. .env.localファイルにANTHROPIC_API_KEYを設定"
	@echo "  2. make dev で開発サーバーを起動"

# 環境変数チェック
env-check:
	@echo "🔍 環境変数をチェック中..."
	@if [ ! -f .env.local ]; then \
		echo "⚠️  .env.localファイルが見つかりません"; \
		echo "   .env.exampleをコピーして作成してください:"; \
		echo "   cp .env.example .env.local"; \
	else \
		echo "✅ .env.localファイルが存在します"; \
		if grep -q "^ANTHROPIC_API_KEY=$$" .env.local; then \
			echo "⚠️  ANTHROPIC_API_KEYが設定されていません"; \
		else \
			echo "✅ ANTHROPIC_API_KEYが設定されています"; \
		fi; \
	fi

# Prisma Clientの生成
prisma-generate:
	@echo "🔨 Prisma Clientを生成中..."
	npx prisma generate

# Prisma SchemaをDBに反映
prisma-push:
	@echo "📤 Prisma SchemaをDBに反映中..."
	npx prisma db push

# Prisma Studioの起動
prisma-studio:
	@echo "🎨 Prisma Studioを起動中..."
	npx prisma studio

# 開発サーバーの起動
dev:
	@echo "🚀 開発サーバーを起動中..."
	npm run dev

# 本番用ビルド
build:
	@echo "🏗️  本番用ビルド中..."
	npm run build

# 本番サーバーの起動
start:
	@echo "▶️  本番サーバーを起動中..."
	npm start

# ESLintの実行
lint:
	@echo "🔍 ESLintを実行中..."
	npm run lint

# ビルド成果物の削除
clean:
	@echo "🧹 ビルド成果物を削除中..."
	rm -rf .next
	rm -rf node_modules/.cache

# Dockerイメージのビルド
docker-build:
	@echo "🐳 Dockerイメージをビルド中..."
	docker build -t ai-chat:latest .

# Google Cloud Runへのデプロイ（ソースから直接デプロイ）
deploy-gcp:
	@echo "☁️  Google Cloud Runにデプロイ中..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "❌ エラー: PROJECT_ID変数が設定されていません"; \
		echo "   使用方法: make deploy-gcp PROJECT_ID=your-project-id"; \
		echo "   例: make deploy-gcp PROJECT_ID=ai-chat-481005"; \
		exit 1; \
	fi
	@if [ -z "$(ANTHROPIC_API_KEY)" ]; then \
		echo "❌ エラー: ANTHROPIC_API_KEY環境変数が設定されていません"; \
		echo "   使用方法: ANTHROPIC_API_KEY=your-key make deploy-gcp PROJECT_ID=your-project-id"; \
		exit 1; \
	fi
	@echo "プロジェクトID: $(PROJECT_ID)"
	@echo "リージョン: asia-northeast1"
	@echo ""
	@echo "📋 ステップ 1: プロジェクト設定を確認中..."
	gcloud config set project $(PROJECT_ID)
	@echo "🔧 ステップ 2: 必要なAPIを有効化中..."
	-gcloud services enable cloudbuild.googleapis.com --project=$(PROJECT_ID)
	-gcloud services enable run.googleapis.com --project=$(PROJECT_ID)
	@echo "☁️  ステップ 3: Cloud Runにソースからデプロイ中..."
	gcloud run deploy ai-chat \
		--source . \
		--platform managed \
		--region asia-northeast1 \
		--allow-unauthenticated \
		--memory 512Mi \
		--cpu 1 \
		--max-instances 10 \
		--min-instances 0 \
		--set-env-vars "ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY)" \
		--project=$(PROJECT_ID)
	@echo ""
	@echo "✅ デプロイ完了！"
	@echo ""
	@SERVICE_URL=$$(gcloud run services describe ai-chat --region=asia-northeast1 --project=$(PROJECT_ID) --format='value(status.url)' 2>/dev/null); \
	if [ -n "$$SERVICE_URL" ]; then \
		echo "🌐 アプリケーションURL: $$SERVICE_URL"; \
		echo ""; \
		echo "📊 Cloud Runコンソール:"; \
		echo "   https://console.cloud.google.com/run/detail/asia-northeast1/ai-chat?project=$(PROJECT_ID)"; \
	fi

# 権限設定（初回デプロイ前または権限エラーが発生した場合に実行）
setup-gcp-permissions:
	@echo "🔐 Google Cloud Runデプロイ用の権限を設定中..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "❌ エラー: PROJECT_ID変数が設定されていません"; \
		echo "   使用方法: make setup-gcp-permissions PROJECT_ID=your-project-id"; \
		exit 1; \
	fi
	@PROJECT_NUMBER=$$(gcloud projects describe $(PROJECT_ID) --format="value(projectNumber)" 2>/dev/null); \
	if [ -z "$$PROJECT_NUMBER" ]; then \
		echo "❌ エラー: プロジェクト $(PROJECT_ID) が見つかりません"; \
		exit 1; \
	fi; \
	echo "プロジェクト番号: $$PROJECT_NUMBER"; \
	echo ""; \
	echo "📋 プロジェクトレベルの権限を付与中..."; \
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member="serviceAccount:service-$$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
		--role="roles/editor" || true; \
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member="serviceAccount:$$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
		--role="roles/artifactregistry.writer" || true; \
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member="serviceAccount:service-$$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
		--role="roles/artifactregistry.writer" || true; \
	echo ""; \
	echo "📦 リポジトリレベルの権限を付与中..."; \
	gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
		--location=asia-northeast1 \
		--member="serviceAccount:$$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
		--role="roles/artifactregistry.writer" \
		--project=$(PROJECT_ID) || true; \
	gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
		--location=asia-northeast1 \
		--member="serviceAccount:$$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
		--role="roles/artifactregistry.writer" \
		--project=$(PROJECT_ID) || true; \
	gcloud artifacts repositories add-iam-policy-binding cloud-run-source-deploy \
		--location=asia-northeast1 \
		--member="serviceAccount:service-$$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
		--role="roles/artifactregistry.writer" \
		--project=$(PROJECT_ID) || true; \
	echo ""; \
	echo "🔑 サービスアカウント借用権限を付与中..."; \
	gcloud iam service-accounts add-iam-policy-binding $$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
		--member="serviceAccount:$$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
		--role="roles/iam.serviceAccountUser" \
		--project=$(PROJECT_ID) || true; \
	gcloud iam service-accounts add-iam-policy-binding $$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
		--member="serviceAccount:service-$$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
		--role="roles/iam.serviceAccountUser" \
		--project=$(PROJECT_ID) || true; \
	echo ""; \
	echo "✅ 権限設定完了！"

# 開発環境のリセット（完全クリーン）
reset: clean
	@echo "♻️  開発環境をリセット中..."
	rm -rf node_modules
	rm -rf .next
	rm -rf prisma/generated
	@echo "✅ リセット完了！make setupを実行してください"
