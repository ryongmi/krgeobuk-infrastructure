#!/bin/bash

#####################################################################
# krgeobuk 인프라 헬스체크 스크립트
#
# 설명: MySQL, Redis, Jenkins, Verdaccio의 상태를 확인합니다.
# 사용법: ./health-check.sh
#####################################################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 결과 저장
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}krgeobuk 인프라 헬스체크${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

#####################################################################
# 헬스체크 함수
#####################################################################

check_docker() {
    echo -n "Docker 상태 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if docker info > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 정상${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 실패${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_container() {
    local container_name=$1
    local display_name=$2

    echo -n "$display_name 컨테이너 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        echo -e "${GREEN}✓ 실행 중${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 중지됨${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_mysql() {
    echo -n "MySQL 연결 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if docker exec krgeobuk-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-password} -e "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 정상${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))

        # 데이터베이스 확인
        echo -n "  └─ 데이터베이스 확인... "
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        DBS=$(docker exec krgeobuk-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-password} -e "SHOW DATABASES" 2>/dev/null | grep -E "auth_dev|auth_prod|authz_dev|authz_prod" | wc -l)
        if [ "$DBS" -ge 4 ]; then
            echo -e "${GREEN}✓ ${DBS}개 발견${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            echo -e "${YELLOW}⚠ ${DBS}개만 발견 (4개 필요)${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
        return 0
    else
        echo -e "${RED}✗ 연결 실패${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_redis() {
    echo -n "Redis 연결 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if docker exec krgeobuk-redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 정상${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))

        # 메모리 사용량 확인
        echo -n "  └─ 메모리 사용량... "
        MEMORY=$(docker exec krgeobuk-redis redis-cli info memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        echo -e "${BLUE}${MEMORY}${NC}"
        return 0
    else
        echo -e "${RED}✗ 연결 실패${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_jenkins() {
    echo -n "Jenkins 웹 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|403"; then
        echo -e "${GREEN}✓ 정상${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 접속 실패${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_verdaccio() {
    echo -n "Verdaccio 웹 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:4873 | grep -q "200"; then
        echo -e "${GREEN}✓ 정상${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 접속 실패${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_disk() {
    echo -n "디스크 사용량 확인... "
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    USAGE=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$USAGE" -lt 80 ]; then
        echo -e "${GREEN}✓ ${USAGE}%${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    elif [ "$USAGE" -lt 90 ]; then
        echo -e "${YELLOW}⚠ ${USAGE}% (주의)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ ${USAGE}% (위험)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

#####################################################################
# 헬스체크 실행
#####################################################################

# Docker 확인
check_docker

if [ $? -eq 0 ]; then
    echo ""

    # 컨테이너 확인
    check_container "krgeobuk-mysql" "MySQL"
    check_container "krgeobuk-redis" "Redis"
    check_container "jenkins" "Jenkins"
    check_container "verdaccio" "Verdaccio"

    echo ""

    # 서비스 연결 확인
    check_mysql
    check_redis
    check_jenkins
    check_verdaccio

    echo ""

    # 시스템 리소스 확인
    check_disk
fi

#####################################################################
# 결과 출력
#####################################################################

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}헬스체크 결과${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "총 체크:   ${TOTAL_CHECKS}"
echo -e "${GREEN}성공:      ${PASSED_CHECKS}${NC}"
echo -e "${RED}실패:      ${FAILED_CHECKS}${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ 모든 서비스가 정상입니다!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ 일부 서비스에 문제가 있습니다.${NC}"
    echo -e "${YELLOW}로그 확인: docker-compose logs -f${NC}"
    exit 1
fi
