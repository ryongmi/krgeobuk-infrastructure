-- krgeobuk MySQL 데이터베이스 초기화 스크립트
-- 모든 마이크로서비스용 데이터베이스 생성

-- =============================================================================
-- 개발 환경 데이터베이스 (Development)
-- =============================================================================

-- auth-server용 데이터베이스
CREATE DATABASE IF NOT EXISTS auth_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- authz-server용 데이터베이스
CREATE DATABASE IF NOT EXISTS authz_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- portal-server용 데이터베이스
CREATE DATABASE IF NOT EXISTS portal_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- my-pick-server용 데이터베이스
CREATE DATABASE IF NOT EXISTS mypick_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =============================================================================
-- 운영 환경 데이터베이스 (Production)
-- 미니PC 배포 시 주석 해제하여 사용
-- =============================================================================

-- auth-server용 운영 데이터베이스
-- CREATE DATABASE IF NOT EXISTS auth_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- authz-server용 운영 데이터베이스
-- CREATE DATABASE IF NOT EXISTS authz_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- portal-server용 운영 데이터베이스
-- CREATE DATABASE IF NOT EXISTS portal_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- my-pick-server용 운영 데이터베이스
-- CREATE DATABASE IF NOT EXISTS mypick_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =============================================================================
-- 데이터베이스 목록 확인
-- =============================================================================
SHOW DATABASES;
