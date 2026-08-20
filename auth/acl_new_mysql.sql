DROP TABLE acl;

CREATE TABLE acl (
	auser_id INTEGER UNSIGNED NOT NULL,
	rights INTEGER UNSIGNED NOT NULL,
	referer_id INTEGER UNSIGNED NOT NULL,
	referer_type VARCHAR(31) NOT NULL,
	PRIMARY KEY (referer_id, auser_id, referer_type)
);


DROP TABLE rights;

CREATE TABLE rights (
	rights_id INTEGER UNSIGNED NOT NULL PRIMARY KEY,
	name VARCHAR(127) NOT NULL,
	name_short VARCHAR(2) NOT NULL,
	description VARCHAR(255) DEFAULT NULL,
	rights_type_id INTEGER UNSIGNED NOT NULL DEFAULT 0
);

INSERT INTO rights (rights_id, name, name_short, rights_type_id) VALUES (512,'Read','R',1);
INSERT INTO rights (rights_id, name, name_short, rights_type_id) VALUES (2048,'Write','W',1);
