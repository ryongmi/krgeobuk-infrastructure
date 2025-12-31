# Kubernetes Dashboard

Kubernetes 클러스터를 웹 브라우저에서 관리할 수 있는 공식 대시보드입니다.

## 목차

- [설치](#설치)
- [접속 방법](#접속-방법)
- [토큰 재생성](#토큰-재생성)
- [제거](#제거)
- [트러블슈팅](#트러블슈팅)

## 설치

### 자동 설치 (권장)

```bash
cd krgeobuk-k8s/infrastructure/dashboard
chmod +x install.sh
./install.sh
```

설치 스크립트는 다음 작업을 수행합니다:
1. Kubernetes Dashboard v2.7.0 설치
2. Dashboard Pod 준비 대기
3. 관리자 계정 생성
4. 로그인 토큰 생성 및 출력

### 수동 설치

```bash
# 1. Dashboard 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 2. 관리자 계정 생성
kubectl apply -f admin-user.yaml

# 3. 토큰 생성
kubectl -n kubernetes-dashboard create token admin-user
```

## 접속 방법

### 방법 1: Ingress 사용 (권장 - 간단한 URL)

설치 스크립트를 실행하면 자동으로 Ingress가 생성됩니다.

```bash
# 브라우저에서 바로 접속
http://dashboard.192.168.0.28.nip.io

# 토큰 생성
./get-token.sh
```

**장점**:
- ✅ 간단한 URL
- ✅ kubectl proxy 불필요
- ✅ 다른 서비스와 동일한 접속 방식

### 방법 2: kubectl proxy 사용 (로컬 접속)

```bash
# 1. 프록시 실행
kubectl proxy

# 2. 브라우저에서 접속
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# 3. 토큰으로 로그인
./get-token.sh  # 토큰 생성
```

### 원격 접속 (메인PC에서)

#### Ingress 사용 (가장 간단)

Ingress를 사용하면 메인PC에서도 동일한 URL로 접속 가능합니다:

```bash
# 메인PC 브라우저에서 바로 접속
http://dashboard.192.168.0.28.nip.io
```

**외부 접속** (외부 IP가 있는 경우):
```bash
# 공유기 포트포워딩 설정 후
http://dashboard.외부IP.nip.io
```

#### SSH 터널링 (kubectl proxy 사용 시)

kubectl proxy를 사용하는 경우에만 필요:

```bash
# 메인PC 터미널에서 실행
ssh -L 8001:localhost:8001 geobuk@192.168.0.28

# 미니PC에서 프록시 실행
kubectl proxy

# 메인PC 브라우저에서 접속
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## 토큰 재생성

로그인 토큰은 일정 시간 후 만료됩니다. 새 토큰을 생성하려면:

```bash
./get-token.sh
```

또는 직접 생성:

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

## 제거

```bash
./uninstall.sh
```

수동 제거:

```bash
# 1. 관리자 계정 삭제
kubectl delete -f admin-user.yaml

# 2. Dashboard 삭제
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

## 트러블슈팅

### Dashboard Pod가 시작되지 않음

```bash
# Pod 상태 확인
kubectl get pods -n kubernetes-dashboard

# Pod 로그 확인
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard

# Pod 상세 정보
kubectl describe pod -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
```

### 토큰 생성 실패

```bash
# ServiceAccount 확인
kubectl get sa admin-user -n kubernetes-dashboard

# ClusterRoleBinding 확인
kubectl get clusterrolebinding admin-user

# 재생성
kubectl delete -f admin-user.yaml
kubectl apply -f admin-user.yaml
```

### 접속 시 404 에러

프록시가 제대로 실행되고 있는지 확인:

```bash
# 프록시 프로세스 확인
ps aux | grep "kubectl proxy"

# 프록시 재시작
pkill -f "kubectl proxy"
kubectl proxy
```

### 토큰 입력 후 접속 안 됨

권한 확인:

```bash
# ClusterRoleBinding 확인
kubectl describe clusterrolebinding admin-user

# 관리자 권한이 없으면 재생성
kubectl delete clusterrolebinding admin-user
kubectl apply -f admin-user.yaml
```

## 주요 기능

Dashboard를 통해 다음 작업을 수행할 수 있습니다:

- **리소스 모니터링**: Pod, Service, Deployment 등 모든 리소스 상태 확인
- **로그 확인**: 컨테이너 로그 실시간 조회
- **리소스 관리**: YAML 편집, 삭제, 생성
- **스케일링**: Deployment/StatefulSet 복제본 수 조정
- **Shell 접속**: Pod 내부 터미널 접속
- **이벤트 모니터링**: 클러스터 이벤트 확인

## 보안 권장사항

### 프로덕션 환경

프로덕션 환경에서는 다음 보안 조치를 권장합니다:

1. **RBAC 세밀화**: `cluster-admin` 대신 제한된 권한 사용
2. **Ingress + TLS**: HTTPS로 접속하도록 설정
3. **IP 화이트리스트**: 특정 IP만 접속 허용
4. **토큰 만료 시간 단축**: 보안 강화
5. **감사 로그 활성화**: 접속 기록 모니터링

### RBAC 예시 (읽기 전용)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # cluster-admin 대신 view 사용
subjects:
- kind: ServiceAccount
  name: dashboard-viewer
  namespace: kubernetes-dashboard
```

## 참고 자료

- [Kubernetes Dashboard 공식 문서](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- [Dashboard GitHub](https://github.com/kubernetes/dashboard)
- [RBAC 설정 가이드](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
