############################################################
# $Id: SQLite.p,v 1.3 2012-10-01 00:53:28 misha Exp $

@CLASS
SQLite

@USE
Sql.p

@BASE
Sql



@auto[]
$sServerName[SQLite]
# todo@
$sQuoteChar[`]

$server_name[sqlite]



# DATE functions

@today[]
$result[DATE('now')]



@now[]
$result[DATETIME('now')]



@year[sSource]
$result[STRFTIME('%Y', $sSource)]



@month[sSource]
$result[STRFTIME('%m', $sSource)]



@day[sSource]
$result[STRFTIME('%d', $sSource)]



@ymd[sSource]
$result[STRFTIME('%Y-%m-%d', $sSource)]



@time[sSource]
$result[TIME($sSource)]



@dateDiff[t;sDateFrom;sDateTo]
$result[^if(def $sDateTo){JULIANDAY($sDateTo)}{^self.now[]} - JULIANDAY($sDateFrom)]



@dateSub[sDate;iDays]
$result[DATE(^if(def $sDate){$sDate}{^self.today[]}, '+$iDays DAY')]



@dateAdd[sDate;iDays]
$result[DATE(^if(def $sDate){$sDate}{^self.today[]}, '-$iDays DAY')]



# functions available not for all sql servers

# MSSQL does not have anything like this
@dateFormat[sSource;sFormatString]
$result[STRFTIME('^if(def $sFormatString){$sFormatString}{%Y-%m-%d}', $sSource)]



# LAST_INSERT_ID()
@lastInsertID[sTable]
^self._execute{
	$result(^int:sql{SELECT last_insert_rowid()}[$.default{0}])
}



# STRING functions

@substring[sSource;iPos;iLength]
$result[SUBSTRING($sSource,^if(def $iPos){$iPos}{1},^if(def $iLength){$iLength}{1})]



@upper[sField]
$result[UPPER($sField)]



@lower[sField]
$result[LOWER($sField)]



@concat[*hArgs][s]
$result[^hArgs.foreach[;s]{IFNULL($s, '')}[ || ]]



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
