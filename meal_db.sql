/*
SQLyog Community v13.3.0 (64 bit)
MySQL - 5.7.42-log : Database - meal_db
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`meal_db` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `meal_db`;

/*Table structure for table `company` */

DROP TABLE IF EXISTS `company`;

CREATE TABLE `company` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CompanyName` varchar(100) DEFAULT NULL COMMENT 'Nom officiel de l''entreprise',
  `Email` varchar(50) DEFAULT NULL COMMENT 'Adresse email principale de contact',
  `Address1` longtext COMMENT 'Adresse postale (ligne 1)',
  `Address2` longtext COMMENT 'Adresse postale (ligne 2 - complément)',
  `City` varchar(100) DEFAULT NULL COMMENT 'Ville',
  `Zip` varchar(50) DEFAULT NULL COMMENT 'Code postal',
  `State` varchar(100) DEFAULT NULL COMMENT 'État/Région',
  `Country` varchar(50) DEFAULT NULL COMMENT 'Pays',
  `ContactP` longtext COMMENT 'Personne à contacter',
  `phone` varchar(20) DEFAULT NULL COMMENT 'Numéro de téléphone principal',
  PRIMARY KEY (`id`)
) ENGINE=FEDERATED DEFAULT CHARSET=utf8 CONNECTION='mysql://ingress:ingress@127.0.0.1:3306/ingress/systemsetting_company';

/*Table structure for table `employee` */

DROP TABLE IF EXISTS `employee`;

CREATE TABLE `employee` (
  `userid` varchar(30) NOT NULL COMMENT 'Identifiant unique de l''employé',
  `Username` varchar(45) DEFAULT NULL COMMENT 'Nom complet de l''employé',
  `Address` varchar(200) DEFAULT NULL COMMENT 'Adresse personnelle',
  `Phone` varchar(20) DEFAULT NULL COMMENT 'Numéro de téléphone personnel',
  `Email` varchar(50) DEFAULT NULL COMMENT 'Adresse email personnelle',
  `User_Group` int(11) DEFAULT '0' COMMENT 'Référence au département (clé étrangère vers user_group.id)',
  `Gender` tinytext COMMENT 'Genre',
  `IssueDate` date DEFAULT '2012-01-01' COMMENT 'Date d''embauche',
  `expirydate` date DEFAULT '2029-12-31' COMMENT 'Date de fin de contrat',
  `SuspendedDate` datetime DEFAULT NULL COMMENT 'Date de suspension si applicable',
  PRIMARY KEY (`userid`),
  KEY `User_Group` (`User_Group`)
) ENGINE=FEDERATED DEFAULT CHARSET=utf8 CONNECTION='mysql://ingress:ingress@127.0.0.1:3306/ingress/user';

/*Table structure for table `employee_meal_rate` */

DROP TABLE IF EXISTS `employee_meal_rate`;

CREATE TABLE `employee_meal_rate` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` varchar(30) NOT NULL COMMENT 'Lien logique vers employee.userid',
  `workcode` int(11) NOT NULL COMMENT 'Type de repas',
  `custom_rate` decimal(10,2) DEFAULT NULL COMMENT 'Tarif personnalisé',
  `custom_limit` int(11) DEFAULT NULL COMMENT 'Limite personnalisée',
  `custom_rate_after_limit` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `employee_portal` */

DROP TABLE IF EXISTS `employee_portal`;

CREATE TABLE `employee_portal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` varchar(30) NOT NULL COMMENT 'Lien vers employee.userid',
  `month_year` varchar(7) NOT NULL COMMENT 'Format YYYY-MM',
  `meals_taken` int(11) DEFAULT '0' COMMENT 'Nombre total de repas consommés',
  `meals_limit` int(11) DEFAULT '0' COMMENT 'Limite pour le mois',
  `deductions` decimal(10,2) DEFAULT '0.00' COMMENT 'Montant déduit',
  `last_update` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `userid` (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `logs` */

DROP TABLE IF EXISTS `logs`;

CREATE TABLE `logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_admin` varchar(50) NOT NULL COMMENT 'Admin ayant fait la modification',
  `action` varchar(255) NOT NULL COMMENT 'Ex: Update meal_setting',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `meal` */

DROP TABLE IF EXISTS `meal`;

CREATE TABLE `meal` (
  `workcode` int(11) NOT NULL DEFAULT '0' COMMENT 'Code unique du repas',
  `remark` varchar(200) DEFAULT NULL COMMENT 'Nom/description du repas',
  PRIMARY KEY (`workcode`)
) ENGINE=FEDERATED DEFAULT CHARSET=utf8 CONNECTION='mysql://ingress:ingress@127.0.0.1:3306/ingress/remark';

/*Table structure for table `meal_cons` */

DROP TABLE IF EXISTS `meal_cons`;

CREATE TABLE `meal_cons` (
  `userid` varchar(45) DEFAULT NULL COMMENT 'Référence à l''employé (employee.userid)',
  `checktime` datetime DEFAULT NULL COMMENT 'Date et heure de prise du repas',
  `workcode` int(11) DEFAULT NULL COMMENT 'Type de repas (référence à meal.workcode)',
  KEY `userid` (`userid`),
  KEY `workcode` (`workcode`)
) ENGINE=FEDERATED DEFAULT CHARSET=utf8 CONNECTION='mysql://ingress:ingress@127.0.0.1:3306/ingress/device_transaction_log';

/*Table structure for table `meal_salary` */

DROP TABLE IF EXISTS `meal_salary`;

CREATE TABLE `meal_salary` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` varchar(30) NOT NULL COMMENT 'Lien logique vers employee.userid',
  `month_year` varchar(7) NOT NULL COMMENT 'Format YYYY-MM',
  `total_meals` int(11) DEFAULT '0',
  `total_deduction` decimal(10,2) DEFAULT '0.00',
  `breakdown` json DEFAULT NULL COMMENT 'Détail par repas (01,02,03,04)',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `meal_setting` */

DROP TABLE IF EXISTS `meal_setting`;

CREATE TABLE `meal_setting` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workcode` int(11) NOT NULL COMMENT 'Lien logique vers meal.workcode',
  `rate_meal` decimal(10,2) NOT NULL COMMENT 'Tarif normal',
  `meal_limit` int(11) DEFAULT '0' COMMENT 'Nombre maximum de repas autorisés',
  `rate_after_limit` decimal(10,2) DEFAULT '0.00' COMMENT 'Tarif si dépassement',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `report_schedule` */

DROP TABLE IF EXISTS `report_schedule`;

CREATE TABLE `report_schedule` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT 'Nom du rapport (ex: Déduction repas)',
  `type` enum('daily','weekly','bi-weekly','semi-monthly','monthly','custom') NOT NULL COMMENT 'Fréquence du rapport',
  `start_date` date DEFAULT NULL COMMENT 'Date de début (utile pour custom)',
  `end_date` date DEFAULT NULL COMMENT 'Date de fin (utile pour custom)',
  `day_of_week` tinyint(4) DEFAULT NULL COMMENT 'Si weekly: 1=Mon ... 7=Sun',
  `day_of_month` tinyint(4) DEFAULT NULL COMMENT 'Si monthly/semi-monthly: jour de génération',
  `next_run` datetime DEFAULT NULL COMMENT 'Prochaine exécution planifiée',
  `last_run` datetime DEFAULT NULL COMMENT 'Dernière exécution',
  `created_by` int(11) DEFAULT NULL COMMENT 'Lien vers user.id (qui a créé)',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `user` */

DROP TABLE IF EXISTS `user`;

CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL COMMENT 'Identifiant de connexion',
  `password` varchar(255) NOT NULL COMMENT 'Mot de passe haché (bcrypt)',
  `email` varchar(100) DEFAULT NULL COMMENT 'Email de récupération',
  `role` enum('admin','manager','employee') DEFAULT 'employee' COMMENT 'Droits d’accès',
  `employee_id` varchar(30) DEFAULT NULL COMMENT 'Lien optionnel avec employee.userid',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `employee_id` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `user_group` */

DROP TABLE IF EXISTS `user_group`;

CREATE TABLE `user_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gName` varchar(200) DEFAULT NULL COMMENT 'Nom du département',
  PRIMARY KEY (`id`)
) ENGINE=FEDERATED DEFAULT CHARSET=utf8 CONNECTION='mysql://ingress:ingress@127.0.0.1:3306/ingress/user_group';

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
