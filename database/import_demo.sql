-- Demo file for the phpMyAdmin import task
USE ssb_app;

CREATE TABLE IF NOT EXISTS departments (
  id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  hod  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO departments (name, hod) VALUES
  ('Information Technology', 'Dr. A. Sharma'),
  ('Computer Engineering',   'Dr. B. Trivedi'),
  ('Electronics',            'Dr. C. Parmar');
