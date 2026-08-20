/*==============================================================*/
/* Database name:  mts2003                                      */
/* DBMS name:      ORACLE Version 9i                            */
/* Created on:     02.03.2005 14:44:43                          */
/*==============================================================*/


DROP TABLE "ACL" CASCADE CONSTRAINTS
/


DROP TABLE "AEVENT_LOG" CASCADE CONSTRAINTS
/


DROP TABLE "ASESSION" CASCADE CONSTRAINTS
/


DROP TABLE "AUSER" CASCADE CONSTRAINTS
/


DROP TABLE "AUSER_TO_AUSER" CASCADE CONSTRAINTS
/


DROP SEQUENCE "SEQ_AEVENT_LOG"
/


DROP SEQUENCE "SEQ_ASESSION"
/


DROP SEQUENCE "SEQ_AUSER"
/


CREATE SEQUENCE "SEQ_AEVENT_LOG"
INCREMENT BY 1
START WITH 1
/


CREATE SEQUENCE "SEQ_ASESSION"
INCREMENT BY 1
START WITH 1
/


CREATE SEQUENCE "SEQ_AUSER"
INCREMENT BY 1
START WITH 4
/


/*==============================================================*/
/* Table: "ACL"                                                   */
/*==============================================================*/
CREATE TABLE ACL (
   "OBJECT_ID"             NUMBER(10)                       DEFAULT 0 NOT NULL,
   "AUSER_ID"              NUMBER(10)                       DEFAULT 0 NOT NULL,
   "RIGHTS"                NUMBER(10)                       DEFAULT 0 NOT NULL,
   CONSTRAINT FK_ACL_REF_AUSER FOREIGN KEY (AUSER_ID) REFERENCES AUSER (AUSER_ID),
   CONSTRAINT FK_ACL_REF_OBJECT FOREIGN KEY (OBJECT_ID) REFERENCES OBJECT (OBJECT_ID)
)
/


/*==============================================================*/
/* Index: IX_ACL_0                                              */
/*==============================================================*/
CREATE UNIQUE INDEX IX_ACL_0 ON ACL (
   OBJECT_ID ASC,
   AUSER_ID ASC
)
/


/*==============================================================*/
/* Table: "AEVENT_LOG"                                          */
/*==============================================================*/


CREATE TABLE "AEVENT_LOG"  (
   "AEVENT_LOG_ID"      NUMBER(10)                   NOT NULL,
   "AUSER_ID"           NUMBER(10)                   DEFAULT 0  NOT NULL,
   "EVENT_TYPE"         NUMBER(10)                   DEFAULT 256  NOT NULL,
   "STAT"               NUMBER(10)                   NOT NULL,
   "DT"                 DATE                         NOT NULL,
   "CONTENT"            VARCHAR2(255),
   CONSTRAINT PK_AEVENT_LOG PRIMARY KEY ("AEVENT_LOG_ID")
)
/


/*==============================================================*/
/* Index: "IX_AEVENT_LOG_0"                                     */
/*==============================================================*/
CREATE INDEX "IX_AEVENT_LOG_0" ON "AEVENT_LOG" (
   "AUSER_ID" ASC,
   "DT" ASC
)
/


/*==============================================================*/
/* Table: "ASESSION"                                            */
/*==============================================================*/


CREATE TABLE "ASESSION"  (
   "ASESSION_ID"        NUMBER(10)                       NOT NULL,
   "AUSER_ID"           NUMBER(10)                       DEFAULT 0  NOT NULL,
   "SID"                VARCHAR2(64)                     NOT NULL,
   "AUID"               VARCHAR2(64)                     NOT NULL,
   "DT_ACCESS"          DATE                             NOT NULL,
   "DT_LOGON"           DATE,
   "DT_LOGOUT"          DATE,
   CONSTRAINT PK_ASESSION PRIMARY KEY ("ASESSION_ID")
)
/


/*==============================================================*/
/* Index: "IX_ASESSION_0"                                       */
/*==============================================================*/
CREATE INDEX "IX_ASESSION_0" ON "ASESSION" (
   "AUSER_ID" ASC
)
/


/*==============================================================*/
/* Index: "IX_ASESSION_1"                                       */
/*==============================================================*/
CREATE INDEX "IX_ASESSION_1" ON "ASESSION" (
   "AUID" ASC,
   "DT_ACCESS" DESC
)
/


/*==============================================================*/
/* Index: "IX_ASESSION_2"                                       */
/*==============================================================*/
CREATE INDEX "IX_ASESSION_2" ON "ASESSION" (
   "DT_ACCESS" ASC
)
/


/*==============================================================*/
/* Table: "AUSER"                                               */
/*==============================================================*/


CREATE TABLE "AUSER"  (
   "AUSER_ID"           NUMBER(10)                 NOT NULL,
   "AUSER_TYPE_ID"      NUMBER(3)                  DEFAULT 0  NOT NULL,
   "RIGHTS"             NUMBER(10)                 DEFAULT 0  NOT NULL,
   "NAME"               VARCHAR2(127)              NOT NULL,
   "DESCRIPTION"        CLOB,
   "EMAIL"              VARCHAR2(63)               NOT NULL,
   "PASSWD"             VARCHAR2(63)               NOT NULL,
   "NEW_PASSWD"         VARCHAR2(63),
   "DT_REGISTER"        DATE                       NOT NULL,
   "DT_LOGON"           DATE,
   "DT_LOGOUT"          DATE,
   "IS_PUBLISHED"       NUMBER(1)                  DEFAULT 1  NOT NULL,
   "IS_DEFAULT"         NUMBER(1)                  DEFAULT 0 NOT NULL,
   "CONNECTIONS_LIMIT"  NUMBER(3)                  DEFAULT 1  NOT NULL,
   "EVENT_TYPE"         NUMBER(10)                 DEFAULT 0  NOT NULL,
   CONSTRAINT PK_AUSER PRIMARY KEY ("AUSER_ID")
)
/


/*==============================================================*/
/* Index: "IX_AUSER_0"                                          */
/*==============================================================*/
CREATE INDEX "IX_AUSER_0" ON "AUSER" (
   "AUSER_TYPE_ID" ASC,
   "IS_PUBLISHED" ASC,
   "DT_LOGON" ASC
)
/


/*==============================================================*/
/* Index: "IX_AUSER_1"                                          */
/*==============================================================*/
CREATE INDEX "IX_AUSER_1" ON "AUSER" (
   "AUSER_TYPE_ID" ASC,
   "DT_REGISTER" DESC
)
/


/*==============================================================*/
/* Index: "IX_AUSER_2"                                          */
/*==============================================================*/
CREATE INDEX "IX_AUSER_2" ON "AUSER" (
   "AUSER_TYPE_ID" ASC,
   "NAME" ASC,
   "PASSWD" ASC
)
/

/*==============================================================*/
/* Index: "IX_AUSER_3"                                            */
/*==============================================================*/
CREATE INDEX "IX_AUSER_3" ON "AUSER"
(
   "AUSER_TYPE_ID" ASC,
   "EMAIL" ASC,
   "NAME" ASC
);


/*==============================================================*/
/* Table: "AUSER_TO_AUSER"                                      */
/*==============================================================*/


CREATE TABLE "AUSER_TO_AUSER"  (
   "AUSER_ID"           NUMBER(10)                     DEFAULT 0  NOT NULL,
   "PARENT_ID"          NUMBER(10)                     DEFAULT 0  NOT NULL,
   "RIGHTS"             NUMBER(10)                     DEFAULT 0  NOT NULL
)
/


/*==============================================================*/
/* Index: "IX_AUSER_TO_AUSER_0"                                 */
/*==============================================================*/
CREATE UNIQUE INDEX "IX_AUSER_TO_AUSER_0" ON "AUSER_TO_AUSER" (
   "AUSER_ID" ASC,
   "PARENT_ID" ASC
)
/



INSERT INTO AUSER (AUSER_ID, NAME, PASSWD, EMAIL, DESCRIPTION, AUSER_TYPE_ID, RIGHTS, IS_PUBLISHED, DT_REGISTER) VALUES (1, 'Owner', 'onwner', 'owner', 'Владелец объектов', 2, 16777215, 1, SYSDATE);
INSERT INTO AUSER (AUSER_ID, NAME, PASSWD, EMAIL, DESCRIPTION, AUSER_TYPE_ID, RIGHTS, IS_PUBLISHED, DT_REGISTER) VALUES (2, 'Admins', 'group', 'group', 'Все администрирующие пользователи', 1, 16777215, 1, SYSDATE);
INSERT INTO AUSER (AUSER_ID, NAME, PASSWD, EMAIL, DESCRIPTION, AUSER_TYPE_ID, RIGHTS, IS_PUBLISHED, DT_REGISTER) VALUES (3, 'admin', 'admin', 'misha@design.ru', '', 0, 16777215, 1, SYSDATE);
INSERT INTO AUSER_TO_AUSER (AUSER_ID, PARENT_ID) VALUES (3,2);

