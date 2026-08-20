DROP TABLE IF EXISTS chat;

CREATE TABLE chat (
chat_id MEDIUMINT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
flags TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
sort_order MEDIUMINT(8) UNSIGNED NOT NULL DEFAULT 0,
name VARCHAR(127) DEFAULT NULL,
PRIMARY KEY (chat_id),
KEY ix_chat_0 (flags, sort_order)
);


DROP TABLE IF EXISTS chat_activity;

CREATE TABLE chat_activity (
chat_id MEDIUMINT(8) UNSIGNED NOT NULL DEFAULT 0,
auser_id INTEGER UNSIGNED NOT NULL DEFAULT 0,
operation TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
dt DATETIME NOT NULL,
user_agent VARCHAR(127),
KEY ix_chat_activity_0 (chat_id, dt),
KEY ix_chat_activity_1 (auser_id),
KEY ix_chat_activity_2 (dt)
);


DROP TABLE IF EXISTS chat_message;

CREATE TABLE chat_message (
chat_message_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
chat_id MEDIUMINT(8) UNSIGNED NOT NULL DEFAULT 0,
auser_id INTEGER UNSIGNED NOT NULL DEFAULT 0,
to_id INTEGER UNSIGNED NOT NULL DEFAULT 0,
dt DATETIME NOT NULL,
body VARCHAR(255),
param VARCHAR(127),
PRIMARY KEY (chat_message_id),
KEY ix_chat_message_0 (chat_id, dt),
KEY ix_chat_message_1 (auser_id),
KEY ix_chat_message_2 (to_id, dt)
);