#!/bin/bash
# krgeobuk MySQL 사용자 생성 및 권한 설정
# 환경 변수에서 비밀번호를 읽어 사용자를 생성합니다

set -e

# 환경 변수 확인
if [ -z "$MYSQL_DEV_USER_PASSWORD" ]; then
  echo "ERROR: MYSQL_DEV_USER_PASSWORD 환경 변수가 설정되지 않았습니다!"
  echo "docker-compose.yaml에서 MYSQL_DEV_USER_PASSWORD를 설정하거나 .env 파일에 추가하세요."
  exit 1
fi
# if [ -z "$MYSQL_PROD_USER_PASSWORD" ]; then
#   echo "ERROR: MYSQL_PROD_USER_PASSWORD 환경 변수가 설정되지 않았습니다!"
#   echo "docker-compose.yaml에서 MYSQL_PROD_USER_PASSWORD를 설정하거나 .env 파일에 추가하세요."
#   exit 1
# fi

echo "==================================================================="
echo "MySQL 사용자 생성 중..."
echo "==================================================================="

# 사용자 생성 (환경 변수에서 비밀번호 읽기)
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
  -- =============================================================================
  -- 개발 환경 사용자 생성
  -- =============================================================================
  CREATE USER IF NOT EXISTS 'dev_user'@'%' IDENTIFIED BY '${MYSQL_DEV_USER_PASSWORD}';

  -- =============================================================================
  -- 개발 환경 데이터베이스 권한 부여
  -- =============================================================================
  GRANT ALL PRIVILEGES ON auth_dev.* TO 'dev_user'@'%';
  GRANT ALL PRIVILEGES ON authz_dev.* TO 'dev_user'@'%';
  GRANT ALL PRIVILEGES ON portal_dev.* TO 'dev_user'@'%';
  GRANT ALL PRIVILEGES ON mypick_dev.* TO 'dev_user'@'%';

  -- =============================================================================
  -- 운영 환경 사용자 생성 (미니PC 배포 시 주석 해제)
  -- =============================================================================
  -- CREATE USER IF NOT EXISTS 'geobuk'@'%' IDENTIFIED BY '${MYSQL_PROD_USER_PASSWORD}';

  -- =============================================================================
  -- 운영 환경 데이터베이스 권한 부여 (미니PC 배포 시 주석 해제)
  -- =============================================================================
  -- GRANT ALL PRIVILEGES ON auth_prod.* TO 'geobuk'@'%';
  -- GRANT ALL PRIVILEGES ON authz_prod.* TO 'geobuk'@'%';
  -- GRANT ALL PRIVILEGES ON portal_prod.* TO 'geobuk'@'%';
  -- GRANT ALL PRIVILEGES ON mypick_prod.* TO 'geobuk'@'%';

  -- =============================================================================
  -- 권한 적용
  -- =============================================================================
  FLUSH PRIVILEGES;

  -- =============================================================================
  -- 생성된 사용자 확인
  -- =============================================================================
  SELECT User, Host FROM mysql.user WHERE User = 'dev_user';
  -- SELECT User, Host FROM mysql.user WHERE User = 'geobuk';
EOSQL

echo "✓ dev_user 사용자 생성 완료"
echo "  - auth_dev 권한 부여: OK"
echo "  - authz_dev 권한 부여: OK"
echo "  - portal_dev 권한 부여: OK"
echo "  - mypick_dev 권한 부여: OK"
# echo "✓ geobuk 사용자 생성 완료"
# echo "  - auth_prod 권한 부여: OK"
# echo "  - authz_prod 권한 부여: OK"
# echo "  - portal_prod 권한 부여: OK"
# echo "  - mypick_prod 권한 부여: OK"
echo "==================================================================="
echo "MySQL 사용자 설정 완료!"
echo "==================================================================="
