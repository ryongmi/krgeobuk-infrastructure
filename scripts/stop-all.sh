#!/bin/bash

#####################################################################
# krgeobuk 인프라 전체 중지 스크립트
#
# 설명: MySQL, Redis, Jenkins, Verdaccio 컨테이너를 중지합니다.
# 사용법: ./stop-all.sh [--remove-volumes]
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

# 옵션 파싱
REMOVE_VOLUMES=false
if [ "$1" == "--remove-volumes" ]; then
    REMOVE_VOLUMES=true
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}krgeobuk 인프라 중지${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Docker Compose 파일 확인
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}[ERROR] docker-compose.yaml 파일을 찾을 수 없습니다.${NC}"
    echo -e "경로: $COMPOSE_FILE"
    exit 1
fi

# 볼륨 삭제 경고
if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}[WARNING] 볼륨 삭제 옵션이 활성화되었습니다!${NC}"
    echo -e "${RED}모든 데이터베이스 데이터가 삭제됩니다.${NC}"
    echo ""
    read -p "계속하시겠습니까? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}[INFO] 작업이 취소되었습니다.${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}[INFO] Docker Compose로 서비스 중지 중...${NC}"
echo ""

# Docker Compose 중지
cd "$PROJECT_ROOT"

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}[INFO] 볼륨을 포함하여 중지합니다...${NC}"
    docker-compose -f "$COMPOSE_FILE" down -v
else
    docker-compose -f "$COMPOSE_FILE" down
fi

echo ""
echo -e "${GREEN}[SUCCESS] 모든 서비스가 중지되었습니다.${NC}"
echo ""

# 컨테이너 상태 확인
echo -e "${YELLOW}[INFO] 남아있는 컨테이너 확인:${NC}"
docker ps -a | grep krgeobuk || echo "  (없음)"

echo ""

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}[INFO] 볼륨이 삭제되었습니다.${NC}"
    echo -e "${YELLOW}다음 시작 시 데이터베이스가 초기화됩니다.${NC}"
else
    echo -e "${GREEN}[INFO] 데이터는 보존되었습니다.${NC}"
    echo -e "${YELLOW}볼륨도 삭제하려면 다음 명령어를 사용하세요:${NC}"
    echo -e "  ./stop-all.sh --remove-volumes"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}중지 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
