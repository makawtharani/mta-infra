#!/bin/bash
#
# Note: This script is no longer needed!
# Terraform now automatically packages Lambda code from src/ directory.
#
# The lambda_package.zip is created by Terraform using the archive_file data source.
# Lambda uses Klayers for boto3 - no dependencies to install.
#

echo "================================================"
echo "INFO: Lambda packaging is now handled by Terraform"
echo "================================================"
echo ""
echo "Terraform automatically creates lambda_package.zip from modules/lambda_chat/src/"
echo "No manual build step required - just run 'terraform apply'"
echo ""
echo "If you need to manually test packaging:"
echo "  cd modules/lambda_chat/src"
echo "  zip -r ../lambda_package.zip ."
echo ""

