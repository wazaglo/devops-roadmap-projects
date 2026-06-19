#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="ansible-server"

echo "==> Creating CloudFormation stack: $STACK_NAME"
aws cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body file://cloudformation/template.yaml \
  --parameters file://cloudformation/parameters.json \
  --capabilities CAPABILITY_NAMED_IAM

echo "==> Waiting for stack creation to complete..."
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME"

echo "==> Retrieving public IP..."
PUBLIC_IP=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
  --output text)

echo "==> Updating inventory.ini with IP: $PUBLIC_IP"
cat > inventory.ini <<EOF
[webserver]
$PUBLIC_IP ansible_user=ubuntu
EOF

echo "==> Running Ansible playbook..."
ansible-playbook setup.yml

echo "==> Done! Site should be available at http://$PUBLIC_IP"
