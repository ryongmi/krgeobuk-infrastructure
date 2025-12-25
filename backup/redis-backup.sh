#!/bin/bash

# krgeobuk Redis 백업 스크립트

set -e  # 에러 발생 시 즉시 종료

# 설정
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_DIR:-/opt/krgeobuk/backups/redis}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
REDIS_PASSWORD="${REDIS_PASSWORD:-krgeobuk_redis_password}"

# 백업 디렉토리 생성
mkdir -p "${BACKUP_DIR}"

echo "========================================="
echo "krgeobuk Redis Backup"
echo "Time: ${DATE}"
echo "========================================="

# Redis SAVE 명령 실행
echo "Starting Redis backup (SAVE)..."
docker exec krgeobuk-redis redis-cli -a "${REDIS_PASSWORD}" --no-auth-warning SAVE

# dump.rdb 파일 복사
docker cp krgeobuk-redis:/data/dump.rdb "${BACKUP_DIR}/dump_${DATE}.rdb"

if [ $? -eq 0 ]; then
  echo "✓ Redis backup completed: dump_${DATE}.rdb"

  # 압축
  gzip "${BACKUP_DIR}/dump_${DATE}.rdb"
  echo "✓ Compressed: dump_${DATE}.rdb.gz"
else
  echo "✗ Redis backup failed!"
  exit 1
fi

# 오래된 백업 파일 삭제
echo "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "*.rdb.gz" -mtime +${RETENTION_DAYS} -delete

# 백업 목록 표시
echo ""
echo "Available backups:"
ls -lh "${BACKUP_DIR}"/*.rdb.gz 2>/dev/null | tail -5 || echo "No backups found"

echo ""
echo "========================================="
echo "Backup completed successfully!"
echo "========================================="
