
# AI Agent Coding Instructions for Homelab

## Architecture Overview

This repository manages a personal homelab using infrastructure-as-code and automation. Major components:

- **Ansible/**: Host configuration, roles, and playbooks. Main entry: `Ansible/playbooks/site.yml`.
- **media-automation/**: Docker Compose workloads for media services (`docker-compose.yml`).
- **swiss-army-container/**: Custom Docker image bundling CLI tools, with Bitwarden integration for secrets.
- **hetzner/terraform/**: Terraform stack for Hetzner/Cloudflare networking, DNS, and secrets. Bootstraps Ansible.
- **k8s/**: Kubernetes manifests, Helm values, and deployment guides (see `k8s/gp/README.md` for monitoring stack).

**Key principle:** Each top-level folder is a boundary for a major system (infra, containers, automation). Changes should respect these boundaries.

## Developer Workflows

**Ansible:**
- Install roles: `ansible-galaxy install -r Ansible/requirements.yml`
- Run main playbook: `ansible-playbook Ansible/playbooks/site.yml --ask-vault-pass`
- Dry-run: add `--check` to any playbook command
- Vault: Use `--ask-vault-pass` or `.vault_pass` (never commit `.vault_pass`)

**Terraform (Hetzner/Cloudflare):**
- From `hetzner/terraform/`: `tofu init`, `tofu plan`, `tofu apply`
- Providers: Hetzner, Cloudflare, Bitwarden, Kubernetes, Helm
- Bitwarden secrets: Use environment variables, never commit secrets

**Docker/Compose:**
- Start media stack: `docker compose -f media-automation/docker-compose.yml up -d`
- Build Swiss Army image: `docker build -t slickg/swiss-army-container:dev ./swiss-army-container`
- Run Swiss Army container: see `swiss-army-container/README.md` for full example and env vars

**Kubernetes:**
- Deploy monitoring: see `k8s/gp/README.md` (namespace, secrets, Helm install, ingress)
- General manifests: `kubectl apply -f <file>`

## Project Conventions & Patterns

- **Ansible inventory:** YAML (`Ansible/inventory.yml`), host vars like `has_docker`/`has_nginx` control role inclusion
- **Secrets:** Bitwarden for secrets (see env vars in `swiss-army-container/README.md`), Ansible Vault for playbooks
- **Roles:** Custom roles in `Ansible/roles/`, register in `requirements.yml`, document required host vars
- **Terraform:** Use Bitwarden provider for secrets, never hardcode
- **K8s:** Monitoring stack expects ingress/cert-manager, domains in `values.yaml`

## Integration Points & Chokepoints

- **SSH & Vault:** Ansible assumes SSH and vault access; update `ansible.cfg` and docs if auth changes
- **Container images:** Update image tags in compose and docs when changing images
- **Secrets:** Never commit secrets; always use Bitwarden or Vault references
- **K8s ingress/cert-manager:** Monitoring stack requires working ingress and cert-manager (see `k8s/gp/README.md`)

## AI Agent Guidance

- When editing Ansible, search for host vars (e.g., `has_docker`) and update templates/roles consistently
- When changing container images, update `swiss-army-container/README.md` and add build/run examples
- When editing K8s manifests, reference `k8s/gp/README.md` for monitoring, and `GKE/free-boi/examples/` for GKE
- For Terraform, ensure Bitwarden secrets are referenced, not hardcoded
- Suggest test/dry-run commands for all infra changes

## Key References

- Ansible: `Ansible/playbooks/site.yml`, `Ansible/ansible.cfg`, `Ansible/inventory.yml`, `Ansible/group_vars/`
- Terraform: `hetzner/terraform/README.md`, `hetzner/terraform/main.tf`
- Docker: `media-automation/docker-compose.yml`, `swiss-army-container/README.md`, `swiss-army-container/Dockerfile`
- K8s: `k8s/gp/README.md`, `k8s/gp/values.yaml`, `k8s/gp/namespace.yaml`

If you need more detail on any workflow or integration, ask for clarification or check the relevant README.
