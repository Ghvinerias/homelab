# syntax=docker/dockerfile:1

FROM lscr.io/linuxserver/wireguard:${WIREGUARD_VERSION:-latest}

RUN \
  apk add --no-cache \
  curl \
  git \
  wget \
  openssh-client \
  ansible \
  sshpass \
  rsync \
  py3-passlib \
  jq && \
  rm -rf \
  /tmp/*
RUN \
  sed -i 's&mkdir -p /config/wg_confs&mkdir -p /config/wg_confs\n\nIFS='"'"','"'"' read -ra SECRET_IDS <<<\"${BWS_SECRET_IDS}\"\nfor i in \"${SECRET_IDS[@]}\"; do\n    SECRET_ID=$(echo \"$i\" | xargs) # Trim whitespace\n    config_filename=$(bws secret get \"$SECRET_ID\" | jq -r .key)\n    config_content=$(bws secret get \"$SECRET_ID\" | jq -r .value)\n    echo \"$config_content\" >/config/wg_confs/\"$config_filename\".conf\n    echo \"Created Wireguard Config for $config_filename\"\ndone\nif [[ -n \"$KUBECTL_SECRET_ID\" ]]; then\n    kubectl_config_cluster_name=$(bws secret get \"$KUBECTL_SECRET_ID\" | jq -r .key)\n    kubectl_config=$(bws secret get \"$KUBECTL_SECRET_ID\" | jq -r .value)\n    mkdir -p /root/.kube\n    echo \"$kubectl_config\" > /root/.kube/config\n    echo \"Created Kubectl Config for $kubectl_config_cluster_name\"\nfi\nif [[ -n \"$SSH_KONFIG_ID\" ]]; then\n    ssh_konfig_name=$(bws secret get \"$SSH_KONFIG_ID\" | jq -r .key)\n    ssh_konfig=$(bws secret get \"$SSH_KONFIG_ID\" | jq -r .value)\n    mkdir -p /root/.ssh\n    echo \"$ssh_konfig\" > /root/.ssh/config\n    echo \"Created SSH Config for $ssh_konfig_name\"\nfi&g' /etc/s6-overlay/s6-rc.d/init-wireguard-confs/run

# add bws executable and dependencies
COPY --from=bitwarden/bws /bin/bws /bin/bws
COPY --from=bitwarden/bws /etc/ssl/certs /etc/ssl/certs
COPY --from=bitwarden/bws /lib /lib
COPY --from=bitwarden/bws /lib64 /lib64

# Install kubectl
RUN ARCH=$(uname -m) && \
  case $ARCH in \
  x86_64) KUBECTL_ARCH=amd64 ;; \
  aarch64) KUBECTL_ARCH=arm64 ;; \
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
  esac && \
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" && \
  chmod +x kubectl && \
  mv kubectl /bin/kubectl

ENV PUID=1000
ENV GUID=1000
ENV TZ=Asia/Tbilisi
