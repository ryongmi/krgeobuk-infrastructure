#!/bin/bash

echo "========================================="
echo "Dashboard 로그인 토큰 생성"
echo "========================================="
echo ""

TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)

echo "토큰:"
echo ""
echo "$TOKEN"
echo ""
echo "========================================="
echo ""
echo "이 토큰을 복사하여 Dashboard 로그인 화면에 붙여넣으세요."
echo ""
