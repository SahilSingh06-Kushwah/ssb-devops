# SSB Digital - DevOps Take-Home Assignment

Small Core PHP + MySQL app (student name / college records) deployed on Ubuntu 24.04 (EC2).

> README is built up step by step as the assignment progresses.

## Layout

```
app/          PHP source (index.php, edit.php, health.php, bootstrap.php)
database/     schema.sql, sample_data.sql, create_app_user.sql.example
scripts/      deploy.sh, backup.sh (added in later steps)
docs/         incident note, command notes
screenshots/  evidence
.env.example  config template (real .env is never committed)
```

## A. Stack (Ubuntu 24.04)

- Apache 2.4, PHP 8.3, MySQL 8.0, phpMyAdmin
- Services: `sudo systemctl start|stop|status apache2 mysql`
- Ports: Apache 80, MySQL 3306 (localhost only)
- Logs: `/var/log/apache2/error.log`, `/var/log/mysql/error.log`, PHP config `/etc/php/8.3/apache2/php.ini`

## B. Application

- `index.php`: lists records and creates a new one
- `edit.php`: updates an existing record
- `health.php`: returns 200 when PHP and the database both work
- DB settings come from `/etc/ssb-app/.env` (server) or `<repo>/.env` (local), never from the source code

## C. MySQL and phpMyAdmin

- Database `ssb_app`, table `students` (`database/schema.sql`, `database/sample_data.sql`)
- App user `ssb_user`: SELECT, INSERT, UPDATE, DELETE on `ssb_app.*` only (never root)
- phpMyAdmin import: ssb_app -> Import -> `database/import_demo.sql` (creates `departments`)
- phpMyAdmin export: ssb_app -> Export -> Custom -> SQL

| Statement | What it does |
|---|---|
| SELECT | Reads rows without changing them |
| INSERT | Adds a new row |
| UPDATE ... WHERE | Changes matching rows (without WHERE it changes every row) |
| DELETE ... WHERE | Removes matching rows (without WHERE it empties the table) |

## D. Deployment with rsync

Source `app/`, target `/var/www/html/ssb-app/`. Always dry-run first:

    sudo rsync -avhi --dry-run --delete --chown=root:www-data --chmod=D755,F644 \
      --exclude='.git' --exclude='.env' --exclude='*.log' --exclude='backups/' \
      app/ /var/www/html/ssb-app/

Run the same command without `--dry-run` to deploy. Excluded items (`.git`, `.env`, logs, backups)
never reach the server. A second run transfers nothing; after a change only that file is sent.

## E. Release flow

    ./scripts/deploy.sh --dry-run   # validate + preview
    ./scripts/deploy.sh             # validate, preview, confirm, deploy, health check

The script stops with a clear message if rsync, the source files, or the config file
(`/etc/ssb-app/.env`) are missing, or if the DB password is still the placeholder.
