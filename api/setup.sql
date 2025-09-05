-- Comptes applicatifs
CREATE TABLE IF NOT EXISTS `user` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `role` ENUM('admin','manager','employee') DEFAULT 'employee',
  `employee_id` VARCHAR(30) DEFAULT NULL COMMENT 'Lien logique vers employee.userid',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `last_login` DATETIME DEFAULT NULL,
  KEY `employee_id` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Paramètres d’application (logo, thèmes, etc.)
CREATE TABLE IF NOT EXISTS `app_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `k` VARCHAR(100) NOT NULL UNIQUE,
  `v` TEXT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Planification des rapports
CREATE TABLE IF NOT EXISTS `report_schedule` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `type` ENUM('daily','weekly','bi-weekly','semi-monthly','monthly','custom') NOT NULL,
  `anchor_date` DATE DEFAULT NULL COMMENT 'Point de départ pour bi-weekly (et weekly si besoin)',
  `start_date` DATE DEFAULT NULL COMMENT 'Utilisé quand type=custom',
  `end_date` DATE DEFAULT NULL COMMENT 'Utilisé quand type=custom',
  `day_of_week` TINYINT DEFAULT NULL COMMENT '1=Lundi ... 7=Dimanche (weekly)',
  `day_of_month` TINYINT DEFAULT NULL COMMENT 'Monthly: jour; Semi-monthly: ignoré (1–15 et 16–fin)',
  `time_of_day` TIME DEFAULT '06:00:00' COMMENT 'Heure locale d\'exécution',
  `email_subject` VARCHAR(200) DEFAULT 'Meal Report',
  `email_body` TEXT DEFAULT NULL,
  `email_enabled` TINYINT(1) DEFAULT 0,
  `format` ENUM('csv','xlsx','pdf','json') DEFAULT 'csv',
  `next_run` DATETIME DEFAULT NULL,
  `last_run` DATETIME DEFAULT NULL,
  `created_by` INT DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Destinataires email par planification
CREATE TABLE IF NOT EXISTS `report_schedule_recipient` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `schedule_id` INT NOT NULL,
  `email` VARCHAR(200) NOT NULL,
  `name` VARCHAR(100) DEFAULT NULL,
  KEY `schedule_id` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Historique d\'exécution des rapports
CREATE TABLE IF NOT EXISTS `report_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `schedule_id` INT DEFAULT NULL,
  `period_start` DATE NOT NULL,
  `period_end` DATE NOT NULL,
  `format` VARCHAR(10) DEFAULT 'csv',
  `file_path` VARCHAR(500) DEFAULT NULL,
  `status` ENUM('success','error','skipped') DEFAULT 'success',
  `error_message` TEXT DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  KEY `schedule_id` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
