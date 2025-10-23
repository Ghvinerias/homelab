
WIP
(This project is still work in progress)
==========================


Containerized Ansible helper
===========================

This Ansible workspace is expected to be executed inside a Docker container named
`wireguard`. The repository root is mounted inside the container at:

  /root/homelab/hetzner/ansible

Usage helper script
-------------------

A small wrapper, `docker-ansible.sh`, is included to run Ansible commands inside
the `wireguard` container. It forwards the current working directory to the
container's mapped path and preserves tty/stdin when appropriate.

Examples
--------

Run a playbook from the host shell (from the repo root):

  ./docker-ansible.sh ansible-playbook -i inventory.ini playbook.yml

Open an interactive shell inside the container at the mapped workspace:

  docker exec -it -w /root/homelab/hetzner/ansible wireguard bash

Notes
-----

- The wrapper assumes the Docker container is already running and named
  `wireguard`.
- If your container uses a different name or the workspace is mapped elsewhere,
  update `docker-ansible.sh` accordingly.
