/*==============================================================*/
/* Database name:  engine                                       */
/* DBMS name:      Microsoft SQL Server 2000                    */
/* Created on:     01.03.2005 22:01:40                          */
/*==============================================================*/


IF EXISTS (SELECT 1 FROM  sysobjects WHERE id = object_id('acl') AND type = 'U') DROP TABLE acl
GO

IF EXISTS (SELECT 1 FROM  sysobjects WHERE id = object_id('aevent_log') AND type = 'U') DROP TABLE aevent_log
GO

IF EXISTS (SELECT 1 FROM  sysobjects WHERE id = object_id('asession') AND type = 'U') DROP TABLE asession
GO

IF EXISTS (SELECT 1 FROM  sysobjects WHERE id = object_id('auser') AND type = 'U') DROP TABLE auser
GO

IF EXISTS (SELECT 1 FROM  sysobjects WHERE id = object_id('auser_to_auser') AND type = 'U') DROP TABLE auser_to_auser
GO


/*==============================================================*/
/* Table: acl                                                   */
/*==============================================================*/
CREATE TABLE acl (
   object_id            INTEGER                  NOT NULL DEFAULT 0,
   auser_id             INTEGER                  NOT NULL DEFAULT 0,
   rights               INTEGER                  NOT NULL DEFAULT 0,
   CONSTRAINT AK_KEY_1_ACL UNIQUE (auser_id, object_id)
)
GO


/*==============================================================*/
/* Table: aevent_log                                            */
/*==============================================================*/
CREATE TABLE aevent_log (
   aevent_log_id        INTEGER                  IDENTITY,
   auser_id             INTEGER                  NOT NULL DEFAULT 0,
   event_type           INTEGER                  NOT NULL DEFAULT 256,
   stat                 INTEGER                  NOT NULL,
   dt                   DATETIME                 NOT NULL,
   content              VARCHAR(255)             NULL,
   CONSTRAINT PK_AEVENT_LOG PRIMARY KEY  (aevent_log_id)
)
GO


/*==============================================================*/
/* Index: ix_aevent_log_0                                       */
/*==============================================================*/
CREATE INDEX ix_aevent_log_0 ON aevent_log (
	auser_id,
	dt
)
GO


/*==============================================================*/
/* Table: asession                                              */
/*==============================================================*/
CREATE TABLE asession (
   asession_id          INTEGER                  IDENTITY,
   auser_id             INTEGER                  NOT NULL DEFAULT 0,
   sid                  VARCHAR(64)              NOT NULL,
   auid                 VARCHAR(64)              NOT NULL,
   dt_access            DATETIME                 NOT NULL,
   dt_logon             DATETIME                 NULL,
   dt_logout            DATETIME                 NULL,
   CONSTRAINT PK_ASESSION PRIMARY KEY  (asession_id)
)
GO


/*==============================================================*/
/* Index: ix_asession_0                                         */
/*==============================================================*/
CREATE INDEX ix_asession_0 ON asession (
	auser_id
)
GO


/*==============================================================*/
/* Index: ix_asession_1                                         */
/*==============================================================*/
CREATE INDEX ix_asession_1 ON asession (
	auid,
	dt_access
)
GO


/*==============================================================*/
/* Index: ix_asession_2                                         */
/*==============================================================*/
CREATE INDEX ix_asession_2 ON asession (
	dt_access
)
GO


/*==============================================================*/
/* Table: auser                                                 */
/*==============================================================*/
CREATE TABLE auser (
   auser_id             INTEGER                  IDENTITY,
   auser_type_id        TINYINT                  NOT NULL DEFAULT 0,
   rights               INTEGER                  NOT NULL DEFAULT 0,
   name                 VARCHAR(127)             NOT NULL,
   description          TEXT                     NULL,
   email                VARCHAR(63)              NOT NULL,
   passwd               VARCHAR(63)              NOT NULL,
   new_passwd           VARCHAR(63)              NULL,
   dt_register          DATETIME                 NOT NULL,
   dt_logon             DATETIME                 NULL,
   dt_logout            DATETIME                 NULL,
   is_published         TINYINT                  NOT NULL DEFAULT 1,
   is_default           TINYINT                  NOT NULL DEFAULT 0,
   connections_limit    TINYINT                  NOT NULL DEFAULT 1,
   event_type           INTEGER                  NOT NULL DEFAULT 0,
   CONSTRAINT PK_AUSER PRIMARY KEY  (auser_id),
   CONSTRAINT AK_KEY_2_AUSER UNIQUE (auser_type_id, name)
)
GO


/*==============================================================*/
/* Index: ix_auser_0                                            */
/*==============================================================*/
CREATE INDEX ix_auser_0 ON auser (
	auser_type_id,
	is_published,
	dt_logon
)
GO


/*==============================================================*/
/* Index: ix_auser_1                                            */
/*==============================================================*/
CREATE INDEX ix_auser_1 ON auser (
	dt_register
)
GO


/*==============================================================*/
/* Index: ix_auser_2                                            */
/*==============================================================*/
CREATE INDEX ix_auser_2 ON auser (
	auser_type_id,
	name,
	passwd
)
GO


/*==============================================================*/
/* Index: ix_auser_3                                            */
/*==============================================================*/
CREATE INDEX ix_auser_3 ON auser (
	auser_type_id,
	email,
	name
)
GO


/*==============================================================*/
/* Table: auser_to_auser                                        */
/*==============================================================*/
CREATE TABLE auser_to_auser (
   auser_id             INTEGER                  NOT NULL DEFAULT 0,
   parent_id            INTEGER                  NOT NULL DEFAULT 0,
   rights               INTEGER                  NOT NULL DEFAULT 0
)
GO


/*==============================================================*/
/* Index: ix_auser_to_auser_0                                   */
/*==============================================================*/
CREATE UNIQUE INDEX ix_auser_to_auser_0 ON auser_to_auser (
	auser_id,
	parent_id
)
GO




/*==============================================================*/
/* Insert DEFAULT data		                                    */
/*==============================================================*/
SET IDENTITY_INSERT auser ON;
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (1, 'Owner', 'onwner', 'owner', 'Владелец объектов', 2, 16777215, 1, GETDATE());
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (2, 'Admins', 'group', 'group', 'Все администрирующие пользователи', 1, 16777215, 1, GETDATE());
INSERT INTO auser (auser_id, name, passwd, email, description, auser_type_id, rights, is_published, dt_register) VALUES (3, 'admin', 'admin', 'misha@design.ru', '', 0, 16777215, 1, GETDATE());
INSERT INTO auser_to_auser (auser_id, parent_id) VALUES (3,2);
SET IDENTITY_INSERT auser OFF;
GO
