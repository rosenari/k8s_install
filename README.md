# k8s shell script

##### k8s 설치 스크립트
```bash
wget https://raw.githubusercontent.com/rosenari/k8s_install/main/k8s_ubuntu_22_04_4.sh && chmod +x k8s_ubuntu_22_04_4.sh && ./k8s_ubuntu_22_04_4.sh
```
##### cluster 초기화 스크립트
```bash
wget https://raw.githubusercontent.com/rosenari/k8s_install/main/cluster_ubuntu_22_04_4.sh && chmod +x cluster_ubuntu_22_04_4.sh && ./cluster_ubuntu_22_04_4.sh
```
##### cni 설치 스크립트 (멀티 호스트에서 파드간 통신에 필요한 플러그인)
```bash
wget https://raw.githubusercontent.com/rosenari/k8s_install/main/cni_ubuntu_22_04_4.sh && chmod +x cni_ubuntu_22_04_4.sh && ./cni_ubuntu_22_04_4.sh
```