#!/bin/bash

# k8s install script

# 현재 사용자 확인 및 root가 아니면 스크립트를 root로 다시 실행
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run as root. Attempting to rerun as root..."
    exec sudo "$0" "$@"  # 현재 스크립트를 sudo로 다시 실행
fi

# 로딩 스피너 출력 함수
# 매개변수:
#   pid: 프로세스의 PID (Process ID)로, 이 PID에 대해 스피너를 표시합니다.
show_spinner() {
    local pid=$1
    local spinner=('|' '/' '-' '\\')
    local spin_index=0

    while ps -p $pid > /dev/null; do
        printf "\rInstalling... ${spinner[spin_index]}"
        spin_index=$(( (spin_index + 1) % ${#spinner[@]} ))
        sleep 0.1
    done
    printf "\rInstalling... done!      \n"
}

# Docker 설치 확인 및 설치
install_docker() {
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
    else
        echo "Installing Docker..."
        (
            # Docker의 공식 GPG 키 추가
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Apt 소스에 리포지토리 추가
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # 패키지 목록 업데이트
            sudo apt-get update

            # Docker 설치
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # 현재 사용자에게 Docker 그룹 권한 추가
            sudo usermod -aG docker $USER
            sudo chmod 666 /var/run/docker.sock
        ) &  # 백그라운드에서 실행
        local pid=$!  # 백그라운드 작업의 PID 저장
        show_spinner "$pid"  # 스피너 표시
        wait $pid  # Docker 설치 완료 대기
        echo "Docker installed."
    fi
}

# 시스템 설정 업데이트
update_system_configuration() {
  mkdir -p /etc/containerd
  CONFIG_FILE="/etc/containerd/config.toml"

  echo "$CONFIG_FILE 파일의 설정을 수정합니다."
  if [ -f "$CONFIG_FILE" ]; then
      cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
      (
        sudo containerd config default | tee "$CONFIG_FILE"
        sudo sed -i '/^\s*disabled_plugins/ s/^/#/' "$CONFIG_FILE"
        sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' "$CONFIG_FILE"
        sudo systemctl restart containerd
      ) &
  else
      echo "$CONFIG_FILE 파일이 존재하지 않습니다."
  fi

  echo "containerd 데몬을 재시작 합니다."
  sudo systemctl restart containerd

  echo "스왑 공간을 비활성화하고, socat을 설치합니다."
  (
    sudo swapoff -a
    sudo sed -i '/swap/s/^/#/' /etc/fstab
    sudo apt-get install socat &
  ) &

  echo "ip_forward를 활성화합니다."
  (
    sudo sysctl -w net.ipv4.ip_forward=1
  ) &

  SYSCTL_CONF="/etc/sysctl.conf"

  if grep -q "^net.ipv4.ip_forward=1" "$SYSCTL_CONF"; then
      echo "IP forwarding 설정이 이미 존재합니다."
  else
      echo "IP forwarding 설정을 추가합니다."
      echo "net.ipv4.ip_forward=1" | sudo tee -a "$SYSCTL_CONF"
  fi

  echo "모든 방화벽을 해제합니다."
  (
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
    sudo systemctl stop NetworkManager
    sudo systemctl disable NetworkManager
    sudo ufw disable
  ) &

}

# Kubernetes 설치 확인 및 설치
install_kubernetes() {
    if command -v kubectl &> /dev/null; then
        echo "Kubernetes (kubectl) is already installed."
    else
        echo "Installing Kubernetes..."
        (
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gpg
            curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
            echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
            sudo apt-get update
            sudo apt-get install -y kubelet kubeadm kubectl
            sudo apt-mark hold kubelet kubeadm kubectl
            sudo systemctl enable --now kubelet
        ) &  # Kubernetes 설치 명령어를 백그라운드에서 실행
        local pid=$!  # 백그라운드 작업의 PID 저장
        show_spinner "$pid"  # 스피너 표시
        wait $pid  # Kubernetes 설치 완료 대기
        echo "Kubernetes installed."
    fi
}

# 메인 스크립트 실행
install_docker
update_system_configuration
install_kubernetes