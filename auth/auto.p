@USE
Erusage.p
MySqlComp.p
auth.p



###########################################################################
@auto[]
$oSql[^MySqlComp::create[$SQL.connect-string;
	$.bDebug(true)
	$.sCacheDir[$CACHE_DIR/_sql]
]]
#end @auto[]



###########################################################################
@postprocess[sBody][repl;tmp]
$result[$sBody]

#...your postprocess code here if needed...

^getSQLStat[$oSql]
^rusage[]
#end @postprocess[]



###########################################################################
# log SQL statistics to file
@getSQLStat[oSql][oSqlLog]
^if(def $oSql && !in "/admin/"){
	^use[SqlLog.p]
	$oSqlLog[^SqlLog::create[$oSql]]
	^oSqlLog.log[
		$.iQueryTimeLimit(500)
		$.iQueriesLimit(25)
		$.iQueryRowsLimit(3000)
		^if(def $form:mode && ^form:tables.mode.locate[field;debug]){
			^rem{ *** for ?mode=debug collect all queries info and store it to separate file *** }
			$.sFile[$DATA_DIR/sql.txt]
			$.bAll(1)
		}{
			^rem{ *** by default we log only pages with potential problems *** }
			$.sFile[$DATA_DIR/sql.log]
		}
	]
}
$result[]
#end @getSQLStat[]




###########################################################################
@rusage[sMessage]
^if(!in "/admin/"){
	^Erusage:log[
		$.sFile[$DATA_DIR/rusage.log]
		$.sMessage[$sMessage]
	]
}
$result[]
#end @rusage[]




