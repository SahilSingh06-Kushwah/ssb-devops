#!/usr/bin/env bash
# backup.sh - back up the MySQL database (mysqldump) and the deployed app files (tar.gz).
#
# Usage: ./scripts/backup.sh
# Output: backups/<db>_<timestamp>.sql and backups/app_files_<timestamp>.tar.gz
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-/etc/ssb-app/.env}"
APP_DIR="${APP_DIR:-/var/www/html/ssb-app}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backups}"
STAMP="$(date +%F_%H%M%S)"

info() { echo "[backup] $*"; }
die()  { echo "[backup] ERROR: $*" >&2; exit 1; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

# ---------- Validation ----------
command -v mysqldump >/dev/null 2>&1 || die "mysqldump not found (run: sudo apt install mysql-client)"
command -v tar >/dev/null 2>&1 || die "tar not found"
$SUDO test -f "$ENV_FILE" || die "Config file missing: $ENV_FILE"
[ -d "$APP_DIR" ] || die "Application folder not found: $APP_DIR"

get_env() { $SUDO sed -n "s/^$1=//p" "$ENV_FILE" | head -n1; }

DB_HOST="$(get_env DB_HOST)"
DB_PORT="$(get_env DB_PORT)"; DB_PORT="${DB_PORT:-3306}"
DB_NAME="$(get_env DB_NAME)"
DB_USER="$(get_env DB_USER)"
DB_PASS="$(get_env DB_PASS)"
for var in DB_HOST DB_NAME DB_USER DB_PASS; do
  [ -n "${!var}" ] || die "$var is missing or empty in $ENV_FILE"
done

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Temporary credentials file so the password never appears on the command line
CNF="$(mktemp)"
chmod 600 "$CNF"
trap 'rm -f "$CNF"' EXIT
printf '[client]\nuser=%s\npassword="%s"\nhost=%s\nport=%s\n' \
  "$DB_USER" "$DB_PASS" "$DB_HOST" "$DB_PORT" > "$CNF"

# ---------- Database backup ----------
DB_FILE="$BACKUP_DIR/${DB_NAME}_${STAMP}.sql"
info "Dumping database '$DB_NAME'..."
if ! mysqldump --defaults-extra-file="$CNF" --single-transaction --no-tablespaces "$DB_NAME" > "$DB_FILE"; then
  rm -f "$DB_FILE"
  die "mysqldump failed (check credentials and that MySQL is running)"
fi
grep -q "Dump completed" "$DB_FILE" || { rm -f "$DB_FILE"; die "Dump looks incomplete, removed $DB_FILE"; }

# ---------- Application files backup ----------
FILES_FILE="$BACKUP_DIR/app_files_${STAMP}.tar.gz"
info "Archiving application files from '$APP_DIR'..."
tar -czf "$FILES_FILE" -C "$(dirname "$APP_DIR")" "$(basename "$APP_DIR")"
tar -tzf "$FILES_FILE" >/dev/null || die "Archive check failed: $FILES_FILE"

info "Backup complete:"
ls -lh "$DB_FILE" "$FILES_FILE"
