############################################################
# $Id: PgSql.p,v 2.8 2012-10-01 00:53:28 misha Exp $
# based on egr's pgsql.p

@CLASS
PgSql

@USE
Sql.p

@BASE
Sql



@auto[]
$sServerName[PgSql]
$sQuoteChar["]

$server_name[pgsql]



# DATE functions

# current date
@today[]
$result[CURRENT_DATE]



# current date and time
@now[]
$result[CURRENT_TIMESTAMP]



@year[sSource]
$result[EXTRACT(year FROM $sSource)]



@month[sSource]
$result[EXTRACT(month FROM $sSource)]



@day[sSource]
$result[EXTRACT(day FROM $sSource)]



@ymd[sSource]
$result[TO_CHAR($sSource,'YY-MM-DD')]



@time[sSource]
$result[TO_CHAR($sSource,'HH24:MI:SS')]



# days between specified dates
@dateDiff[t;sDateFrom;sDateTo]
$result[^if(def $sDateTo){TO_DAYS($sDateTo)}{^self.today[]} - TO_DAYS($sDateFrom)]



@dateSub[sDate;iDays]
$result[^if(def $sDate){'$sDate'}{^self.now[]} - INTERVAL '$iDays DAYS']



@dateAdd[sDate;iDays]
$result[^if(def $sDate){'$sDate'}{^self.now[]} + INTERVAL '$iDays DAYS']



# functions available not for all sql servers
# MSSQL does not have anything like this
@dateFormat[sSource;sFormatString]
$result[TO_CHAR($sSource, '^if(def $sFormatString){$sFormatString}{YY-MM-DD}')]




# LAST_INSERT_ID()

# you must add column with SERIAL type and sequence created by default
@lastInsertID[sTable]
^self._execute{
	$result(^int:sql{SELECT CURRVAL('${sTable}_${sTable}_id_seq')}[$.default{0}])
}



# STRING functions

@substring[sSource;iPos;iLength]
$result[SUBSTRING($sSource,^if(def $iPos){$iPos}{1},^if(def $iLength){$iLength}{1})]



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
	^case[from]{LEFT JOIN ^self.quote[$sTable]^if(def $sAS){ $sAS} ON ($sJoinConditions)}
	^case[where]{1 = 1^if(!def $last){ AND}}
	^case[DEFAULT]{
		^throw[$self.CLASS_NAME;Unknown join type '$sType']
	}
}]



@begin[hParams]
^self._execute{
	^void:sql{BEGIN TRANSACTION}
}
$result[]



@commit[hParams]
^self._execute{
	^void:sql{COMMIT TRANSACTION}
}
$result[]



@rollback[hParams]
^self._execute{
	^void:sql{ROLLBACK TRANSACTION}
}
$result[]
