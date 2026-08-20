/*==============================================================*/
/* DBMS name:      PostgreSQL 7.3.2                                   */
/* Created on:     13.06.2003                          */
/*==============================================================*/

/*==============================================================*/
/* Table: acl                                                   */
/*==============================================================*/
/* назначеные на объект права */

CREATE TABLE acl
(
   object_id                      INT                        NOT NULL DEFAULT 0,
   auser_id                       INT                        NOT NULL DEFAULT 0,
   rights                         INT                        NOT NULL DEFAULT 0
);


/* object_id - связка с объектом */;

/* rights - младший байт - права на объект, старший - на свойства. */;

/*==============================================================*/
/* Index: ix_acl_0                                   */
/*==============================================================*/
CREATE UNIQUE INDEX ix_acl_0 ON acl
(
   object_id,
   auser_id
);


/*==============================================================*/
/* Table: aevent_log                                            */
/*==============================================================*/
CREATE TABLE aevent_log
(
	aevent_log_id SERIAL NOT NULL,
	auser_id INT NOT NULL DEFAULT 0,
	event_type INT NOT NULL DEFAULT 256,
	stat INT NOT NULL,
	dt TIMESTAMP NOT NULL,
	content VARCHAR(255),
	PRIMARY KEY (aevent_log_id)
);

/* auser_id - собственно про кого записываем */;

/* event_type - что за событие (описаны у auser) */;

/* stat - статус (например, пытались добавлять и ошибка) */;

/* dt - когда залогили */;

/* content - тут пишем что-то о событии... */;

/*==============================================================*/
/* Index: ix_aevent_log_0                                       */
/*==============================================================*/
CREATE INDEX ix_aevent_log_0 ON aevent_log
(
   auser_id,
   dt
);

/*==============================================================*/
/* Table: asession                                              */
/*==============================================================*/
/* сессии, по которым отслеживается залогиненость */
CREATE TABLE asession
(
	asession_id SERIAL NOT NULL,
	auser_id INT NOT NULL DEFAULT 0,
	sid VARCHAR(64) NOT NULL,
	auid VARCHAR(64) NOT NULL,
	dt_access TIMESTAMP NOT NULL,
	dt_logon TIMESTAMP,
	dt_logout TIMESTAMP,
	PRIMARY KEY (asession_id)
);

/* sid - кука, выдающаяся на сессию */;

/* auid - кука, выдающаяся на постоянку */;

/* dt_access - время последнего доступа */;

/* dt_logon - время последнего логина */;

/* dt_logout - время последнего логаута */;

/*==============================================================*/
/* Index: ix_asession_0                                         */
/*==============================================================*/
CREATE INDEX ix_asession_0 ON asession
(
   auser_id
);

/*==============================================================*/
/* Index: ix_asession_1                                         */
/*==============================================================*/
CREATE INDEX ix_asession_1 ON asession
(
   auid,
   dt_access
);

/*==============================================================*/
/* Index: ix_asession_2                                         */
/*==============================================================*/
CREATE INDEX ix_asession_2 ON asession
(
   dt_access
);

/*==============================================================*/
/* Table: auser                                                 */
/*==============================================================*/
/* пользователи и группы
   есть такая фигня как owner (auser_type_id = 3)
   его права меньше, чем права пользователя и права группы.
   т.е. если пользователю/группе назначены права то мы не смотрим на овнера, 
   если не назначены - смотрим, он-ли овнер, и если он - берем эти права.
   event_type - что записываем, битовая маска:
   1 - логин, 
   2 - логаут, 
   8 - смена пароля, 
   4 - request_password, 
   16 - смена имени, 
   32 - смена email, 
   64 - изменение прав пользователю, 
   128 - изменение пользователя, 
   256 - добавление пользователя
   ... потом дальше придумаю */
CREATE TABLE auser
(
	auser_id SERIAL NOT NULL,
	auser_type_id INT NOT NULL DEFAULT 0,
	rights INT NOT NULL DEFAULT 0,
	name VARCHAR(127) NOT NULL,
	description TEXT,
	email VARCHAR(63) NOT NULL,
	passwd VARCHAR(63) NOT NULL,
	new_passwd VARCHAR(63),
	dt_register TIMESTAMP NOT NULL,
	dt_logon TIMESTAMP,
	dt_logout TIMESTAMP,
	is_published INT NOT NULL DEFAULT 1,
	is_default INT NOT NULL DEFAULT 0,
	connections_limit INT NOT NULL DEFAULT 1,
	event_type INT NOT NULL DEFAULT 0,
	PRIMARY KEY (auser_id),
	UNIQUE (auser_type_id, name)
);

/* auser_type_id - тип пользователя (0 - пользователь, 1 - группа) */;

/* rights - права пользователя/группы на корень дерева */;

/* name - имя для подключения */;

/* description - описание (например для группы) */;

/* email - email пользователя */;

/* passwd - пароль */;

/* new_passwd - новый пароль (если забыли, генериться и живет пока не подтвердят) */;

/* dt_register - дата/время регистрации */;

/* dt_logon - дата/время последнего логина */;

/* dt_logout - дата/время последнего логаута */;

/* is_published - разрешен доступ или нет */;

/* is_default - для групп. если установлена в 1 то добавляемый пользователь включается в группу */;

/* connections_limit - количество одновременных подключений */;

/* event_type - битовая маска, что записываем в лог */;

/*==============================================================*/
/* Index: ix_auser_0                                            */
/*==============================================================*/
CREATE INDEX ix_auser_0 ON auser
(
   auser_type_id,
   is_published,
   dt_logon
);

/*==============================================================*/
/* Index: ix_auser_1                                            */
/*==============================================================*/
CREATE INDEX ix_auser_1 ON auser
(
   dt_register
);

/*==============================================================*/
/* Index: ix_auser_2                                            */
/*==============================================================*/
CREATE INDEX ix_auser_2 ON auser
(
   auser_type_id,
   name,
   passwd
);

/*==============================================================*/
/* Index: ix_auser_3                                            */
/*==============================================================*/
CREATE INDEX ix_auser_3 ON auser
(
   auser_type_id,
   email,
   name
);


/*==============================================================*/
/* Table: auser_to_auser                                        */
/*==============================================================*/
/* принадлежность пользователя группе */
CREATE TABLE auser_to_auser
(
	auser_id INT NOT NULL DEFAULT 0,
	parent_id INT NOT NULL DEFAULT 0,
	rights INT NOT NULL DEFAULT 0
);
/* auser_id - кто (ссылка на пользователя) */;

/* parent_id - в какую группу включен (ссылка на группу) */;

/* rights - права, с которые пользователь имеет на группу */;


/*==============================================================*/
/* Index: ix_auser_to_auser_0                                   */
/*==============================================================*/
CREATE UNIQUE INDEX ix_auser_to_auser_0 ON auser_to_auser
(
   auser_id,
   parent_id
);



/*==============================================================*/
/* Insert DEFAULT data		                                    */
/*==============================================================*/
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (1, 'Owner', 'onwner', 'owner', 'Владелец объектов', 2, 16777215, 1, CURRENT_TIMESTAMP);
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (2, 'Admins', 'group', 'group', 'Все администрирующие пользователи', 1, 16777215, 1, CURRENT_TIMESTAMP);
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (3, 'admin', 'admin', 'misha@design.ru', '', 0, 16777215, 1, CURRENT_TIMESTAMP);
INSERT INTO auser_to_auser (auser_id, parent_id) VALUES (3,2);
