# krgeobuk-infrastructure

krgeobuk 프로젝트의 기반 인프라 환경 리포지토리입니다.

## 📌 리포지토리 역할

이 리포지토리는 **애플리케이션 실행에 필요한 기반 인프라**를 제공합니다:

- ✅ MySQL 데이터베이스 (dev, prod 환경)
- ✅ Redis 캐시 서버
- ✅ Jenkins CI/CD 서버
- ✅ Verdaccio 프라이빗 NPM 레지스트리
- ✅ 백업/복구 스크립트

## 🔗 다른 리포지토리와의 관계

```
krgeobuk-infrastructure     krgeobuk-k8s              krgeobuk-deployment
(인프라 환경)               (K8s 리소스)              (배포 오케스트레이션)
        │                         │                           │
        ▼                         ▼                           ▼
   MySQL, Redis          외부 인프라 연결               배포 프로세스
   Jenkins, NPM          (ExternalName)                Jenkins 활용
```

**관계**:
- **krgeobuk-infrastructure** (이 리포지토리): 기반 인프라 제공
- **krgeobuk-k8s**: ExternalName Service로 이 인프라에 연결
- **krgeobuk-deployment**: Jenkins를 사용한 CI/CD 파이프라인 실행

## 🎯 제공하는 서비스

| 서비스 | 포트 | 용도 | 환경 |
|--------|------|------|------|
| **MySQL** | 3306 | 데이터베이스 | dev, prod |
| **Redis** | 6379 | 캐시/세션 | dev, prod |
| **Jenkins** | 9090 | CI/CD | 공통 |
| **Verdaccio** | 4873 | NPM 레지스트리 | 공통 |

## 구조

```
krgeobuk-infrastructure/
├── docker-compose/
│   ├── docker-compose.yaml        # 메인 Compose 파일
│   ├── mysql/                     # MySQL 설정
│   │   ├── init/                  # 초기화 SQL 스크립트
│   │   ├── conf/                  # MySQL 설정 파일
│   │   └── data/                  # 데이터 볼륨 (git 제외)
│   ├── redis/                     # Redis 설정
│   ├── jenkins/                   # Jenkins 설정
│   └── verdaccio/                 # Verdaccio 설정
├── backup/                        # 백업 스크립트
├── scripts/                       # 유틸리티 스크립트
└── docs/                          # 문서
```

## 시작하기

### 1. 환경 변수 설정

```bash
cp .env.example .env
# .env 파일을 열어 필요한 값 수정
```

**필수 설정 항목**:
```bash
# 비밀번호 (필수)
MYSQL_ROOT_PASSWORD=강력한_비밀번호
MYSQL_USER_PASSWORD=강력한_비밀번호    # 사용자 'geobuk' 비밀번호
REDIS_PASSWORD=강력한_비밀번호

# 포트 (선택, 기본값 사용 가능)
MYSQL_PORT=3306
REDIS_PORT=6379
JENKINS_HTTP_PORT=9090      # 포트 충돌 시 변경
JENKINS_AGENT_PORT=50001    # 포트 충돌 시 변경
VERDACCIO_PORT=4873
```

### 2. 서비스 시작

```bash
cd docker-compose/
docker-compose up -d
```

### 3. 서비스 확인

```bash
# 모든 컨테이너 상태 확인
docker-compose ps

# MySQL 접속 확인
docker exec -it krgeobuk-mysql mysql -u root -p

# Redis 접속 확인
docker exec -it krgeobuk-redis redis-cli -a <REDIS_PASSWORD>
```

## 서비스 정보

### MySQL
- **외부 포트**: `${MYSQL_PORT:-3306}` (환경 변수로 변경 가능)
- **내부 포트**: 3306
- **데이터베이스**:
  - `auth_dev` (개발 환경)
  - `auth_prod` (운영 환경)
- **애플리케이션 사용자**: `geobuk`
- **root 사용자**: `root` (관리 전용)

### Redis
- **외부 포트**: `${REDIS_PORT:-6379}` (환경 변수로 변경 가능)
- **내부 포트**: 6379
- **DB 번호**:
  - `0`: auth-dev
  - `1`: auth-prod

### Jenkins
- **HTTP 포트**: `${JENKINS_HTTP_PORT:-9090}` (기본값: 9090)
- **Agent 포트**: `${JENKINS_AGENT_PORT:-50001}` (기본값: 50001)
- **볼륨**: `./jenkins/data`
- **접속**: `http://localhost:9090`

### Verdaccio
- **외부 포트**: `${VERDACCIO_PORT:-4873}` (환경 변수로 변경 가능)
- **내부 포트**: 4873
- **설정**: `./verdaccio/config`
- **접속**: `http://localhost:4873`

## 백업

백업 스크립트는 `backup/` 디렉토리에 있습니다:

```bash
# MySQL 백업
./backup/mysql-backup.sh

# Redis 백업
./backup/redis-backup.sh

# 복구
./backup/restore.sh <backup_file> <mysql|redis>
```

## 문제 해결

### 포트 충돌 해결

**증상**: "Bind for 0.0.0.0:9090 failed: port is already allocated"

**원인**: 해당 포트가 이미 다른 프로세스에서 사용 중

**해결 방법**:

```bash
# 1. 사용 중인 포트 확인 (Windows)
netstat -ano | findstr :9090

# 2. .env 파일에서 포트 변경
JENKINS_HTTP_PORT=9091      # 9090 → 9091로 변경
JENKINS_AGENT_PORT=50002    # 50001 → 50002로 변경

# 3. 컨테이너 재시작
docker-compose down
docker-compose up -d
```

**포트 변경 예시**:
```bash
# .env 파일
MYSQL_PORT=3307           # 3306이 사용 중이면
REDIS_PORT=6380           # 6379가 사용 중이면
JENKINS_HTTP_PORT=9091    # 9090이 사용 중이면
```

### 컨테이너 로그 확인
```bash
docker-compose logs -f [service_name]
```

### 컨테이너 재시작
```bash
docker-compose restart [service_name]
```

### 모든 서비스 중지 및 제거
```bash
docker-compose down
```

## 🔒 보안 주의사항

### 중요: 비밀번호 관리

**절대로 Git에 커밋하지 마세요**:
- ✅ `.env.example` - 템플릿만 (기본값 또는 플레이스홀더)
- ❌ `.env` - 실제 비밀번호 포함 (.gitignore에 포함됨)
- ❌ `docker-compose/*/data/` - 데이터베이스 파일
- ❌ `backup/*.sql.gz` - 백업 파일

### 환경 변수 보안

**`.env` 파일 설정 예시**:
```bash
# 강력한 비밀번호 사용 (최소 16자, 영문+숫자+특수문자)
MYSQL_ROOT_PASSWORD=MyStr0ng!R00tP@ssw0rd2024
MYSQL_USER_PASSWORD=Ge0buk$erv1ceP@ss!2024    # 'geobuk' 사용자
REDIS_PASSWORD=Red1sS3cur3P@ssw0rd!2024
```

**비밀번호 생성 방법**:
```bash
# OpenSSL로 랜덤 비밀번호 생성
openssl rand -base64 32

# 또는 pwgen (설치 필요)
pwgen -s 32 1
```

### MySQL 사용자 생성 방식

**보안 개선 (환경 변수 사용)**:
- ✅ `02-create-users.sh` - 환경 변수에서 비밀번호 로드
- ❌ ~~`02-create-users.sql`~~ - 평문 비밀번호 노출 (삭제됨)

**동작 방식**:
1. `.env` 파일에 `MYSQL_USER_PASSWORD` 설정
2. `docker-compose.yaml`에서 환경 변수로 전달
3. `02-create-users.sh` 스크립트가 환경 변수 읽어서 'geobuk' 사용자 생성

### 프로덕션 체크리스트

배포 전 반드시 확인:
- [ ] `.env` 파일의 모든 비밀번호 변경
- [ ] 비밀번호 강도 확인 (16자 이상, 복잡도 높음)
- [ ] `.gitignore`에 `.env` 포함 확인
- [ ] Git 히스토리에 비밀번호 노출 여부 확인
- [ ] 백업 파일 암호화 고려

## 참고

- 데이터 파일 (`docker-compose/*/data/`)은 Git에서 제외됩니다.
- 프로덕션 환경에서는 `.env` 파일의 비밀번호를 반드시 변경하세요.
- 정기적인 백업을 권장합니다.
- **보안 사고 발생 시**: 즉시 모든 비밀번호 변경 및 데이터베이스 접근 로그 확인
