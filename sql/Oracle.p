############################################################
# $Id: Oracle.p,v 2.8 2012-10-01 00:53:28 misha Exp $


@CLASS
Oracle

@USE
Sql.p

@BASE
Sql



@auto[]
$sServerName[Oracle]
$sQuoteChar["]

$server_name[oracle]



@setServerEnvironment[]
# set date/time format and language
^void:sql{ALTER SESSION SET NLS_LANGUAGE="ENGLISH"}
^void:sql{ALTER SESSION SET NLS_TERRITORY="AMERICA"}
^void:sql{ALTER SESSION SET NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"}
$result[]



# DATE functions

@today[]
$result[trunc(SYSDATE)]



@now[]
$result[SYSDATE]



@year[sSource]
$result[TO_CHAR($sSource,'YYYY')]



@month[sSource]
$result[TO_CHAR($sSource,'MM')]



@day[sSource]
$result[TO_CHAR($sSource,'DD')]



@ymd[sSource]
$result[TO_CHAR($sSource,'YYYY-MM-DD')]



@time[sSource]
$result[TO_CHAR($sSource,'HH24:MI:SS')]



@dateDiff[t;sDateFrom;sDateTo]
$result[^if(def $sDateTo){TO_DATE($sDateTo)}{^self.today[]} - TO_DATE($sDateFrom)]



@dateSub[sDate;iDays]
$result[^if(def $sDate){TO_DATE($sDate)}{^self.today[]} - $iDays]



@dateAdd[sDate;iDays]
$result[^if(def $sDate){TO_DATE($sDate)}{^self.today[]} + $iDays]



# functions available not for all sql servers
# MSSQL does not have anything like this
@dateFormat[sSource;sFormatString]
$result[TO_CHAR($sSource, '^if(def $sFormatString){$sFormatString}{YYYY-MM-DD}')]



# LAST_INSERT_ID()

# for auto increment we must for each table with name (TABLE) add
# CREATE SEQUENCE SEQ_TABLE INCREMENT by 1 START with 1;
# CREATE TRIGGER TRG_TABLE
# BEFORE INSERT ON TABLE
#     FOR EACH ROW
#     BEGIN
#     IF :new.TABLE_id is null THEN
#         SELECT SEQ_TABLE.nextval INTO :new.TABLE_id FROM dual;
#     END IF;
# END;
# /

@lastInsertID[sTable]
^self._execute{
	$result(^int:sql{SELECT SEQ_${sTable}.currval FROM dual}[$.default{0}])
}



# STRING functions

@substring[sSource;iPos;iLength]
$result[SUBSTR($sSource,^if(def $iPos){$iPos}{1},^if(def $iLength){$iLength}{1})]



@upper[sField]
$result[UPPER($sField)]



@lower[sField]
$result[LOWER($sField)]



@concat[*hArgs][s]
$result[CONCAT(^hArgs.foreach[;s]{$s}[, ])]



# MISC functions

@password[sPassword]
$result[^math:md5[$sPassword]]



@leftJoin[sType;sTable;sJoinConditions;last;sAS]
$result[^switch[^sType.lower[]]{
	^case[from]{, ^self.quote[$sTable]^if(def $sAS){ $sAS}}
	^case[where]{$sJoinConditions (+)^if(!def $last){ AND }}
	^case[DEFAULT]{
		^throw[$self.CLASS_NAME;Unknown join type '$sType']
	}
}]



@begin[hParams]
^self._execute{
	^void:sql{SET TRANSACTION^if(def $hParams.sName){ NAME $hParams.sName}}
}
$result[]



@commit[hParams]
^self._execute{
	^void:sql{COMMIT}
}
$result[]



@rollback[hParams]
^self._execute{
	^void:sql{ROLLBACK}
}
$result[]
