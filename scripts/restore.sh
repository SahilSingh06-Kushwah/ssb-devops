#!/usr/bin/env bash
# restore.sh - restore a SQL backup into a TEST database and verify row counts.
#
# Usage: ./scripts/restore.sh backups/<file>.sql [target_db]
# Default target database: ssb_app_restore_test
set -euo pipefail

BACKUP_FILE="${1:-}"
TARGET_DB="${2:-ssb_app_restore_test}"
SOURCE_DB="${SOURCE_DB:-ssb_app}"

info() { echo "[restore] $*"; }
die()  { echo "[restore] ERROR: $*" >&2; exit 1; }

[ -n "$BACKUP_FILE" ] || die "Usage: $0 backups/<file>.sql [target_db]"
[ -f "$BACKUP_FILE" ] || die "Backup file not found: $BACKUP_FILE"
[[ "$TARGET_DB" =~ ^[A-Za-z0-9_]+$ ]] || die "Invalid database name: $TARGET_DB"
[ "$TARGET_DB" != "$SOURCE_DB" ] || die "Refusing to restore over the live database '$SOURCE_DB'"
command -v mysql >/dev/null 2>&1 || die "mysql client not found"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

info "Creating test database '$TARGET_DB'..."
$SUDO mysql -e "CREATE DATABASE IF NOT EXISTS \`$TARGET_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

info "Restoring $BACKUP_FILE into '$TARGET_DB'..."
$SUDO mysql "$TARGET_DB" < "$BACKUP_FILE"

info "Verifying row counts (live vs restored):"
bad=0
tables="$($SUDO mysql -N -e "SELECT table_name FROM information_schema.tables WHERE table_schema='${SOURCE_DB}'")"
for t in $tables; do
  src="$($SUDO mysql -N -e "SELECT COUNT(*) FROM \`$SOURCE_DB\`.\`$t\`")"
  dst="$($SUDO mysql -N -e "SELECT COUNT(*) FROM \`$TARGET_DB\`.\`$t\`" 2>/dev/null || echo missing)"
  if [ "$src" = "$dst" ]; then
    echo "  $t: live=$src restored=$dst OK"
  else
    echo "  $t: live=$src restored=$dst MISMATCH"
    bad=1
  fi
done

[ "$bad" -eq 0 ] || die "Verification failed"
info "Restore verified."
