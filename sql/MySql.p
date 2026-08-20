############################################################
# $Id: MySql.p,v 2.10 2012-10-01 00:53:28 misha Exp $


@CLASS
MySql

@USE
Sql.p

@BASE
Sql



@auto[]
$sServerName[MySql]
$sQuoteChar[`]

$server_name[mysql]



# DATE functions

@today[]
$result[CURDATE()]



@now[]
$result[NOW()]



@year[sSource]
$result[YEAR($sSource)]



@month[sSource]
$result[MONTH($sSource)]



@day[sSource]
$result[DATE_FORMAT($sSource,'%d')]



@ymd[sSource]
$result[DATE_FORMAT($sSource,'%Y-%m-%d')]



@time[sSource]
$result[DATE_FORMAT($sSource,'%H:%i:%S')]



@dateDiff[t;sDateFrom;sDateTo]
$result[^if(def $sDateTo){TO_DAYS($sDateTo)}{^self.now[]} - TO_DAYS($sDateFrom)]



@dateSub[sDate;iDays]
$result[DATE_SUB(^if(def $sDate){$sDate}{^self.today[]},INTERVAL $iDays DAY)]



@dateAdd[sDate;iDays]
$result[DATE_ADD(^if(def $sDate){$sDate}{^self.today[]},INTERVAL $iDays DAY)]



# functions available not for all sql servers
# MSSQL does not have anything like this
@dateFormat[sSource;sFormatString]
$result[DATE_FORMAT($sSource, '^if(def $sFormatString){$sFormatString}{%Y-%m-%d}')]



# LAST_INSERT_ID()

@lastInsertID[sTable]
^self._execute{
	$result(^int:sql{SELECT last_insert_id()}[$.default{0}])
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
$result[PASSWORD($sPassword)]



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
	^void:sql{START TRANSACTION}
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



# overrided for receive explain info
@getQueryDetail[sType;sQuery;hSqlOptions][tExplain;tColumn]
$result[]
^if(def $sQuery && $sType ne "void"){
	^try{
		$tExplain[^table::sql{EXPLAIN $sQuery^if(def $hSqlOptions && def $hSqlOptions.limit){ LIMIT ^if(def $hSqlOptions.offset){$hSqlOptions.offset,}$hSqlOptions.limit}}]
		$tColumn[^tExplain.columns[]]
		$result[EXPLAIN:^#0A^tColumn.menu{$tColumn.column	}^#0A^tExplain.menu{^tColumn.menu{$tExplain.[$tColumn.column]	}}[^#0A]]
	}{
		$exception.handled(true)
	}
}
