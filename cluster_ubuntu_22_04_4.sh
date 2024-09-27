#!/bin/bash

# cluster initialization script

# 현재 사용자 확인 및 root가 아니면 스크립트를 root로 다시 실행
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run as root. Attempting to rerun as root..."
    exec sudo "$0" "$@"  # 현재 스크립트를 sudo로 다시 실행
fi

initialize_cluster() {
  echo "Kubernetes 클러스터를 초기화 합니다. 초기화 후 출력되는 명령어를 워커노드에서 실행하세요."
  sudo kubeadm init --pod-network-cidr=172.16.0.0/16
}

initialize_cluster