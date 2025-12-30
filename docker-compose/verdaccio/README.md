# Verdaccio 운영 가이드

## 개요

이 문서는 Verdaccio 프라이빗 NPM 레지스트리의 사용자 관리 방법을 설명합니다.
bcrypt 알고리즘을 사용하여 안전하게 사용자 인증 정보를 관리합니다.

## 사전 요구사항

### htpasswd 설치

Ubuntu/Debian:
```bash
sudo apt-get install -y apache2-utils
```

macOS:
```bash
brew install httpd
```

Windows (WSL 사용 권장):
```bash
sudo apt-get install -y apache2-utils
```

## 사용자 관리 명령어

### 1. 첫 사용자 생성 (파일 생성)

```bash
# -c: 새 파일 생성
# -B: bcrypt 알고리즘 사용
# -C 10: cost factor (Verdaccio 기본값)
htpasswd -c -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd krgeobuk
```

실행 후 비밀번호 입력 프롬프트가 나타납니다.

**파일 확인:**
```bash
cat krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd
```

**권한 설정:**
```bash
chmod 644 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd
```

**Verdaccio 재시작:**
```bash
docker restart verdaccio
```

### 2. 추가 사용자 등록 (기존 파일에 추가)

```bash
# -c 플래그 없이 실행 (기존 파일에 추가)
htpasswd -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd developer1
htpasswd -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd developer2
```

**파일 확인 (여러 사용자가 있어야 함):**
```bash
cat krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd

# 예시 출력:
# krgeobuk:$2y$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# developer1:$2y$10$yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
# developer2:$2y$10$zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz
```

**Verdaccio 재시작:**
```bash
docker restart verdaccio
```

### 3. 사용자 비밀번호 변경

```bash
# 기존 사용자명으로 다시 실행하면 비밀번호 업데이트됨
htpasswd -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd krgeobuk
```

**Verdaccio 재시작:**
```bash
docker restart verdaccio
```

### 4. 사용자 삭제

```bash
# -D: delete
htpasswd -D krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd developer1
```

**Verdaccio 재시작:**
```bash
docker restart verdaccio
```

### 5. 사용자 목록 확인

```bash
cut -d: -f1 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd

# 출력 예시:
# krgeobuk
# developer1
# developer2
```

## 운영 환경 워크플로우

### 새 개발자 계정 추가 프로세스

```bash
# 1. 새 개발자 계정 추가
htpasswd -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd jane

# 2. Verdaccio 재시작 (변경사항 반영)
docker restart verdaccio

# 3. 새 개발자에게 로그인 정보 전달
# Username: jane
# Password: (설정한 비밀번호)
# Registry: http://localhost:4873 (또는 실제 서버 주소)
```

### 개발자 측 설정

```bash
# NPM 레지스트리에 로그인
npm login --registry http://localhost:4873

# 로그인 정보 입력
# Username: jane
# Password: (전달받은 비밀번호)
# Email: jane@example.com
```

## 주의사항

### ⚠️ 절대 하지 말 것

**기존 파일이 있는데 -c 플래그 사용:**
```bash
# ❌ 잘못된 예 - 기존 파일을 덮어씀!
htpasswd -c -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd newuser
# 이렇게 하면 krgeobuk 사용자가 사라지고 newuser만 남음!

# ✅ 올바른 예 - 기존 파일에 추가
htpasswd -B -C 10 krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd newuser
```

### 보안 권장사항

1. **강력한 비밀번호 사용**: 최소 12자 이상, 대소문자, 숫자, 특수문자 포함
2. **정기적인 비밀번호 변경**: 3-6개월마다 비밀번호 변경 권장
3. **파일 권한 관리**: htpasswd 파일은 644 권한 유지
4. **백업**: htpasswd 파일을 안전한 곳에 백업 (암호화 권장)

### 변경 후 필수 작업

모든 사용자 관리 작업 후 **반드시 Verdaccio를 재시작**해야 변경사항이 반영됩니다:
```bash
docker restart verdaccio
```

## 트러블슈팅

### 로그인 실패 시

1. **htpasswd 파일 권한 확인:**
   ```bash
   ls -l krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd
   # 출력: -rw-r--r-- ... htpasswd
   ```

2. **Verdaccio 로그 확인:**
   ```bash
   docker logs verdaccio
   ```

3. **사용자 존재 여부 확인:**
   ```bash
   grep "^username:" krgeobuk-infrastructure/docker-compose/verdaccio/config/htpasswd
   ```

### htpasswd 명령어가 없을 때

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y apache2-utils

# macOS
brew install httpd

# Alpine Linux (Docker 컨테이너 내부)
apk add apache2-utils
```

## 참고 자료

- [Verdaccio 공식 문서](https://verdaccio.org/docs/what-is-verdaccio)
- [htpasswd 사용법](https://httpd.apache.org/docs/current/programs/htpasswd.html)
- [bcrypt 알고리즘](https://en.wikipedia.org/wiki/Bcrypt)

## 빠른 참조

### 명령어 요약

| 작업 | 명령어 |
|------|--------|
| 첫 사용자 생성 | `htpasswd -c -B -C 10 htpasswd username` |
| 사용자 추가 | `htpasswd -B -C 10 htpasswd username` |
| 비밀번호 변경 | `htpasswd -B -C 10 htpasswd username` |
| 사용자 삭제 | `htpasswd -D htpasswd username` |
| 사용자 목록 | `cut -d: -f1 htpasswd` |
| Verdaccio 재시작 | `docker restart verdaccio` |

### 플래그 설명

| 플래그 | 설명 |
|--------|------|
| `-c` | 새 파일 생성 (기존 파일 덮어씀 주의!) |
| `-B` | bcrypt 알고리즘 사용 |
| `-C 10` | bcrypt cost factor (기본값: 10) |
| `-D` | 사용자 삭제 |
