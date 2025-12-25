#!/bin/bash

#####################################################################
# krgeobuk 인프라 전체 시작 스크립트
#
# 설명: MySQL, Redis, Jenkins, Verdaccio 컨테이너를 시작합니다.
# 사용법: ./start-all.sh
#####################################################################

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose/docker-compose.yaml"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}krgeobuk 인프라 시작${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# .env 파일 확인
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${RED}[ERROR] .env 파일을 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}다음 명령어로 .env 파일을 생성하세요:${NC}"
    echo -e "  cp .env.example .env"
    echo -e "  # .env 파일을 열어 실제 값을 입력하세요"
    exit 1
fi

# Docker Compose 파일 확인
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}[ERROR] docker-compose.yaml 파일을 찾을 수 없습니다.${NC}"
    echo -e "경로: $COMPOSE_FILE"
    exit 1
fi

# Docker가 실행 중인지 확인
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] Docker가 실행되고 있지 않습니다.${NC}"
    echo -e "${YELLOW}Docker를 시작한 후 다시 시도하세요.${NC}"
    exit 1
fi

echo -e "${YELLOW}[INFO] Docker Compose로 서비스 시작 중...${NC}"
echo ""

# Docker Compose 시작
cd "$PROJECT_ROOT"
docker-compose -f "$COMPOSE_FILE" up -d

echo ""
echo -e "${GREEN}[SUCCESS] 모든 서비스가 시작되었습니다.${NC}"
echo ""

# 컨테이너 상태 확인
echo -e "${YELLOW}[INFO] 컨테이너 상태:${NC}"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}서비스 접속 정보${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "MySQL:       localhost:3306"
echo -e "Redis:       localhost:6379"
echo -e "Jenkins:     http://localhost:8080"
echo -e "Verdaccio:   http://localhost:4873"
echo ""

# 헬스체크 대기
echo -e "${YELLOW}[INFO] 서비스 헬스체크 대기 중 (30초)...${NC}"
sleep 30

# 헬스체크 실행
if [ -f "$SCRIPT_DIR/health-check.sh" ]; then
    echo ""
    bash "$SCRIPT_DIR/health-check.sh"
else
    echo -e "${YELLOW}[WARN] health-check.sh 스크립트를 찾을 수 없습니다.${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}시작 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. Jenkins 초기 설정: http://localhost:8080"
echo -e "  2. 데이터베이스 초기화: ./scripts/init-databases.sh"
echo -e "  3. 로그 확인: docker-compose -f $COMPOSE_FILE logs -f"
echo ""
