# RHIS Change Log

This file tracks repository changes from this point forward.

## Entry format

- **Timestamp:** `YYYY-MM-DD HH:MM:SS TZ`
- **Area:** file(s) or component(s)
- **Summary:** short description of what changed
- **Reason:** why the change was made

---

## 2026-03-23 17:39:04 MDT

### 2026-03-23 17:39:04 MDT — Script hardening and orchestration updates
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added container playbook hotfix preflight with verify/fail-fast controls.
  - Added/remediated IdM update task patching (`disable_gpg_check`, firmware exclusion) and Satellite pre-task non-fatal handling.
  - Added/normalized `SATELLITE_PRE_USE_IDM` handling and injected IdM integration vars for Satellite flows.
  - Added startup installer-host collection visibility check and unified required collection source list.
  - Added AAP callback wait progress monitor (heartbeat, % progress, remaining time, stage transitions, fail-fast stall detection).
  - Improved manual rerun guidance with container prerequisite checks and root-auth fallback template.
  - Enforced VM build creation order: `IdM -> Satellite -> AAP`.
- **Reason:** Improve reliability, visibility, and deterministic dependency order while reducing repeated operator troubleshooting.

### 2026-03-23 17:39:04 MDT — Documentation alignment
- **Area:** `README.md`, `CHECKLIST.md`, `Doc/README.md`, `host_vars/README.md`, `inventory/README.md`
- **Summary:**
  - Updated docs to match current runtime behavior and dependency order.
  - Documented AAP callback progress/fail-fast controls and collection preflight behavior.
  - Updated manual rerun notes to include container availability prerequisite.
- **Reason:** Keep operator documentation synchronized with script behavior.

## 2026-03-24 07:28:21 MDT

### 2026-03-24 07:28:21 MDT — SSH mesh fallback hardening
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added installer-user + passwordless `sudo` fallback for root SSH key bootstrap on RHIS nodes.
  - Added installer-user + `sudo` fallback when collecting root public keys.
  - Added installer-user + `sudo` fallback when distributing root trust keys.
- **Reason:** Prevent RHIS from aborting when direct `root@<node>` SSH is not ready yet but the installer/admin account is already available.

### 2026-03-24 07:35:18 MDT — Managed container patch persistence
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added top-level RHIS-managed container patch functions for Satellite and IdM playbook component fixes.
  - Container startup/reuse now automatically reapplies and verifies these patches on every deployment or restart of `rhis-provisioner`.
  - Current managed patches include the Satellite `chrony.j2` fallback, non-fatal foreman service check patch, and IdM update-task GPG/firmware guard patch.
- **Reason:** Ensure all container component fixes are maintained by the script itself and are consistently re-applied whenever a new provisioner container is deployed through RHIS.

### 2026-03-24 07:51:02 MDT — Per-run installer logging under /var/log/rhis
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added run-log configuration and startup log initialization for each script invocation.
  - Script now ensures `/var/log/rhis` exists and writes a timestamped per-run logfile.
  - Added output mirroring (`tee`) so each RHIS run is captured while still printing live to console.
  - Added/updated `latest.log` symlink in `/var/log/rhis` for quick access to most recent run.
- **Reason:** Provide durable, per-run operational logs for troubleshooting and auditability of each `rhis_install.sh` execution.

### 2026-03-24 07:54:03 MDT — Automatic run-log retention/pruning
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added `RHIS_RUN_LOG_KEEP_COUNT` (default `30`) to control retained per-run installer logs.
  - Added automatic pruning of old `/var/log/rhis/rhis_install_*.log` files after logging initialization.
  - Retention keeps newest logs by mtime and removes older files beyond the configured count.
- **Reason:** Prevent unbounded growth of `/var/log/rhis` while preserving recent execution history.

### 2026-03-24 08:09:44 MDT — Root SSH mesh defaults to best-effort
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added `RHIS_REQUIRE_ROOT_SSH_MESH` (default `0`) to control whether root mesh failures are fatal.
  - Updated `setup_rhis_ssh_mesh()` so installer-user mesh remains mandatory, while root-key bootstrap/collection/distribution failures warn-and-continue by default.
  - Added runtime summary output for `RHIS_REQUIRE_ROOT_SSH_MESH`.
- **Reason:** Avoid aborting full workflow when root key auth is not fully ready on one node (for example IdM), while still allowing strict enforcement when explicitly required.

### 2026-03-24 08:15:26 MDT — SSH key/known_hosts stability hardening for rebuilt RHIS nodes
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added dedicated persistent installer-host RHIS SSH key path (`RHIS_INSTALLER_SSH_KEY_DIR`) so RHIS mesh operations no longer depend on/churn default `~/.ssh/id_rsa`.
  - Updated SSH mesh bootstrap/copy-id paths to use the dedicated RHIS installer key.
  - Added known_hosts refresh for RHIS node IPs/hostnames (`RHIS_REFRESH_KNOWN_HOSTS`, default enabled) to remove stale host keys and reseed current keys after VM rebuild cycles.
  - Added runtime/help visibility for these new SSH stability controls.
- **Reason:** Prevent recurring host-key-change breakage and avoid impacting the static installer host’s primary SSH identity during repeated RHIS rebuild/install cycles.

### 2026-03-24 08:45:25 MDT — Config-only auth resilience preflight
- **Area:** `rhis_install.sh`
- **Summary:**
  - Added config-as-code preflight call to refresh SSH trust baseline (`setup_rhis_ssh_mesh`) before phase playbooks (best-effort in this path).
  - Added config-as-code preflight root password normalization (`fix_vm_root_passwords`) before phase execution to improve root fallback reliability.
- **Reason:** Reduce repeated phase failures in container config-only/rerun workflows caused by SSH trust drift and root password mismatch between current vault values and guest state.
