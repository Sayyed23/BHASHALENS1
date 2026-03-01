#!/bin/bash

# BhashaLens AWS Infrastructure Deployment Script
# This script automates the deployment of BhashaLens infrastructure to AWS

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_info "All prerequisites met!"
}

check_bedrock_access() {
    print_info "Checking Amazon Bedrock model access..."
    
    AWS_REGION=${AWS_REGION:-us-east-1}
    
    print_warning "Please ensure you have enabled access to the following Bedrock models:"
    echo "  - Claude 3 Sonnet (anthropic.claude-3-sonnet-20240229-v1:0)"
    echo "  - Titan Text Premier (amazon.titan-text-premier-v1:0)"
    echo "  - Titan Embeddings (amazon.titan-embed-text-v2:0)"
    echo ""
    echo "To enable model access:"
    echo "  1. Go to AWS Console → Amazon Bedrock → Model access"
    echo "  2. Request access to the models listed above"
    echo "  3. Wait for approval (usually instant)"
    echo ""
    
    read -p "Have you enabled Bedrock model access? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Please enable Bedrock model access before continuing."
        exit 1
    fi
}

initialize_terraform() {
    print_info "Initializing Terraform..."
    cd terraform
    terraform init
    cd ..
}

plan_deployment() {
    print_info "Planning infrastructure deployment..."
    cd terraform
    terraform plan -out=tfplan
    cd ..
    
    echo ""
    print_warning "Please review the plan above carefully."
    read -p "Do you want to proceed with deployment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
}

deploy_infrastructure() {
    print_info "Deploying infrastructure..."
    cd terraform
    terraform apply tfplan
    cd ..
    
    print_info "Infrastructure deployed successfully!"
}

display_outputs() {
    print_info "Deployment Summary:"
    echo ""
    cd terraform
    terraform output -json > outputs.json
    
    API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "N/A")
    DASHBOARD_URL=$(terraform output -raw cloudwatch_dashboard_url 2>/dev/null || echo "N/A")
    S3_BUCKET=$(terraform output -json s3_buckets 2>/dev/null | jq -r '.language_packs.name' || echo "N/A")
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  API Endpoint: $API_ENDPOINT"
    echo "  S3 Bucket: $S3_BUCKET"
    echo "  CloudWatch Dashboard: $DASHBOARD_URL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    print_info "Save these values for configuring your Flutter application."
    echo ""
    print_info "Next steps:"
    echo "  1. Test the API endpoints (see README.md for examples)"
    echo "  2. Configure CloudWatch alarms with SNS notifications"
    echo "  3. Update Flutter app with API endpoint"
    echo "  4. Upload language packs to S3 bucket"
    
    cd ..
}

test_api() {
    print_info "Testing API endpoints..."
    cd terraform
    API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null)
    cd ..
    
    if [ "$API_ENDPOINT" == "N/A" ]; then
        print_error "Could not retrieve API endpoint."
        return
    fi
    
    print_info "Testing translation endpoint..."
    RESPONSE=$(curl -s -X POST "$API_ENDPOINT/translate" \
        -H "Content-Type: application/json" \
        -d '{
            "source_text": "Hello",
            "source_lang": "en",
            "target_lang": "hi"
        }')
    
    if echo "$RESPONSE" | jq -e '.translated_text' > /dev/null 2>&1; then
        print_info "Translation endpoint is working!"
        echo "Response: $RESPONSE"
    else
        print_warning "Translation endpoint test failed. Response: $RESPONSE"
    fi
}

# Main execution
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  BhashaLens AWS Infrastructure Deployment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    check_prerequisites
    check_bedrock_access
    initialize_terraform
    plan_deployment
    deploy_infrastructure
    display_outputs
    
    echo ""
    read -p "Would you like to test the API endpoints? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_api
    fi
    
    echo ""
    print_info "Deployment complete! 🎉"
}

# Run main function
main
