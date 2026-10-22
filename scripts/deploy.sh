#!/usr/bin/env bash
# deploy.sh - validate, dry-run, then deploy app/ to the web folder with rsync.
#
# Usage:
#   ./scripts/deploy.sh             # validate, dry run, ask, deploy, health check
#   ./scripts/deploy.sh --dry-run   # validate and show the dry run only
#   ./scripts/deploy.sh --yes       # skip the confirmation prompt
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${SRC:-$PROJECT_ROOT/app/}"
DEST="${DEST:-/var/www/html/ssb-app/}"
ENV_FILE="${ENV_FILE:-/etc/ssb-app/.env}"
HEALTH_URL="${HEALTH_URL:-http://localhost/ssb-app/health.php}"

DRY_RUN_ONLY=false
ASSUME_YES=false

info() { echo "[deploy] $*"; }
die()  { echo "[deploy] ERROR: $*" >&2; exit 1; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN_ONLY=true ;;
    --yes|-y)  ASSUME_YES=true ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *)         die "Unknown option: $arg (use --dry-run, --yes or --help)" ;;
  esac
done

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

# ---------- 1. Validation ----------
info "Validating environment..."

command -v rsync >/dev/null 2>&1 || die "rsync is not installed (run: sudo apt install rsync)"

[ -d "$SRC" ] || die "Source folder not found: $SRC"
for f in index.php bootstrap.php health.php; do
  [ -f "$SRC/$f" ] || die "Required file missing in source: $SRC/$f"
done

# --delete is used below, so refuse dangerous targets
case "${DEST%/}" in
  ""|"/"|"/var"|"/var/www"|"/var/www/html") die "Refusing unsafe deploy target: '$DEST'" ;;
esac
[ -d "$(dirname "${DEST%/}")" ] || die "Parent of deploy folder does not exist: $(dirname "${DEST%/}")"

$SUDO test -f "$ENV_FILE" || die "Config file missing: $ENV_FILE (copy .env.example there and fill it in)"
for key in DB_HOST DB_NAME DB_USER DB_PASS; do
  $SUDO grep -q "^${key}=." "$ENV_FILE" || die "Config key $key is missing or empty in $ENV_FILE"
done
if $SUDO grep -q '^DB_PASS=change_me$' "$ENV_FILE"; then
  die "DB_PASS in $ENV_FILE is still the placeholder value"
fi

if command -v php >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    php -l "$file" >/dev/null || die "PHP syntax error in $file"
  done < <(find "$SRC" -name '*.php' -print0)
  info "PHP syntax check passed"
fi

info "Validation passed"

# ---------- 2. rsync ----------
RSYNC_OPTS=(
  -avhi --delete
  --chown=root:www-data --chmod=D755,F644
  --exclude=.git --exclude=.env --exclude='*.log' --exclude='backups/'
)

$SUDO mkdir -p "$DEST"

info "Dry run (no changes made):"
$SUDO rsync "${RSYNC_OPTS[@]}" --dry-run "$SRC" "$DEST"

if [ "$DRY_RUN_ONLY" = true ]; then
  info "Dry run only, nothing deployed."
  exit 0
fi

if [ "$ASSUME_YES" = false ]; then
  read -r -p "[deploy] Proceed with the real deployment? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { info "Cancelled."; exit 0; }
fi

info "Deploying..."
$SUDO rsync "${RSYNC_OPTS[@]}" "$SRC" "$DEST"

# ---------- 3. Health check ----------
if command -v curl >/dev/null 2>&1; then
  curl -fsS "$HEALTH_URL" >/dev/null || die "Health check failed: $HEALTH_URL"
  info "Health check passed: $HEALTH_URL"
fi

info "Deployment finished."
