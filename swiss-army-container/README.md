## Swiss Army Container

A compact image that bundles several utilities into a single container. The image is built on top of `linuxserver/docker-wireguard` and adds a handful of useful CLI tools so you can run them inside the WireGuard-enabled container.

Included tools (examples):

- WireGuard VPN (from base image)
- Bitwarden CLI wrapper (`bws`)
- `kubectl`
- Common utilities: `vim`, `ssh`, `curl`, `wget`, `git`, etc.

## Quick start

Copy-button-friendly single-line (useful for quick copy/paste):

```bash
docker run -d --rm --name wireguard --cap-add=NET_ADMIN --cap-add=SYS_MODULE -e BWS_ACCESS_TOKEN="" -e KUBECTL_SECRET_ID="" -e BWS_SECRET_IDS="" -e SSH_KONFIG_ID="" -v /lib/modules:/lib/modules --sysctl net.ipv4.conf.all.src_valid_mark=1 -v ~/.ssh/id_ed25519:/root/.ssh/id_ed25519 slickg/swiss-army-container && docker exec -it wireguard bash
```

You can paste the multi-line example into a script for readability or use the single-line for quick execution.

## Environment variables

- `BWS_ACCESS_TOKEN`: Bitwarden access token (Settings → API Key → Access Token).
  - Can be set in your shell and passed with `-e BWS_ACCESS_TOKEN`.

- `BWS_SECRET_IDS`: Comma-separated list of Bitwarden secret IDs for Wireguard peer configuration to fetch. You can find a secret's ID in the Bitwarden web vault URL or UI.

- `KUBECTL_SECRET_ID` : Kubectl config Secret ID. When provided, the container will fetch kube config and place it at /root/.kube/config.

- `SSH_KONFIG_ID`: Bitwarden secret ID containing your SSH config. When provided, the container will fetch the SSH config and place it at `/root/.ssh/config`.

All of these variables are optional, but the Bitwarden-related ones are required if you want the container to fetch secrets at startup.

## Runtime options & capabilities

- `--cap-add=NET_ADMIN`: required for WireGuard networking.
- `--cap-add=SYS_MODULE`: required for WireGuard module operations on some hosts.
- `-v /lib/modules:/lib/modules`: maps host kernel modules into the container (required for modprobe usage).
- `--sysctl net.ipv4.conf.all.src_valid_mark=1`: networking sysctl required for some routing setups.
- `-v ~/.ssh/id_ed25519:/root/.ssh/id_ed25519`: optional - mount your SSH private key to use SSH from inside the container.

## Notes

- The image is intended for convenience and testing; evaluate security implications before running in production. Be careful when mounting host keys or exposing tokens to containers.
- If you want this image to run non-root or with different user mappings, adjust the docker flags accordingly.


## Examples configurations in Bitwarden Secrets Manager
- Wireguard Config:
```json
{
  "id": "*redacted*",
  "organizationId": "*redacted*",
  "projectId": "*redacted",
  "key": "NAME_OF_THE_SECRET",
  "value": "[Interface]\nPrivateKey = *redacted*\nAddress = 10.0.0.6/32\nMTU = 1420\nDNS = 10.10.10.1\n \n[Peer]\nPublicKey = *redacted*\nAllowedIPs = 0.0.0.0/0\nEndpoint = ip.of.the.server:port\nPersistentKeepalive = 21",
  "note": "",
  "creationDate": "2025-09-17T17:32:42.409469Z",
  "revisionDate": "2025-10-03T13:34:00.065822900Z"
}
```

- kubectl config:
```json
{
  "id": "*redacted*",
  "organizationId": "*redacted*",
  "projectId": "*redacted*",
  "key": "KUBERNETES_CONFIG",
  "value": "apiVersion: v1\nkind: Config\nclusters:\n- name: example-cluster\n  cluster:\n    server: https://KUBE_API_SERVER:6443\n    # Either provide base64 CA data or mount a CA file and reference path\n    certificate-authority-data: REDACTED_BASE64_CA_DATA\ncontexts:\n- name: example-context\n  context:\n    cluster: example-cluster\n    user: example-user\ncurrent-context: example-context\nusers:\n- name: example-user\n  user:\n    # Prefer short-lived tokens or exec-based auth; bearer token shown as example\n    token: YOUR_BEARER_TOKEN\npreferences: {}",
  "note": "Kube Cluster Config",
  "creationDate": "2025-10-01T06:57:36.378954400Z",
  "revisionDate": "2025-10-01T06:57:36.378954400Z"
}
```

- SSH config:
```json
{
  "id": "*redacted*",
  "organizationId": "*redacted*",
  "projectId": "*redacted*",
  "key": "SSH_CONFIG",
  "value": "Host bastion\n  HostName bastion.example.com\n  User jumpuser\n  IdentityFile ~/.ssh/id_ed25519\n\nHost internal\n  HostName internal.example.local\n  User ubuntu\n  IdentityFile ~/.ssh/id_ed25519\n  ProxyJump bastion",
  "note": "Kube Cluster Config",
  "creationDate": "2025-10-01T06:57:36.378954400Z",
  "revisionDate": "2025-10-01T06:57:36.378954400Z"
}
```