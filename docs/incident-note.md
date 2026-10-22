# Incident note: application database connection failure

- **Issue:** The student records app returned HTTP 500 "Database connection failed" (simulated fault in a test window).
- **Detection:** `curl -i http://localhost/ssb-app/health.php` returned 500 instead of 200.
- **Checks:** Apache and PHP were up (our own error page rendered). `systemctl status mysql`, `ss -tulpn | grep mysqld` and `mysqladmin ping` showed MySQL running on 127.0.0.1:3306.
- **Evidence:** `tail /var/log/apache2/error.log` showed `SQLSTATE[HY000] [1045] Access denied for user 'ssb_user'@'localhost' (using password: YES)`, and `/etc/ssb-app/.env` had a fresh modification time.
- **Cause:** `DB_PASS` in `/etc/ssb-app/.env` did not match the password of the MySQL user `ssb_user`.
- **Fix:** Restored the correct `.env` from a permission-preserving copy (`cp -p`), then re-ran the health check: HTTP 200.
- **Prevention:** Keep a known-good copy of the config outside the web root, change passwords in MySQL and `.env` together, run `./scripts/deploy.sh` (it validates the config), and alert on non-200 health checks.
- **Impact:** App unavailable for a few minutes; no data lost.
