#!/bin/bash

# cni 설치 스크립트 (calico)

# 현재 사용자 확인 및 root가 아니면 스크립트를 root로 다시 실행
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run as root. Attempting to rerun as root..."
    exec sudo "$0" "$@"  # 현재 스크립트를 sudo로 다시 실행
fi

install_cni() {
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
}

install_cni