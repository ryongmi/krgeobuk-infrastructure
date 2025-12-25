-- krgeobuk MySQL 데이터베이스 초기화 스크립트
-- auth-server용 데이터베이스 생성

-- 개발 환경 데이터베이스
CREATE DATABASE IF NOT EXISTS auth_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 운영 환경 데이터베이스
-- CREATE DATABASE IF NOT EXISTS auth_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 데이터베이스 목록 확인
SHOW DATABASES;
