############################################################
# $Id: MsSql.p,v 2.8 2012-10-01 00:53:28 misha Exp $


@CLASS
MsSql

@USE
Sql.p

@BASE
Sql



@auto[]
$sServerName[MsSql]
$sQuoteChar["]

$server_name[mssql]



@setServerEnvironment[]
# set max available size for text fields (2Gb) (2 KB by default is not enough)
^void:sql{SET TEXTSIZE 2147483647}
# set date/time format MSSQL (independently from server regional settings)
^void:sql{SET LANGUAGE us_english}
^void:sql{SET DATEFORMAT ymd}
$result[]



# DATE functions

@today[]
$result[CONVERT(char, GETDATE(), 111)]



@now[]
$result[CONVERT(char, GETDATE(), 20)]



@year[sSource]
$result[YEAR($sSource)]



@month[sSource]
$result[MONTH($sSource)]



@day[sSource]
$result[DAY($sSource)]



@ymd[sSource]
$result[CONVERT(char, $sSource, 111)]



@time[sSource]
$result[CONVERT(char, $sSource, 108)]



@dateDiff[t;sDateFrom;sDateTo]
$result[DATEDIFF($t, $sDateFrom, ^if(def $sDateTo){$sDateTo}{^self.today[]})]



@dateSub[sDate;iDays]
$result[^if(def $sDate){'$sDate'}{GETDATE()} - $iDays]



@dateAdd[sDate;iDays]
$result[DATEADD(day, $iDays, ^if(def $sDate){$sDate}{^self.today[]})]



# functions available not for all sql servers
# I don't know how to format date
@dateFormat[sSource;sFormatString]
$result[]




# LAST_INSERT_ID()

@lastInsertID[sTable]
^self._execute{
	$result(^int:sql{SELECT @@IDENTITY}[$.default{0}])
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

# WARNING:
# 1. this function is undocumented. it can be removed/modifyed in next version
#    (during upgrade from SQL Server 6.5 to 7.0 it already happened) - so be careful
# 2. the next method not worked now:
#    http://www.theregister.co.uk/2002/07/08/cracking_ms_sql_server_passwords/
# 3. this function return 'binary' (NOT 'text') data
@password[sPassword]
$result[CAST(PWDENCRYPT('$sPassword') AS varbinary(255))]



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
	^void:sql{BEGIN TRANSACTION^if(def $hParams.sName){ NAME $hParams.sName}}
}
$result[]



@commit[hParams]
^self._execute{
	^void:sql{COMMIT TRANSACTION^if(def $hParams.sName){ NAME $hParams.sName}}
}
$result[]



@rollback[hParams]
^self._execute{
	^void:sql{ROLLBACK TRANSACTION^if(def $hParams.sName){ NAME $hParams.sName}}
}
$result[]
