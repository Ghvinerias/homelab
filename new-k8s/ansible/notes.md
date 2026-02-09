#Runs on pve
qm create 8000 --memory 2048 --core 2 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
qm disk import 8000 noble-server-cloudimg-amd64.img share-hdd
qm set 8000 --scsihw virtio-scsi-pci --scsi0 share-hdd:8000/vm-8000-disk-0.raw
qm set 8000 --ide2 share-hdd:cloudinit
qm set 8000 --boot c --bootdisk scsi0
qm set 8000 --serial0 socket --vga serial0

#Runs on pve
qm clone 8000 4001 --name "k8s-mgmt-01" --full
qm clone 8000 5001 --name "k8s-node-01" --full
qm clone 8000 5002 --name "k8s-node-02" --full
qm clone 8000 5003 --name "k8s-node-03" --full
qm clone 8000 5004 --name "k8s-node-04" --full

#Runs on pve
qm migrate 5001 dell-01 --online 0
qm migrate 5002 dell-02 --online 0
qm migrate 5003 dell-03 --online 0

#Runs on dell-02
qm move-disk 5002 scsi0 local-lvm
qm resize 5002 scsi0 +130G
qm set 5002 -net0 virtio=52:54:00:BB:00:02,bridge=vmbr0,tag=1199 --memory 12048 --cores 10
qm start 5002

#Runs on dell-01
qm move-disk 5001 scsi0 local-lvm
qm resize 5001 scsi0 +130G
qm set 5001 -net0 virtio=52:54:00:BB:00:01,bridge=vmbr0,tag=1199 --memory 12048 --cores 10
qm start 5001

#Runs on dell-03
qm move-disk 5003 scsi0 local-lvm
qm resize 5003 scsi0 +130G
qm set 5003 -net0 virtio=52:54:00:BB:00:03,bridge=vmbr0,tag=1199 --memory 12048 --cores 10
qm start 5003


#Runs on pve
qm move-disk 5004 scsi0 local-lvm
qm resize 5004 scsi0 +50G
qm set 5004 -net0 virtio=52:54:00:BB:00:04,bridge=vmbr0,tag=1199
qm start 5004