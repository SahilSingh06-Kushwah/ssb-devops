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
