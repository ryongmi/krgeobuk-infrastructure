FROM jenkins/jenkins:lts

# root 사용자로 전환
USER root

# kubectl 설치
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Docker CLI 설치
RUN curl -fsSL https://get.docker.com | sh

# Node.js 및 npm 설치 (빌드용)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Git 설치
RUN apt-get update && apt-get install -y git

# jenkins 사용자를 docker 그룹에 추가
RUN usermod -aG docker jenkins

# 권한 설정
RUN chown -R jenkins:jenkins /var/jenkins_home

# jenkins 사용자로 복귀
USER jenkins

# 기본 플러그인 설치 (선택사항)
# RUN jenkins-plugin-cli --plugins "git github docker-workflow kubernetes-cli"
