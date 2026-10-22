# Security and permissions

## Secrets
- No passwords or keys are committed. `.env`, logs and backups are in `.gitignore`.
- `.env.example` holds placeholders only.
- Real settings live in `/etc/ssb-app/.env`, outside the web root.
- rsync excludes `.env`, `.git`, `*.log` and `backups/`, so they never reach the web folder.
- Checked: the real DB password does not appear in tracked files or in git history.

## File ownership and permissions
| Path | Mode | Owner:group |
|---|---|---|
| /etc/ssb-app | 750 | root:www-data |
| /etc/ssb-app/.env | 640 | root:www-data |
| /var/www/html/ssb-app (dirs) | 755 | root:www-data |
| /var/www/html/ssb-app (files) | 644 | root:www-data |
| backups/ | 700 | ubuntu:ubuntu |

- Apache (www-data) can read the app but cannot modify it. Nothing is world-writable.
- deploy.sh sets ownership and permissions on every deploy (rsync --chown/--chmod).

## Database user
- The app connects as `ssb_user`, never root.
- Rights: SELECT, INSERT, UPDATE, DELETE on `ssb_app.*` only.
- It cannot create databases, drop tables or read other accounts.
- Admin work goes through `pma_admin` (phpMyAdmin) or `sudo mysql` (socket auth).

## Network
- MySQL listens on 127.0.0.1 only; port 3306 is not open in the security group.
- Port 80 is limited to the administrator's IP while phpMyAdmin is exposed.
