provider "proxmox" {
  endpoint = var.proxmox_endpoint

  # TODO: use terraform variable or remove the line, and use PROXMOX_VE_USERNAME environment variable
  # username = "root@pam"
  # TODO: use terraform variable or remove the line, and use PROXMOX_VE_PASSWORD environment variable
  # password = "the-password-set-during-installation-of-proxmox-ve"

  insecure = true # Only needed if your Proxmox server is using a self-signed certificate
}
