## Repo overview (big picture)

- This repository contains infrastructure and app artifacts for a personal homelab. Key areas:
  - `Ansible/` — primary place for host configuration, roles, and playbooks (see `Ansible/playbooks/site.yml`, `Ansible/deploy-alloy.yml`).
  - `GKE/` — Kubernetes manifests and examples (e.g. `GKE/free-boi/examples/`).
  - `media-automation/` — docker-compose workloads for media services (`docker-compose.yml`).
  - `swiss-army-container/` — convenience Docker image and runtime notes (see `Dockerfile`, README).
  - `hetzner/Ansible/` — provider-specific Ansible playbooks and third-party roles (geerlingguy.*).

Focus: when modifying code, consider whether changes are infrastructure (Ansible/Terraform/K8s), container images, or local automation scripts; each live in their own top-level folder.

## Developer workflows & key commands

- Ansible (main workflows):
  - Install roles: `ansible-galaxy install -r Ansible/requirements.yml`
  - Run main playbook: `ansible-playbook Ansible/playbooks/site.yml --ask-vault-pass`
  - Deploy Alloy: `ansible-playbook Ansible/playbooks/deploy-alloy.yml --ask-vault-pass`
  - Dry-run: append `--check` to any `ansible-playbook` command.
  - Config: `Ansible/ansible.cfg` sets `inventory = inventory.yml`, `roles_path = roles`, `vault_password_file = .vault_pass` and `stdout_callback = yaml`.

- Docker / compose:
  - Start media services: `docker compose -f media-automation/docker-compose.yml up -d`
  - Swiss-army-container quick-run example is in `swiss-army-container/README.md` (single-line `docker run ...` invocation).

- Kubernetes (GKE):
  - Manifests and examples are under `GKE/free-boi/` — apply with `kubectl apply -f <file>` against your kubecontext.

## Project-specific conventions and patterns

- Ansible inventory and secrets:
  - Inventory is YAML (`Ansible/inventory.yml`). Host capabilities are expressed as host vars (example: `has_docker: true`, `has_nginx: false`) — playbooks/roles read those to conditionally assemble configs (see `roles/alloy_config/`).
  - Vault usage is expected: either `--ask-vault-pass` or `.vault_pass` (but `.vault_pass` should be gitignored).

- Role/layout:
  - Custom roles live in `Ansible/roles/` and follow Ansible role structure (tasks/handlers/templates/vars). When adding roles, register them in `requirements.yml` and document any host variables needed.

- Secrets & external integrations:
  - Bitwarden is used for runtime secrets in `swiss-army-container` (environment variable names and secret IDs documented in that README). Media automation services expect RabbitMQ env vars in `media-automation/docker-compose.yml`.

## Integration points & chokepoints to watch

- SSH and vault: many Ansible tasks assume SSH connectivity and that vault secrets are available. If a change touches authentication, update `Ansible/ansible.cfg` expectations and README steps.
- Container images: `swiss-army-container/Dockerfile` and any `slickg/*` images referenced in `docker-compose.yml` are built/hosted externally — confirm image names/tags when updating runtime behavior.

## What a helpful AI agent can do here

- When changing Ansible code: search for usages of host vars (e.g., `has_docker`) and update `roles/alloy_config/` templates consistently. Provide suggested `ansible-playbook` test commands including `--limit` and `--check`.
- When changing container images: update the matching README snippet in `swiss-army-container/README.md` and add a short build example (`docker build -t slickg/swiss-army-container:dev ./swiss-army-container`).
- When touching K8s manifests: point to `GKE/free-boi/examples/` and recommend `kubectl --context <ctx> apply -f` plus a brief rollout/status check.

## Quick references (paths & examples)

- Main playbooks: `Ansible/playbooks/site.yml`, `Ansible/playbooks/deploy-alloy.yml`
- Ansible config: `Ansible/ansible.cfg`
- Inventory & group vars: `Ansible/inventory.yml`, `Ansible/group_vars/` (see `all.yml`, `alloy.yml`)
- Media compose: `media-automation/docker-compose.yml`
- Swiss container README and Dockerfile: `swiss-army-container/README.md`, `swiss-army-container/Dockerfile`
- K8s examples: `GKE/free-boi/examples/`

If any of these areas are incomplete or you'd like the instructions to emphasize another workflow (e.g., Terraform or cloud provider deployment), tell me which area to expand and I will iterate.
