SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

CREATE TABLE IF NOT EXISTS alembic_version (
  version_num varchar(32) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO alembic_version (version_num) VALUES
('2a26731bd08e');

CREATE TABLE IF NOT EXISTS `comment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned DEFAULT NULL,
  proposal_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  generation int(10) unsigned DEFAULT NULL,
  created datetime DEFAULT NULL,
  `comment` text NOT NULL,
  comment_type enum('for','against','question','answer') NOT NULL,
  reply_to int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (id),
  KEY proposal_id (proposal_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS email_invite (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  sender_id int(10) unsigned DEFAULT NULL,
  receiver_email varchar(120) DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  permissions int(10) unsigned DEFAULT NULL,
  token varchar(32) DEFAULT NULL,
  email_sent tinyint(1) unsigned DEFAULT NULL,
  accepted tinyint(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY token (token),
  KEY sender_id (sender_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS endorsement (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  proposal_id int(10) unsigned DEFAULT NULL,
  generation int(10) unsigned NOT NULL,
  endorsement_date datetime DEFAULT NULL,
  endorsement_type enum('endorse','oppose','confused') DEFAULT NULL,
  mapx float DEFAULT NULL,
  mapy float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY user_id (user_id),
  KEY question_id (question_id),
  KEY proposal_id (proposal_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS finished_writing (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned NOT NULL,
  question_id int(10) unsigned NOT NULL,
  generation int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY fk_finished_writing_user (user_id),
  KEY fk_finished_writing_question (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS invite (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  sender_id int(10) unsigned DEFAULT NULL,
  receiver_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  permissions int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY sender_id (sender_id),
  KEY receiver_id (receiver_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS key_player (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned DEFAULT NULL,
  proposal_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  generation int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY user_id (user_id),
  KEY proposal_id (proposal_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS proposal (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  title varchar(120) NOT NULL,
  blurb text NOT NULL,
  abstract text NOT NULL,
  image varchar(150) NOT NULL,
  generation_created int(10) unsigned DEFAULT NULL,
  created datetime DEFAULT NULL,
  source int(10) unsigned DEFAULT NULL,
  user_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  geomedx float DEFAULT NULL,
  geomedy float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY user_id (user_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS pwd_reset (
  user_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  email varchar(120) DEFAULT NULL,
  token varchar(32) DEFAULT NULL,
  timeout int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (user_id),
  UNIQUE KEY email (email),
  UNIQUE KEY token (token)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS question (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  title varchar(120) NOT NULL,
  blurb text NOT NULL,
  generation int(10) unsigned NOT NULL,
  room varchar(30) DEFAULT NULL,
  phase enum('writing','voting','archived','consensus','results') DEFAULT NULL,
  question_type_id int(10) unsigned NOT NULL,
  voting_type_id int(10) unsigned NOT NULL,
  created int(10) unsigned DEFAULT NULL,
  last_move_on int(10) unsigned DEFAULT NULL,
  minimum_time int(10) unsigned DEFAULT NULL,
  maximum_time int(10) unsigned DEFAULT NULL,
  user_id int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY fk_quesion_question_types (question_type_id),
  KEY fk_quesion_voting_types (voting_type_id),
  KEY user_id (user_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS question_history (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  proposal_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  generation int(10) unsigned DEFAULT NULL,
  dominated_by int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY proposal_id (proposal_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS question_types (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(25) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO question_types (id, name) VALUES
(1, 'standard'),
(2, 'image');

CREATE TABLE IF NOT EXISTS threshold (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  question_id int(10) unsigned DEFAULT NULL,
  generation int(10) unsigned DEFAULT NULL,
  mapx float DEFAULT NULL,
  mapy float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY question_id (question_id)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `update` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned DEFAULT NULL,
  how enum('daily','weekly','asap') DEFAULT NULL,
  last_update datetime DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY user_id (user_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS user (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  username varchar(20) NOT NULL,
  email varchar(120) DEFAULT NULL,
  password varchar(120) NOT NULL,
  registered datetime DEFAULT NULL,
  last_seen datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY username (username),
  UNIQUE KEY email (email)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS user_comments (
  user_id int(10) unsigned DEFAULT NULL,
  comment_id int(10) unsigned DEFAULT NULL,
  KEY user_id (user_id),
  KEY comment_id (comment_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS user_invite (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  sender_id int(10) unsigned DEFAULT NULL,
  receiver_id int(10) unsigned DEFAULT NULL,
  question_id int(10) unsigned DEFAULT NULL,
  permissions int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY sender_id (sender_id),
  KEY receiver_id (receiver_id),
  KEY question_id (question_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS verify_email (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned DEFAULT NULL,
  email varchar(120) DEFAULT NULL,
  token varchar(32) DEFAULT NULL,
  email_sent tinyint(1) unsigned DEFAULT NULL,
  timeout int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY token (token),
  KEY user_id (user_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS voting_types (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(25) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO voting_types (`id`, name) VALUES
(1, 'triangle'),
(2, 'linear');
