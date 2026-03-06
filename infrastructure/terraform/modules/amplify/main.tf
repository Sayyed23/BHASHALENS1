# AWS Amplify configuration for Flutter Web App

resource "aws_amplify_app" "bhashalens_web" {
  name       = "${var.project_name}-web-${var.environment}"
  repository = var.github_repository

  # GitHub personal access token
  access_token = var.github_token

  # Build Spec for Flutter Web
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - echo "Phase: preBuild"
            - git clone https://github.com/flutter/flutter.git -b stable --depth 1
            - export PATH="$PATH:$(pwd)/flutter/bin"
            - flutter config --enable-web
            - cd bhashalens_app && flutter pub get
        build:
          commands:
            - echo "Phase: build"
            - export PATH="$PATH:$(pwd)/flutter/bin"
            - cd bhashalens_app && flutter build web --release
      artifacts:
        baseDirectory: bhashalens_app/build/web
        files:
          - '**/*'
      cache:
        paths:
          - "flutter/.pub-cache/**/*"
          - "flutter/bin/cache/**/*"
  EOT

  # Environment variables accessible during build and optionally at runtime
  environment_variables = {
    ENV             = var.environment
    API_GATEWAY_URL = var.api_gateway_url
  }

  # Auto branch creation for CI/CD
  enable_auto_branch_creation = true
  auto_branch_creation_patterns = [
    "feature/*",
    "develop",
    "release/*"
  ]

  auto_branch_creation_config {
    enable_auto_build = true
    environment_variables = {
      ENV = var.environment
    }
  }
  # Custom rules for single page application routing (Flutter web)
  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|ttf|map|json)$)([^.]+$)/>"
    status = "200"
    target = "/index.html"
  }
}

# Branch connection (main maps to dev/prod based on strategy, usually main -> prod, others -> dev)
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.bhashalens_web.id
  branch_name = "main"

  # Environment specific overrides
  environment_variables = {
    ENV = var.environment
  }

  enable_auto_build = true
}

# Optional Custom Domain Configuration
resource "aws_amplify_domain_association" "custom_domain" {
  count = var.enable_custom_domain ? 1 : 0

  app_id      = aws_amplify_app.bhashalens_web.id
  domain_name = var.custom_domain_name

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = var.environment == "prod" ? "" : var.environment
  }

  # Add www subdomain for bare domains (typically in prod)
  dynamic "sub_domain" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      branch_name = aws_amplify_branch.main.branch_name
      prefix      = "www"
    }
  }
}
