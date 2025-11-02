.PHONY: help deploy status kubeconfig test-lb ssh-master destroy clean

# Hetzner K8s Cluster Makefile

SCRIPTS_DIR := scripts
TERRAFORM_DIR := terraform
KUBECONFIG_PATH := $(HOME)/.kube/config-hetzner

help: ## Show this help message
	@echo "Hetzner K8s Cluster Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Infrastructure
init: ## Initialize Terraform
	@echo "🔧 Initializing Terraform..."
	cd $(TERRAFORM_DIR) && tofu init

plan: ## Plan infrastructure changes
	@echo "📋 Planning infrastructure..."
	cd $(TERRAFORM_DIR) && tofu plan

apply: ## Apply infrastructure (create servers)
	@echo "🚀 Applying infrastructure..."
	cd $(TERRAFORM_DIR) && tofu apply

# Cluster Deployment
deploy: ## Deploy complete K8s cluster (automated)
	@echo "🚀 Deploying K8s cluster..."
	@chmod +x $(SCRIPTS_DIR)/*.sh
	cd $(SCRIPTS_DIR) && ./deploy-cluster.sh

provision-master: ## Provision master node only
	@echo "🎯 Provisioning master node..."
	@chmod +x $(SCRIPTS_DIR)/provision-master.sh
	cd $(SCRIPTS_DIR) && ./provision-master.sh

provision-workers: ## Provision worker nodes only
	@echo "👷 Provisioning worker nodes..."
	@chmod +x $(SCRIPTS_DIR)/provision-worker.sh
	cd $(SCRIPTS_DIR) && ./provision-worker.sh

deploy-metallb: ## Deploy MetalLB LoadBalancer
	@echo "⚖️  Deploying MetalLB..."
	@chmod +x $(SCRIPTS_DIR)/deploy-metallb.sh
	cd $(SCRIPTS_DIR) && ./deploy-metallb.sh

# Cluster Management
status: ## Show cluster status
	@$(SCRIPTS_DIR)/cluster-helper.sh status

kubeconfig: ## Get kubeconfig from master
	@$(SCRIPTS_DIR)/cluster-helper.sh get-kubeconfig
	@echo ""
	@echo "✓ Kubeconfig saved to $(KUBECONFIG_PATH)"
	@echo "  Run: export KUBECONFIG=$(KUBECONFIG_PATH)"

join-command: ## Get worker join command
	@$(SCRIPTS_DIR)/cluster-helper.sh get-join-command

# Testing
test-lb: ## Test LoadBalancer with nginx
	@$(SCRIPTS_DIR)/cluster-helper.sh test-metallb

endpoints: ## Show all LoadBalancer endpoints
	@$(SCRIPTS_DIR)/cluster-helper.sh endpoints

# Node Access
ssh-master: ## SSH to master node (server1)
	@$(SCRIPTS_DIR)/cluster-helper.sh ssh server1

ssh-agent1: ## SSH to agent1
	@$(SCRIPTS_DIR)/cluster-helper.sh ssh agent1

ssh-agent2: ## SSH to agent2
	@$(SCRIPTS_DIR)/cluster-helper.sh ssh agent2

ssh-agent3: ## SSH to agent3
	@$(SCRIPTS_DIR)/cluster-helper.sh ssh agent3

logs-master: ## Show kubelet logs from master
	@$(SCRIPTS_DIR)/cluster-helper.sh logs server1

# Kubectl Commands (require kubeconfig)
nodes: ## Show cluster nodes
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) get nodes -o wide

pods: ## Show all pods
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) get pods -A

services: ## Show all services
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) get svc -A

metallb-status: ## Check MetalLB status
	@echo "MetalLB Pods:"
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) get pods -n metallb-system
	@echo ""
	@echo "IP Address Pools:"
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) get ipaddresspool -n metallb-system
	@echo ""
	@echo "L2 Advertisements:"
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) get l2advertisement -n metallb-system

# Cleanup
destroy: ## Destroy entire infrastructure (careful!)
	@$(SCRIPTS_DIR)/cluster-helper.sh destroy

clean: ## Clean local kubeconfig
	@echo "🧹 Cleaning local files..."
	@rm -f $(KUBECONFIG_PATH)
	@rm -f $(KUBECONFIG_PATH).bak
	@echo "✓ Cleaned"

# Quick deployment workflow
quick-deploy: apply deploy kubeconfig status ## Complete deployment workflow
	@echo ""
	@echo "✅ Cluster deployment complete!"
	@echo "   export KUBECONFIG=$(KUBECONFIG_PATH)"

# Show current configuration
show-config: ## Show current configuration
	@echo "Configuration:"
	@echo "  Scripts: $(SCRIPTS_DIR)"
	@echo "  Terraform: $(TERRAFORM_DIR)"
	@echo "  Kubeconfig: $(KUBECONFIG_PATH)"
	@echo ""
	@echo "Environment:"
	@env | grep -E "(BWS_|HETZNER_)" || echo "  No BWS/Hetzner env vars set"
