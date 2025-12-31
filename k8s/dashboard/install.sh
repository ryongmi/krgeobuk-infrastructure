#!/bin/bash

set -e

echo "========================================="
echo "Kubernetes Dashboard 설치"
echo "========================================="
echo ""

# Dashboard 설치
echo "[1/4] Kubernetes Dashboard 설치 중..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

echo ""
echo "[2/4] Dashboard Pod가 준비될 때까지 대기 중..."
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

echo ""
echo "[3/5] 관리자 계정 생성 중..."
kubectl apply -f "$(dirname "$0")/admin-user.yaml"

echo ""
echo "[4/5] Ingress 설정 중..."
kubectl apply -f "$(dirname "$0")/ingress.yaml"

echo ""
echo "[5/5] 토큰 생성 중..."
sleep 2
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)

echo ""
echo "========================================="
echo "설치 완료!"
echo "========================================="
echo ""
echo "Dashboard 접속 방법:"
echo ""
echo "[ 옵션 1 ] Ingress 사용 (간단한 URL)"
echo "   브라우저에서 접속:"
echo "   http://dashboard.192.168.0.28.nip.io"
echo ""
echo "[ 옵션 2 ] kubectl proxy 사용"
echo "   1. 프록시 실행: kubectl proxy"
echo "   2. 브라우저 접속:"
echo "      http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "로그인 토큰:"
echo ""
echo "$TOKEN"
echo ""
echo "========================================="
echo ""
echo "토큰을 다시 생성하려면:"
echo "  ./get-token.sh"
echo ""
