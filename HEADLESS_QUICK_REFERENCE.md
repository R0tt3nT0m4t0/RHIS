# RHIS Headless Quick Reference

## One-Command Deployment

```bash
# 1. Copy template
cp rhis-headless.env.template /etc/rhis/headless.env

# 2. Edit with your values
nano /etc/rhis/headless.env

# 3. Make scripts executable (first time only)
chmod +x rhis-headless-validate.sh rhis_install.sh

# 4. Validate configuration
./rhis-headless-validate.sh 5

# 5. Run deployment
source /etc/rhis/headless.env
./rhis_install.sh --non-interactive --menu-choice 5
```

---

## Environment Variables Cheat Sheet

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `RH_USER` | Red Hat CDN username | `rh_user@example.com` | Menu 1,2,4,5 |
| `RH_PASS` | Red Hat CDN password | `secure-pass` | Menu 1,2,4,5 |
| `ADMIN_PASS` | Local admin password | `P@ssw0rd123!` | Menu 3,4,5,7 |
| `IDM_IP` | IdM VM IP (internal) | `10.168.128.3` | Menu 3,4,5,7 |
| `IDM_HOSTNAME` | IdM FQDN | `idm.example.com` | Menu 4,5,7 |
| `IDM_DS_PASS` | Directory Service password | `secure-pass` | Menu 4,5,7 |
| `SAT_IP` | Satellite VM IP | `10.168.128.1` | Menu 3,4,5,7 |
| `SAT_HOSTNAME` | Satellite FQDN | `satellite.example.com` | Menu 4,5,7 |
| `SAT_ORG` | Satellite organization | `Default_Organization` | Menu 4,5,7 |
| `SAT_LOC` | Satellite location | `Default_Location` | Menu 4,5,7 |
| `AAP_IP` | AAP VM IP | `10.168.128.2` | Menu 3,4,5,7 |
| `AAP_HOSTNAME` | AAP FQDN | `aap.example.com` | Menu 4,5,7 |
| `HUB_TOKEN` | Automation Hub token | `eyJ...` | Menu 4,5,7 |
| `DOMAIN` | Base domain | `example.com` | Menu 4,5,7 |
| `HOST_INT_IP` | Host internal IP | `10.168.128.1` | Optional |
| `DEMO_MODE` | Use demo partitions | `1` (or `0`) | Optional |

---

## Menu Quick Select

| Menu | Purpose | Time | Requires |
|------|---------|------|----------|
| **1** | Local App Mode | 5 min | RH creds |
| **2** | Container Only | 5 min | RH creds |
| **3** | VMs Only | 10 min | Network vars |
| **4** | Local + VMs (no config) | 15 min | All vars |
| **5** | Container + VMs + Config ⭐ | 90 min | All vars |
| **7** | Config Existing VMs | 45 min | Network vars |

---

## Headless Modes

### Full Headless (Recommended)
```bash
export $(cat /etc/rhis/headless.env | grep -v '^#')
./rhis_install.sh --non-interactive --menu-choice 5
```

### As systemd Service
```bash
cat > /etc/systemd/system/rhis-install.service << 'EOF'
[Unit]
Description=RHIS Headless Installer
After=network.target

[Service]
Type=oneshot
EnvironmentFile=/etc/rhis/headless.env
ExecStart=/root/rhis_install.sh --non-interactive --menu-choice 5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start rhis-install.service
systemctl status rhis-install.service
journalctl -u rhis-install.service -f
```

### In Container
```bash
docker run -it --rm \
  --env-file /etc/rhis/headless.env \
  -v /var/run/libvirt:/var/run/libvirt \
  -v /root/.ssh:/root/.ssh:ro \
  rhis-installer:latest \
  ./rhis_install.sh --non-interactive --menu-choice 5
```

### With Terraform
```hcl
resource "null_resource" "rhis" {
  provisioner "local-exec" {
    command = "source /etc/rhis/headless.env && /root/rhis_install.sh --non-interactive --menu-choice 5"
  }
}
```

---

## Troubleshooting

### Validation Fails
```bash
./rhis-headless-validate.sh 5    # Detailed diagnosis
env | grep -E "^(RH_|IDM_|SAT_|AAP_)"  # Check what's set
```

### Installation Hangs
```bash
# Check logs in real-time
tail -f /var/log/rhis/rhis_install_*.log

# Monitor VMs
watch virsh list --all

# Check container
podman logs -f rhis-provisioner
```

### Network Issues
```bash
ping $HOST_INT_IP        # Host reachable?
ping $IDM_IP             # IdM reachable? (after VM boots)
ssh root@$IDM_IP hostname  # SSH working?
```

### SSH Authentication
```bash
# Verify key
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no root@$IDM_IP "echo OK"

# Regenerate if needed
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
```

---

## Post-Deployment

### Access Web UIs
```bash
# IdM
https://$IDM_HOSTNAME/ipa/ui/    (or https://10.168.128.3/ipa/ui/)

# Satellite  
https://$SAT_HOSTNAME/          (or https://10.168.128.1/)

# AAP
https://$AAP_HOSTNAME/          (or https://10.168.128.2/)
```

### Verify Services
```bash
# SSH to each VM
ssh root@$IDM_IP "ipactl status"
ssh root@$SAT_IP "systemctl status satellite"
ssh root@$AAP_IP "systemctl status automation-controller"
```

### View Status Dashboard
```bash
./rhis_install.sh --non-interactive --menu-choice 8
```

---

## Common Env Files

### Minimal (Testing)
```bash
RH_USER="user"
RH_PASS="pass"
ADMIN_PASS="pass"
IDM_IP="10.168.128.3"
IDM_HOSTNAME="idm.local"
DOMAIN="local"
IDM_DS_PASS="pass"
SAT_IP="10.168.128.1"
SAT_HOSTNAME="sat.local"
SAT_ORG="Org"
SAT_LOC="Loc"
AAP_IP="10.168.128.2"
AAP_HOSTNAME="aap.local"
HUB_TOKEN="token"
DEMO_MODE=1
```

### Production
```bash
# Load from Vault/Secrets Manager:
export RH_USER="$(vault kv get -field=username secret/rh)"
export RH_PASS="$(vault kv get -field=password secret/rh)"
export ADMIN_PASS="$(vault kv get -field=admin_pass secret/rhis)"
export IDM_DS_PASS="$(vault kv get -field=ds_pass secret/idm)"
export HUB_TOKEN="$(vault kv get -field=token secret/hub)"

export IDM_HOSTNAME="${ENV_PREFIX}.idm.${BASE_DOMAIN}"
export SAT_HOSTNAME="${ENV_PREFIX}.satellite.${BASE_DOMAIN}"
export AAP_HOSTNAME="${ENV_PREFIX}.aap.${BASE_DOMAIN}"
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | ✓ Success |
| 1 | ✗ General error |
| 2 | ✗ Invalid CLI flag |
| 3 | ✗ Missing env var |
| 4 | ✗ Network/SSH error |
| 5 | ✗ Container/VM error |

---

## Resources

- **Full Guide:** [HEADLESS_OPERATIONS.md](HEADLESS_OPERATIONS.md)
- **Validator:** Run `./rhis-headless-validate.sh` before deployment
- **Logs:** `/var/log/rhis/rhis_install_*.log`
- **Container:** `podman exec rhis-provisioner bash`
- **VMs:** `virsh list --all`

---

**Created:** 2026-03-24  
**Last Updated:** 2026-03-24
