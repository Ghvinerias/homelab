# Ansible Homelab Setup

A simple Ansible configuration for managing your homelab infrastructure.

## Directory Structure

```
Ansible/
├── ansible.cfg          # Ansible configuration
├── inventory.yml        # Host inventory
├── .vault_pass         # Vault password file (add to .gitignore)
├── group_vars/         # Group-specific variables
│   ├── all.yml        # Variables for all hosts
│   └── homelab.yml    # Variables for homelab group
├── host_vars/         # Host-specific variables
├── playbooks/         # Ansible playbooks
│   └── site.yml       # Main site playbook
└── roles/             # Custom roles (to be created)
```

## Getting Started

### 1. Configure Inventory

Edit `inventory.yml` to add your hosts:

```yaml
all:
  children:
    homelab:
      hosts:
        server1:
          ansible_host: 192.168.1.100
          ansible_user: your_username
        server2:
          ansible_host: 192.168.1.101
          ansible_user: your_username
```

### 2. Set Up Vault Password

**Option A: Using --ask-vault-pass (Recommended for security)**

Run any ansible command with the `--ask-vault-pass` flag:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

**Option B: Using password file (for automation)**

1. Create a vault password file:
   ```bash
   echo "your_secure_password" > .vault_pass
   chmod 600 .vault_pass
   ```

2. Add `.vault_pass` to your `.gitignore`:
   ```bash
   echo ".vault_pass" >> .gitignore
   ```

### 3. Working with Ansible Vault

#### Create encrypted variables:

```bash
# Create a new encrypted file
ansible-vault create group_vars/secrets.yml --ask-vault-pass

# Encrypt an existing file
ansible-vault encrypt group_vars/all.yml --ask-vault-pass

# Edit an encrypted file
ansible-vault edit group_vars/secrets.yml --ask-vault-pass
```

#### Encrypt specific variables in YAML files:

```bash
# Encrypt a single variable
ansible-vault encrypt_string 'secret_value' --name 'secret_variable' --ask-vault-pass
```

Example output to add to your YAML files:
```yaml
secret_variable: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66386439653834336464626566653738653938396539...
```

#### Decrypt files for viewing:

```bash
# View encrypted file content
ansible-vault view group_vars/secrets.yml --ask-vault-pass

# Decrypt file (creates unencrypted copy)
ansible-vault decrypt group_vars/secrets.yml --ask-vault-pass
```

### 4. Running Playbooks

#### Basic playbook execution:

```bash
# Run main playbook with vault password prompt
ansible-playbook playbooks/site.yml --ask-vault-pass

# Run with specific inventory and become password
ansible-playbook playbooks/site.yml --ask-vault-pass --ask-become-pass

# Dry run (check mode)
ansible-playbook playbooks/site.yml --ask-vault-pass --check

# Run on specific hosts
ansible-playbook playbooks/site.yml --ask-vault-pass --limit server1
```

#### Ad-hoc commands:

```bash
# Ping all hosts
ansible all -m ping --ask-vault-pass

# Run shell command on all hosts
ansible all -m shell -a "uptime" --ask-vault-pass --ask-become-pass
```

### 5. Common Vault Use Cases

#### Store sensitive information:

Create `group_vars/secrets.yml`:
```bash
ansible-vault create group_vars/secrets.yml --ask-vault-pass
```

Add content like:
```yaml
---
# Database credentials
db_user: admin
db_password: super_secret_password

# API keys
api_key: your_api_key_here

# SSL certificate passwords
ssl_keystore_password: certificate_password
```

#### Reference encrypted variables in playbooks:

```yaml
- name: Configure database
  template:
    src: database.conf.j2
    dest: /etc/app/database.conf
  vars:
    username: "{{ db_user }}"
    password: "{{ db_password }}"
```

## Security Best Practices

1. **Always use `--ask-vault-pass`** for better security
2. Never commit `.vault_pass` file to version control
3. Use strong, unique passwords for your vault
4. Regularly rotate vault passwords
5. Consider using `ansible-vault rekey` to change vault passwords:
   ```bash
   ansible-vault rekey group_vars/secrets.yml --ask-vault-pass
   ```

## Future Expansions

This basic structure is ready for:
- Adding custom roles in the `roles/` directory
- Creating specific playbooks for different tasks
- Organizing variables by environment (dev, staging, prod)
- Implementing more complex inventory structures

## Grafana Alloy Deployment

### Quick Start

1. **Install required roles**:
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

2. **Configure your inventory** with server capabilities:
   ```yaml
   homelab:
     hosts:
       server1:
         ansible_host: 192.168.1.100
         has_docker: true
         has_nginx: false
         custom_tools: []
   ```

3. **Deploy Alloy**:
   ```bash
   ansible-playbook playbooks/deploy-alloy.yml --ask-vault-pass
   ```

### Server Configuration Detection

The playbook uses **manual configuration only**. You must define capabilities for each host:

Required host variables:
- ✅ `has_docker: true/false` - Enable Docker metrics and logs
- ✅ `has_nginx: true/false` - Enable Nginx log collection  
- ✅ `custom_tools: []` - List of custom tools for log collection

Example inventory configuration:
```yaml
homelab:
  hosts:
    server1:
      ansible_host: 192.168.1.100
      has_docker: true      # Docker installed
      has_nginx: false      # No Nginx
      custom_tools: []      # No custom tools
    server2:
      ansible_host: 192.168.1.101  
      has_docker: false     # No Docker
      has_nginx: true       # Nginx installed
      custom_tools: ["mysql", "redis"] # Custom tools
```

### Generated Configurations

Based on server capabilities, Alloy configs include:

**Base (all servers):**
- System logs & journal
- System metrics (CPU, memory, disk, network)

**Docker servers:**
- Docker container metrics (cAdvisor)
- Docker container logs

**Nginx servers:**
- Nginx access/error logs
- Optional: Nginx metrics (if exporter available)

**Custom tools:**
- Log collection for specified tools
- Configurable per-host

### Configuration Files

- `inventory-example.yml` - Example inventory with different server types
- `group_vars/alloy.yml` - Alloy-specific configuration
- `roles/alloy_config/` - Custom role for dynamic config generation
- `playbooks/deploy-alloy.yml` - Main deployment playbook

## Quick Reference Commands

```bash
# Install Galaxy requirements
ansible-galaxy install -r requirements.yml

# Deploy Alloy to all servers
ansible-playbook playbooks/deploy-alloy.yml --ask-vault-pass

# Deploy to specific servers
ansible-playbook playbooks/deploy-alloy.yml --ask-vault-pass --limit docker_servers

# Check Alloy service status
ansible homelab -m systemd -a "name=alloy" --ask-vault-pass

# Test Alloy configuration
ansible-playbook playbooks/deploy-alloy.yml --ask-vault-pass --check

# Create new vault file
ansible-vault create filename.yml --ask-vault-pass

# Edit vault file
ansible-vault edit filename.yml --ask-vault-pass

# Encrypt existing file
ansible-vault encrypt filename.yml --ask-vault-pass

# Run playbook with vault
ansible-playbook playbook.yml --ask-vault-pass

# Run with both vault and sudo passwords
ansible-playbook playbook.yml --ask-vault-pass --ask-become-pass
```
