#!/bin/bash

#####################################################################
# krgeobuk 데이터베이스 초기화 스크립트
#
# 설명: MySQL 데이터베이스와 사용자를 생성합니다.
# 사용법: ./init-databases.sh
# 참고: MySQL 컨테이너가 실행 중이어야 합니다.
#####################################################################

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}krgeobuk 데이터베이스 초기화${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# MySQL 컨테이너 확인
if ! docker ps --filter "name=krgeobuk-mysql" --filter "status=running" | grep -q "krgeobuk-mysql"; then
    echo -e "${RED}[ERROR] krgeobuk-mysql 컨테이너가 실행 중이지 않습니다.${NC}"
    echo -e "${YELLOW}다음 명령어로 컨테이너를 시작하세요:${NC}"
    echo -e "  ./scripts/start-all.sh"
    exit 1
fi

# .env 파일 확인
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${RED}[ERROR] .env 파일을 찾을 수 없습니다.${NC}"
    exit 1
fi

# .env 파일 로드
source "$PROJECT_ROOT/.env"

# 비밀번호 확인
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo -e "${RED}[ERROR] MYSQL_ROOT_PASSWORD가 설정되지 않았습니다.${NC}"
    exit 1
fi

echo -e "${YELLOW}[INFO] 데이터베이스 초기화를 시작합니다...${NC}"
echo ""

#####################################################################
# 데이터베이스 생성
#####################################################################

echo -e "${BLUE}[1/3] 데이터베이스 생성${NC}"
echo ""

# SQL 명령어 생성
DB_SQL="
-- 개발 환경 데이터베이스
CREATE DATABASE IF NOT EXISTS auth_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS authz_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS portal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS mypick CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 운영 환경 데이터베이스
CREATE DATABASE IF NOT EXISTS auth_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS authz_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"

# MySQL 실행
echo "$DB_SQL" | docker exec -i krgeobuk-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 데이터베이스 생성 완료${NC}"
else
    echo -e "${RED}✗ 데이터베이스 생성 실패${NC}"
    exit 1
fi

echo ""

#####################################################################
# 사용자 생성 및 권한 부여
#####################################################################

echo -e "${BLUE}[2/3] 사용자 생성 및 권한 부여${NC}"
echo ""

# 기본 비밀번호 설정 (환경 변수에서 가져오거나 기본값 사용)
AUTH_PASSWORD=${MYSQL_AUTH_PASSWORD:-"auth_password"}
AUTHZ_PASSWORD=${MYSQL_AUTHZ_PASSWORD:-"authz_password"}
PORTAL_PASSWORD=${MYSQL_PORTAL_PASSWORD:-"portal_password"}
MYPICK_PASSWORD=${MYSQL_MYPICK_PASSWORD:-"mypick_password"}

# 사용자 생성 SQL
USER_SQL="
-- auth-server 사용자
CREATE USER IF NOT EXISTS 'auth_user'@'%' IDENTIFIED BY '${AUTH_PASSWORD}';
GRANT ALL PRIVILEGES ON auth_dev.* TO 'auth_user'@'%';
GRANT ALL PRIVILEGES ON auth_prod.* TO 'auth_user'@'%';

-- authz-server 사용자
CREATE USER IF NOT EXISTS 'authz_user'@'%' IDENTIFIED BY '${AUTHZ_PASSWORD}';
GRANT ALL PRIVILEGES ON authz_dev.* TO 'authz_user'@'%';
GRANT ALL PRIVILEGES ON authz_prod.* TO 'authz_user'@'%';

-- portal-server 사용자
CREATE USER IF NOT EXISTS 'portal_user'@'%' IDENTIFIED BY '${PORTAL_PASSWORD}';
GRANT ALL PRIVILEGES ON portal.* TO 'portal_user'@'%';

-- mypick-server 사용자
CREATE USER IF NOT EXISTS 'mypick_user'@'%' IDENTIFIED BY '${MYPICK_PASSWORD}';
GRANT ALL PRIVILEGES ON mypick.* TO 'mypick_user'@'%';

FLUSH PRIVILEGES;
"

# MySQL 실행
echo "$USER_SQL" | docker exec -i krgeobuk-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 사용자 생성 및 권한 부여 완료${NC}"
else
    echo -e "${RED}✗ 사용자 생성 실패${NC}"
    exit 1
fi

echo ""

#####################################################################
# 확인
#####################################################################

echo -e "${BLUE}[3/3] 생성된 데이터베이스 확인${NC}"
echo ""

# 데이터베이스 목록 조회
DBS=$(docker exec krgeobuk-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES" 2>/dev/null)

echo "$DBS" | grep -E "Database|auth_dev|auth_prod|authz_dev|authz_prod|portal|mypick"

echo ""

#####################################################################
# 완료
#####################################################################

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}데이터베이스 초기화 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${BLUE}생성된 데이터베이스:${NC}"
echo -e "  - auth_dev      (사용자: auth_user)"
echo -e "  - auth_prod     (사용자: auth_user)"
echo -e "  - authz_dev     (사용자: authz_user)"
echo -e "  - authz_prod    (사용자: authz_user)"
echo -e "  - portal        (사용자: portal_user)"
echo -e "  - mypick        (사용자: mypick_user)"

echo ""
echo -e "${BLUE}Redis 데이터베이스 매핑:${NC}"
echo -e "  - DB 0: auth-dev"
echo -e "  - DB 1: auth-prod"
echo -e "  - DB 2: authz-dev"
echo -e "  - DB 3: authz-prod"
echo -e "  - DB 4: portal"
echo -e "  - DB 5: mypick"

echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. Kubernetes Secret 생성 (krgeobuk-k8s 리포지토리)"
echo -e "  2. 애플리케이션 배포"
echo ""
