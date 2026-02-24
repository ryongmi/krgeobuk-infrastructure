# krgeobuk-infrastructure

krgeobuk 프로젝트의 기반 인프라 환경을 관리하는 리포지토리입니다.

## 역할

- MySQL 데이터베이스 (Docker Compose)
- Redis 캐시 서버 (Docker Compose)
- 백업/복구 스크립트
- Kubernetes Dashboard 매니페스트

> Jenkins와 Verdaccio는 K8s로 이관되었습니다.
> → `krgeobuk-deployment/jenkins/k8s/`, `krgeobuk-deployment/verdaccio/k8s/`

## 다른 리포지토리와의 관계

```
krgeobuk-infrastructure       krgeobuk-k8s
(이 리포지토리)               (애플리케이션 K8s 매니페스트)
        │                             │
        ▼                             ▼
  MySQL, Redis                ExternalName Service로
  (Docker Compose)            MySQL, Redis에 연결
```

- **krgeobuk-k8s**: 각 서비스의 K8s 매니페스트에서 `ExternalName` Service로 이 리포지토리의 MySQL, Redis에 접근

---

## 구조

```
krgeobuk-infrastructure/
│
├── docker-compose/
│   ├── docker-compose.yaml         # MySQL, Redis Compose 파일
│   ├── mysql/
│   │   ├── init/                   # 초기화 스크립트 (DB, 사용자 자동 생성)
│   │   │   ├── 01-create-databases.sql
│   │   │   └── 02-create-users.sh
│   │   ├── conf/my.cnf             # MySQL 설정
│   │   └── data/                   # 데이터 볼륨 (git 제외)
│   └── redis/
│       ├── redis.conf              # Redis 설정
│       └── data/                   # 데이터 볼륨 (git 제외)
│
├── backup/                         # 백업/복구 스크립트
│   ├── mysql-backup.sh
│   ├── redis-backup.sh
│   ├── restore.sh
│   └── backup-cron                 # cron 등록용 설정
│
├── scripts/                        # 유틸리티 스크립트
│   ├── start-all.sh                # 전체 서비스 시작
│   ├── stop-all.sh                 # 전체 서비스 중지
│   ├── health-check.sh             # 서비스 상태 확인
│   └── init-databases.sh           # DB 수동 초기화
│
├── k8s/
│   └── dashboard/                  # Kubernetes Dashboard 매니페스트
│       ├── admin-user.yaml         # 관리자 ServiceAccount
│       ├── ingress.yaml            # Dashboard Ingress
│       ├── install.sh              # 설치 스크립트
│       ├── uninstall.sh            # 제거 스크립트
│       └── get-token.sh            # 로그인 토큰 생성
│
└── .env.example                    # 환경 변수 템플릿
```

---

## 시작하기

### 1. 환경 변수 설정

`.env` 파일은 `docker-compose/` 디렉토리에 위치해야 합니다.

```bash
cd docker-compose/
cp ../.env.example .env
vi .env   # 비밀번호 등 실제 값 입력
```

필수 설정 항목:

| 변수 | 설명 |
|---|---|
| `MYSQL_ROOT_PASSWORD` | MySQL root 비밀번호 |
| `MYSQL_DEV_USER_PASSWORD` | dev_user 비밀번호 (개발 DB 접근) |
| `REDIS_PASSWORD` | Redis 비밀번호 |
| `MYSQL_PORT` | MySQL 외부 포트 (기본값: 3306) |
| `REDIS_PORT` | Redis 외부 포트 (기본값: 6379) |

> 포트는 `0.0.0.0`으로 바인딩되어 모든 인터페이스에서 접근 가능합니다.
> K8s 파드가 호스트 IP를 통해 MySQL, Redis에 접근하기 위해 필요한 설정입니다.

### 2. 서비스 시작

```bash
cd docker-compose/
docker compose up -d
```

또는 유틸리티 스크립트 사용:

```bash
./scripts/start-all.sh
```

### 3. 서비스 확인

```bash
# 컨테이너 상태 확인
docker compose -f docker-compose/docker-compose.yaml ps

# MySQL 접속 확인
docker exec krgeobuk-mysql mysql -u root -p -e "SHOW DATABASES;"

# Redis 접속 확인
docker exec krgeobuk-redis redis-cli -a YOUR_PASSWORD PING

# 전체 헬스체크
./scripts/health-check.sh
```

### 4. 생성되는 데이터베이스

초기화 스크립트(`mysql/init/`)에 의해 자동 생성됩니다.

**개발 환경:**

| 데이터베이스 | 용도 |
|---|---|
| `auth_dev` | auth-server |
| `authz_dev` | authz-server |
| `portal_dev` | portal-server |
| `mypick_dev` | my-pick-server |

**운영 환경** (`.env`에서 `MYSQL_PROD_USER_PASSWORD` 활성화 시):

| 데이터베이스 | 용도 |
|---|---|
| `auth_prod` | auth-server |
| `authz_prod` | authz-server |
| `portal_prod` | portal-server |
| `mypick_prod` | my-pick-server |

**사용자 권한:**
- `dev_user`: 모든 `*_dev` DB 접근
- `geobuk`: 모든 `*_prod` DB 접근 (운영 환경)

---

## 서비스 정보

### MySQL

- **이미지**: `mysql:8.0`
- **외부 포트**: `${MYSQL_PORT:-3306}` → `0.0.0.0` 바인딩 (K8s 파드 접근용)
- **문자셋**: `utf8mb4` / `utf8mb4_unicode_ci`
- **설정 파일**: `docker-compose/mysql/conf/my.cnf`

### Redis

- **이미지**: `redis:7-alpine`
- **외부 포트**: `${REDIS_PORT:-6379}` → `0.0.0.0` 바인딩 (K8s 파드 접근용)
- **설정 파일**: `docker-compose/redis/redis.conf`
- **인증**: `requirepass` 적용

---

## 백업

### MySQL 백업

```bash
./backup/mysql-backup.sh
```

백업 파일은 기본적으로 `/opt/krgeobuk/backups/mysql`에 저장됩니다.
경로를 변경하려면 `.env`에서 설정합니다:

```bash
MYSQL_BACKUP_DIR=/path/to/backup
```

### Redis 백업

```bash
./backup/redis-backup.sh
```

### 복구

```bash
./backup/restore.sh <backup_file> <mysql|redis>
```

### cron 등록 (자동 백업)

```bash
# backup/backup-cron 내용 참고
crontab -e
# 예: 매일 새벽 2시 MySQL 백업
# 0 2 * * * /path/to/backup/mysql-backup.sh
```

---

## Kubernetes Dashboard

k3s 클러스터를 웹 UI로 관리할 수 있는 Kubernetes Dashboard입니다.

### 설치

```bash
cd k8s/dashboard/
chmod +x install.sh
./install.sh
```

설치 후 로그인 토큰 생성:

```bash
./get-token.sh
```

### 접속

| 방법 | URL |
|---|---|
| Ingress (로컬) | `http://dashboard.192.168.0.28.nip.io` |
| kubectl proxy | `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/` |

상세 내용은 [k8s/dashboard/README.md](./k8s/dashboard/README.md)를 참조하세요.

### 제거

```bash
./k8s/dashboard/uninstall.sh
```

---

## 문제 해결

### 포트 충돌

```bash
# 사용 중인 포트 확인 (Linux)
ss -tlnp | grep 3306

# .env에서 포트 변경 후 재시작
MYSQL_PORT=3307
docker compose -f docker-compose/docker-compose.yaml down
docker compose -f docker-compose/docker-compose.yaml up -d
```

### 컨테이너 로그 확인

```bash
docker compose -f docker-compose/docker-compose.yaml logs -f krgeobuk-mysql
docker compose -f docker-compose/docker-compose.yaml logs -f krgeobuk-redis
```

### 컨테이너 재시작

```bash
docker compose -f docker-compose/docker-compose.yaml restart krgeobuk-mysql
```

---

## 보안 주의사항

Git에 절대 커밋하지 않는 파일:

| 파일 | 이유 |
|---|---|
| `docker-compose/.env` | 실제 비밀번호 포함 |
| `docker-compose/*/data/` | 데이터베이스 파일 |
| `backup/*.sql.gz` | 백업 파일 |

비밀번호 생성:

```bash
# OpenSSL로 랜덤 비밀번호 생성
openssl rand -base64 32
```
