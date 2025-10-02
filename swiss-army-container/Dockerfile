# syntax=docker/dockerfile:1

FROM lscr.io/linuxserver/wireguard:${WIREGUARD_VERSION:-latest}

RUN \
  apk add --no-cache \
    curl \
    openssh-client \
    jq && \
  rm -rf \
    /tmp/*
RUN \
    sed -i '/mkdir -p \/config\/wg_confs/c\
    mkdir -p /config/wg_confs\
    \
    IFS='"'"','"'"' read -ra SECRET_IDS <<<"${WIREGUARD_SECRET_IDS}"\
    for i in "${SECRET_IDS[@]}"; do\
        SECRET_ID=$(echo "$i" | xargs) # Trim whitespace\
        config_filename=$(bws secret get "$SECRET_ID" | jq -r .key)\
        config_content=$(bws secret get "$SECRET_ID" | jq -r .value)\
        echo "$config_content" >/config/wg_confs/"$config_filename".conf\
        echo "Created Wireguard Config for $config_filename"\
    done\7z
    if [[ -n "$KUBECTL_SECRET_ID" ]]; then\
        kubectl_config_cluster_name=$(bws secret get "$KUBECTL_SECRET_ID" | jq -r .key)\
        kubectl_config=$(bws secret get "$KUBECTL_SECRET_ID" | jq -r .value)\
        mkdir /root/.kube\
        echo "$kubectl_config" > /root/.kube/config\
        echo "Created Kubectl Config for $kubectl_config_cluster_name"\
    fi\
    ' /etc/s6-overlay/s6-rc.d/init-wireguard-confs/run

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