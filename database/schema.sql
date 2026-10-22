-- Schema for the SSB Digital demo app
CREATE DATABASE IF NOT EXISTS ssb_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ssb_app;

CREATE TABLE IF NOT EXISTS students (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100) NOT NULL,
  college    VARCHAR(150) NOT NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;
