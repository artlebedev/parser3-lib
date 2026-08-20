/*==============================================================*/
/* Database name:  engine                                       */
/* DBMS name:      MySQL 3.23                                   */
/* Created on:     02.03.2005 13:44:39                          */
/*==============================================================*/


drop table if exists acl;

drop table if exists aevent_log;

drop table if exists asession;

drop table if exists auser;

drop table if exists auser_to_auser;

/*==============================================================*/
/* Table: acl                                                   */
/*==============================================================*/
/* назначеные на объект права */
create table if not exists acl
(
   object_id                      INTEGER UNSIGNED               not null default 0,
   auser_id                       INTEGER UNSIGNED               not null default 0,
   rights                         INTEGER UNSIGNED               not null default 0,
   unique (auser_id, object_id)
);

/* object_id - связка с объектом */;

/* rights - младший байт - права на объект, старший - на свойства. */;

/*==============================================================*/
/* Table: aevent_log                                            */
/*==============================================================*/
/*  */
create table if not exists aevent_log
(
   aevent_log_id                  INTEGER UNSIGNED               not null AUTO_INCREMENT,
   auser_id                       INTEGER UNSIGNED               not null default 0,
   event_type                     MEDIUMINT                      not null default 256,
   stat                           MEDIUMINT                      not null,
   dt                             DATETIME                       not null,
   content                        VARCHAR(255),
   primary key (aevent_log_id)
);

/* auser_id - собственно про кого записываем */;

/* event_type - что за событие (описаны у auser) */;

/* stat - статус (например, пытались добавлять и ошибка) */;

/* dt - когда залогили */;

/* content - тут пишем что-то о событии... */;

/*==============================================================*/
/* Index: ix_aevent_log_0                                       */
/*==============================================================*/
create index ix_aevent_log_0 on aevent_log
(
   auser_id,
   dt
);

/*==============================================================*/
/* Table: asession                                              */
/*==============================================================*/
/* сессии, по которым отслеживается залогиненость */
create table if not exists asession
(
   asession_id                    INTEGER UNSIGNED               not null AUTO_INCREMENT,
   auser_id                       INTEGER UNSIGNED               not null default 0,
   sid                            VARCHAR(64)                    not null,
   auid                           VARCHAR(64)                    not null,
   dt_access                      DATETIME                       not null,
   dt_logon                       DATETIME,
   dt_logout                      DATETIME,
   primary key (asession_id)
);

/* sid - кука, выдающаяся на сессию */;

/* auid - кука, выдающаяся на постоянку */;

/* dt_access - время последнего доступа */;

/* dt_logon - время последнего логина */;

/* dt_logout - время последнего логаута */;

/*==============================================================*/
/* Index: ix_asession_0                                         */
/*==============================================================*/
create index ix_asession_0 on asession
(
   auser_id
);

/*==============================================================*/
/* Index: ix_asession_1                                         */
/*==============================================================*/
create index ix_asession_1 on asession
(
   auid,
   dt_access
);

/*==============================================================*/
/* Index: ix_asession_2                                         */
/*==============================================================*/
create index ix_asession_2 on asession
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
create table if not exists auser
(
   auser_id                       INTEGER UNSIGNED               not null AUTO_INCREMENT,
   auser_type_id                  TINYINT UNSIGNED               not null default 0,
   rights                         INTEGER UNSIGNED               not null default 0,
   name                           VARCHAR(127)                   not null,
   description                    TEXT,
   email                          VARCHAR(63)                    not null,
   passwd                         VARCHAR(63)                    not null,
   new_passwd                     VARCHAR(63),
   dt_register                    DATETIME                       not null,
   dt_logon                       DATETIME,
   dt_logout                      DATETIME,
   is_published                   TINYINT UNSIGNED               not null default 1,
   is_default                     TINYINT UNSIGNED               not null default 0,
   connections_limit              TINYINT UNSIGNED               not null default 1,
   event_type                     MEDIUMINT UNSIGNED             not null default 0,
   primary key (auser_id),
   unique (auser_type_id, name)
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

/* is_default - для групп. если установлена в 1 то новый пользователь включается в группу */;

/* connections_limit - количество одновременных подключений */;

/* event_type - битовая маска, что записываем в лог */;

/*==============================================================*/
/* Index: ix_auser_0                                            */
/*==============================================================*/
create index ix_auser_0 on auser
(
   auser_type_id,
   is_published,
   dt_logon
);

/*==============================================================*/
/* Index: ix_auser_1                                            */
/*==============================================================*/
create index ix_auser_1 on auser
(
   dt_register
);

/*==============================================================*/
/* Index: ix_auser_2                                            */
/*==============================================================*/
create index ix_auser_2 on auser
(
   auser_type_id,
   name,
   passwd
);

/*==============================================================*/
/* Index: ix_auser_3                                            */
/*==============================================================*/
create index ix_auser_3 on auser
(
   auser_type_id,
   email,
   name
);

/*==============================================================*/
/* Table: auser_to_auser                                        */
/*==============================================================*/
/* принадлежность пользователя группе
   
   rights (права пользователя на группу):
   0 - User
   1 - Supervisory (может включать в группу кого угодно)
   2 - Remove self (а надо?) */
create table if not exists auser_to_auser
(
   auser_id                       INTEGER UNSIGNED               not null default 0,
   parent_id                      INTEGER UNSIGNED               not null default 0,
   rights                         INTEGER UNSIGNED               not null default 0
);

/* auser_id - кто (ссылка на пользователя) */;

/* parent_id - в какую группу включен (ссылка на группу) */;

/* rights - права, с которые пользователь имеет на группу */;

/*==============================================================*/
/* Index: ix_auser_to_auser_0                                   */
/*==============================================================*/
create unique index ix_auser_to_auser_0 on auser_to_auser
(
   auser_id,
   parent_id
);



/*==============================================================*/
/* Insert default data		                                    */
/*==============================================================*/
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (1, 'Owner', 'onwner', 'owner', 'Владелец объектов', 2, 16777215, 1, NOW());
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (2, 'Admins', 'group', 'group', 'Все администрирующие пользователи', 1, 16777215, 1, NOW());
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (3, 'admin', 'admin', 'misha@design.ru', '', 0, 16777215, 1, NOW());
INSERT INTO auser_to_auser (auser_id, parent_id) VALUES (3,2);
