#!/bin/bash

set -e

echo "========================================="
echo "Kubernetes Dashboard 제거"
echo "========================================="
echo ""

# Ingress 삭제
echo "[1/3] Ingress 삭제 중..."
kubectl delete -f "$(dirname "$0")/ingress.yaml" --ignore-not-found=true

# 관리자 계정 삭제
echo ""
echo "[2/3] 관리자 계정 삭제 중..."
kubectl delete -f "$(dirname "$0")/admin-user.yaml" --ignore-not-found=true

# Dashboard 삭제
echo ""
echo "[3/3] Kubernetes Dashboard 삭제 중..."
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml --ignore-not-found=true

echo ""
echo "========================================="
echo "제거 완료!"
echo "========================================="
echo ""
