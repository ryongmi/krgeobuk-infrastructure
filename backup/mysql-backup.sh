#!/bin/bash

# krgeobuk MySQL 백업 스크립트

set -e  # 에러 발생 시 즉시 종료

# 설정
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_BACKUP_DIR="${MYSQL_BACKUP_DIR:-${BACKUP_DIR:-/opt/krgeobuk/backups}/mysql}"
MYSQL_RETENTION_DAYS="${MYSQL_RETENTION_DAYS:-${RETENTION_DAYS:-7}}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-krgeobuk_root_password}"

# 백업 디렉토리 생성
mkdir -p "${MYSQL_BACKUP_DIR}"

echo "========================================="
echo "krgeobuk MySQL Backup"
echo "Time: ${DATE}"
echo "Backup Directory: ${MYSQL_BACKUP_DIR}"
echo "========================================="

# 모든 데이터베이스 백업
echo "Starting MySQL backup..."
docker exec krgeobuk-mysql mysqldump \
  -u root -p"${MYSQL_ROOT_PASSWORD}" \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --set-gtid-purged=OFF \
  > "${MYSQL_BACKUP_DIR}/all-databases_${DATE}.sql"

if [ $? -eq 0 ]; then
  echo "✓ MySQL backup completed: all-databases_${DATE}.sql"

  # 압축
  gzip "${MYSQL_BACKUP_DIR}/all-databases_${DATE}.sql"
  echo "✓ Compressed: all-databases_${DATE}.sql.gz"
else
  echo "✗ MySQL backup failed!"
  exit 1
fi

# 오래된 백업 파일 삭제
echo "Cleaning up old backups (older than ${MYSQL_RETENTION_DAYS} days)..."
find "${MYSQL_BACKUP_DIR}" -name "*.sql.gz" -mtime +${MYSQL_RETENTION_DAYS} -delete

# 백업 목록 표시
echo ""
echo "Available backups:"
ls -lh "${MYSQL_BACKUP_DIR}"/*.sql.gz 2>/dev/null | tail -5 || echo "No backups found"

echo ""
echo "========================================="
echo "Backup completed successfully!"
echo "========================================="
