#!/bin/bash

# krgeobuk 복구 스크립트

set -e  # 에러 발생 시 즉시 종료

BACKUP_FILE=$1
TARGET_TYPE=$2  # mysql or redis

# 사용법 확인
if [ -z "$BACKUP_FILE" ] || [ -z "$TARGET_TYPE" ]; then
  echo "Usage: $0 <backup_file> <mysql|redis>"
  echo ""
  echo "Examples:"
  echo "  $0 /opt/krgeobuk/backups/mysql/all-databases_20241221_120000.sql.gz mysql"
  echo "  $0 /opt/krgeobuk/backups/redis/dump_20241221_120000.rdb.gz redis"
  exit 1
fi

# 백업 파일 존재 확인
if [ ! -f "$BACKUP_FILE" ]; then
  echo "✗ Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "========================================="
echo "krgeobuk Restore"
echo "File: $BACKUP_FILE"
echo "Type: $TARGET_TYPE"
echo "========================================="
echo ""

# 확인 메시지
read -p "⚠️  This will OVERWRITE existing data. Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Restore cancelled."
  exit 0
fi

# MySQL 복구
if [ "$TARGET_TYPE" == "mysql" ]; then
  echo "Restoring MySQL from $BACKUP_FILE..."

  MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-krgeobuk_root_password}"

  # 압축 해제 및 복구
  if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker exec -i krgeobuk-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
  else
    cat "$BACKUP_FILE" | docker exec -i krgeobuk-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
  fi

  if [ $? -eq 0 ]; then
    echo "✓ MySQL restore completed successfully!"
  else
    echo "✗ MySQL restore failed!"
    exit 1
  fi

# Redis 복구
elif [ "$TARGET_TYPE" == "redis" ]; then
  echo "Restoring Redis from $BACKUP_FILE..."

  # Redis 중지
  echo "Stopping Redis..."
  docker stop krgeobuk-redis

  # 압축 해제
  if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" > /tmp/dump.rdb
    RESTORE_FILE="/tmp/dump.rdb"
  else
    RESTORE_FILE="$BACKUP_FILE"
  fi

  # dump.rdb 복사
  docker cp "$RESTORE_FILE" krgeobuk-redis:/data/dump.rdb

  # Redis 시작
  echo "Starting Redis..."
  docker start krgeobuk-redis

  # 임시 파일 정리
  rm -f /tmp/dump.rdb

  if [ $? -eq 0 ]; then
    echo "✓ Redis restore completed successfully!"
  else
    echo "✗ Redis restore failed!"
    exit 1
  fi

else
  echo "✗ Error: Invalid target type: $TARGET_TYPE"
  echo "Valid types: mysql, redis"
  exit 1
fi

echo ""
echo "========================================="
echo "Restore completed!"
echo "========================================="
