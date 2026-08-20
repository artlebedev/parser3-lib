###########################################################################
# $Id: Sql.p,v 2.8 2013-01-28 02:35:19 misha Exp $
# Parser 3.4.1+ is required


@CLASS
Sql


@USE
SqlInfo.p


###########################################################################
@auto[]
$tOptionsReplace[^table::create{sFrom	sTo
file	sFile
auto	bAuto
is_force	bForce
cache_interval	dInterval
cache_expiration_time	dtExpirationTime}]



###########################################################################
# $.bDebug(true) - collect queries statistics (time/memory usage) [default=false]
# $.sCacheDir[directory for storing cache files]
# $.dCacheInterval(cache expiration interval) [days, default=1]
# $.bCacheAuto(true)- cache all queries (except void) automatically (with auto generated names) [default=false]
@create[sConnectString;hParams]
^if(!def $sConnectString){
	^throw[$self.CLASS_NAME;^$sConnectString must be specified.]
}

$hParams[^hash::create[$hParams]]

$self.sConnectString[$sConnectString]
$self.bDebug(^hParams.bDebug.bool(false))

$self.sCacheDir[$hParams.sCacheDir]

$self.dCacheInterval(^hParams.dCacheInterval.double(1))
$self.iCacheThreshold(^hParams.iCacheThreshold.int(100))

$self.bCacheAuto(def $self.sCacheDir && ^hParams.bCacheAuto.bool(false))
$self.sCacheAutoSubDir[^if(def $hParams.sCacheAutoSubDir){$hParams.sCacheAutoSubDir}{_auto}]

$self.bConnectAuto(^hParams.bConnectAuto.bool(true))

$self.iConnectEstablished(0)
$self.bServerEnvSet(false)
$self.dtNow[^date::now[]]

$self.oSqlInfo[^SqlInfo::create[]]

# backward
$self.server[$self.connect]
$self.setLastInsertId[$self.setLastInsertID]
$self.lastInsertId[$self.lastInsertID]
^if($self.setServerEnviroment is "junction"){
	$self.setServerEnvironment[$self.setServerEnviroment]
}

# compatibility with Sumo's pfSQL
$self.startTransaction[$self.begin]
$self.transaction[$self.connect]




###########################################################################
@connect[jBody]
^oSqlInfo.storeConnectionInfo(1)
^try{
	^iConnectEstablished.inc(1)
	$result[^connect[$sConnectString]{$jBody}]
}{
	^rem{ *** only need finally section *** }
}{
	^iConnectEstablished.dec(1)
	$self.bServerEnvSet(false)
}



###########################################################################
# set server enviroment if needed
@setServerEnvironment[]
$result[]



###########################################################################
# some $hCacheOption are available:
# $.bForce(1). force execute query without clearing file
# $.sFile[path/to/cache-file]. path to file in $sCacheDir
# $.bAuto(1|0). 1 - cache query with auto-generated filename, 0 - disable auto caching for query
# $.dInterval(value). 0 - clear file and don't cache query [days, default=1]
# $.dtExpirationTime[time when cache expire]
# $.iThreshold(value). in any case file will be cleared after 1.5 * dInterval [%, default=100]

###########################################################################
@void[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[void;$hSqlOption;$hCacheOption]]
^self._execute{^self._measure[$hOption]{^void:sql{$hOption.sQuery}}}
$result[]



###########################################################################
@int[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[int;$hSqlOption;$hCacheOption]]
^self._sql[$hOption]{^self._measure[$hOption]{$result(^int:sql{$hOption.sQuery}[$hSqlOption])}}



###########################################################################
@double[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[double;$hSqlOption;$hCacheOption]]
^self._sql[$hOption]{^self._measure[$hOption]{$result(^double:sql{$hOption.sQuery}[$hSqlOption])}}



###########################################################################
@string[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[string;$hSqlOption;$hCacheOption]]
^self._sql[$hOption]{^self._measure[$hOption]{$result[^string:sql{$hOption.sQuery}[$hSqlOption]]}}



###########################################################################
@table[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[table;$hSqlOption;$hCacheOption]]
^self._sql[$hOption]{^self._measure[$hOption]{$result[^table::sql{$hOption.sQuery}[$hSqlOption]]}}



###########################################################################
@hash[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[hash;$hSqlOption;$hCacheOption]]
^self._sql[$hOption]{^self._measure[$hOption]{$result[^hash::sql{$hOption.sQuery}[$hSqlOption]]}}



###########################################################################
@file[jQuery;hSqlOption;hCacheOption][hOption]
$hOption[^self._getOptions{$jQuery}[file;$hSqlOption;$hCacheOption]]
^self._sql[$hOption]{^self._measure[$hOption]{$result[^file::sql{$hOption.sQuery}[$hSqlOption]]}}



###########################################################################
@quote[sName]
$result[${sQuoteChar}${sName}$sQuoteChar]



###########################################################################
# when you update database and want to clear cache file immediately you have to call: ^clear[cache-file]
# ^clear[] w/o parameters deletes all cache files
@clear[sFileName]
^if(def $self.sCacheDir){
	^self._delete[$self.sCacheDir^if(def $sFileName){/$sFileName}]
}
$result[]



############################################################
@setLastInsertID[sTable;sOrderColumn;sIdColumn]
^self._execute{
	$result(^self.lastInsertID[$sTable])
	^void:sql{UPDATE ^self.quote[$sTable] SET ^self.quote[^if(def $sOrderColumn){$sOrderColumn}{sort_order}]=$result WHERE ^self.quote[^if(def $sIdColumn){$sIdColumn}{${sTable}_id}]=$result}
}



###########################################################################
# must return text with query details (explain for mysql)
@getQueryDetail[sType;sQuery;hSqlOption][result]
$result[]



@_execute[jQuery;hParams][result]
^if(!$self.iConnectEstablished && ^hParams.bConnectAuto.bool($self.bConnectAuto)){
	$result[^self.connect{^self._setServerEnv[]$jQuery}}]
}{
	$result[^self._setServerEnv[]$jQuery]
}



@_setServerEnv[][result]
^if(!$self.bServerEnvSet){
	$self.bServerEnvSet(true)
	^self.setServerEnvironment[]
}
$result[]



@_getOptions[jQuery;sType;hSqlOptions;hCacheOptions]
$result[
	$.sQuery[$jQuery]
	$.sType[$sType]
	$.hSql[^if($hSqlOptions is "hash"){$hSqlOptions}]
	$.hCache[^hash::create[$hCacheOptions]]
]
^if($result.hCache){
	^self._copyValues[$result.hCache;$self.tOptionsReplace]
}



@_copyValues[hOption;tData][result]
^tData.menu{^if(def $hOption.[$tData.sFrom] && !def $hOption.[$tData.sTo]){$hOption.[$tData.sTo][$hOption.[$tData.sFrom]]}}
$result[]



@_measure[hOptions;jBody][hBefore;hAfter;hStat]
^if($self.bDebug){
	$hBefore[^self._getStat[]]
	$result[$jBody]
	$hAfter[^self._getStat[]]
	$hStat[
		$.dTime($hAfter.iTime-$hBefore.iTime)
		$.iMemoryBlock($hAfter.iBL-$hBefore.iBL)
		$.iMemoryKB($hAfter.iKB-$hBefore.iKB)
	]
}{
	$result[$jBody]
}
^oSqlInfo.storeQueryInfo[$hOptions;$hStat;$caller.result]



@_getStat[]
^try{
	$result[
		$.iTime($status:rusage.tv_sec*1000+$status:rusage.tv_usec/1000)
		$.iBL($status:rusage.maxrss)
		$.iKB($status:memory.used)
	]
}{
	$exception.handled(true)
}



@_sql[hOption;jQuery][sFileSpec]
$sFileSpec[^self._getFileSpec[$hOption]]
^switch[^self._getFileStatus[$sFileSpec;$hOption]]{
	^case[load]{
		$caller.result[^self._load[$hOption.sType;$sFileSpec]]
	}
	^case[sql;force]{
		^self._execute{$jQuery}
	}
	^case[skip-save]{
		^self._delete[$sFileSpec]
		^self._execute{$jQuery}
	}
	^case[DEFAULT]{
		^self._delete[$sFileSpec]
		^self._execute{$jQuery}
		^self._save[$hOption.sType;$sFileSpec;$caller.result]
	}
}
$result[]



@_getFileStatus[sFileSpec;hOption][dInterval;dtNow;fStat;dtExpire]
^if($hOption.hCache.bForce){
	$result[force]
}{
	^if(def $sFileSpec){
		$dInterval(^hOption.hCache.dInterval.double($self.dCacheInterval))
		^if($dInterval){
			^if(-f $sFileSpec){
				^try{
					$dtNow[^date::now[]]
					$fStat[^file::stat[$sFileSpec]]
					^if(
						($fStat.mdate < ($dtNow - $dInterval))
						&& (
							$fStat.mdate < ($dtNow - 1.5 * $dInterval)
							|| ^math:random(100) < ^hOption.iThreshold.int($self.iCacheThreshold)
						)
					){
						$result[interval]
					}{
						^if(def $hOption.hCache.dtExpirationTime){
							^if($hOption.hCache.dtExpirationTime is "date"){
								$dtExpire[^date::create($dtNow.year;$dtNow.month;$dtNow.day;$hOption.hCache.dtExpirationTime.hour;$hOption.hCache.dtExpirationTime.minute;$hOption.hCache.dtExpirationTime.second)]
							}{
								$dtExpire[^date::create[$hOption.hCache.dtExpirationTime]]
							}
							^if($dtNow > $dtExpire && $fStat.mdate < $dtExpire){
								$result[time]
							}
						}
					}
					^if(!def $result){
						$result[load]
					}
				}{
					$exception.handled(true)
					$result[bad-file]
				}
			}{
				$result[no-file]
			}
		}{
			$result[skip-save]
		}
	}{
		$result[sql]
	}
}



@_getFileSpec[hOptions][result]
^if(def $hOptions.hCache.sFile){
	$result[$self.sCacheDir/$hOptions.hCache.sFile]
}(^hOptions.bAuto.bool($self.bCacheAuto)){
	$result[$self.sCacheDir/$self.sCacheAutoSubDir/^math:md5[$hOptions.sQuery]^if(def $hOptions.hSql && ($hOptions.hSql.limit || $hOptions.hSql.offset)){=$hOptions.hSql.limit=$hOptions.hSql.offset}.$hOptions.sType]
}{
	$result[]
}



@_delete[sFileSpec][result;t]
^if(def $sFileSpec){
	^if(-d $sFileSpec){
		$t[^file:list[$sFileSpec]]
		^t.menu{
			^self._delete[$sFileSpec/$t.name]
		}
	}(-f $sFileSpec){
		^try{
			^file:delete[$sFileSpec]
		}{
			$exception.handled(true)
		}
	}
}
$result[]



@_save[sType;sFileSpec;uValue][tKey;t;sKey;sValue]
^switch[$sType]{
	^case[int;double;string]{
		^uValue.save[$sFileSpec]
	}
	^case[table]{
		^uValue.save[$sFileSpec;$.encloser["]]
	}
	^case[hash]{
		$tKey[^uValue._keys[]]
		^if($uValue.[$tKey.key] is "hash"){
			$t[^table::create{key^uValue.[$tKey.key].foreach[sKey;]{^#09$sKey}}]
			^tKey.menu{^t.append{$tKey.key^uValue.[$tKey.key].foreach[;sValue]{^#09$sValue}}}
		}{
			$t[^table::create{key}]
			^tKey.menu{^t.append{$tKey.key}}
		}
		^self._save[table;$sFileSpec;$t]
	}
	^case[file]{
		^uValue.save[binary;$sFileSpec]
	}
	^case[void]{}
}
$result[]



@_load[sType;sFileSpec][f;t;c]
^switch[$sType]{
	^case[int]{
		$f[^file::load[text;$sFileSpec]]
		$result(^f.text.int(0))
	}
	^case[double]{
		$f[^file::load[text;$sFileSpec]]
		$result(^f.text.double(0))
	}
	^case[string]{
		$f[^file::load[text;$sFileSpec]]
		$result[$f.text]
	}
	^case[table]{
		$result[^table::load[$sFileSpec;$.encloser["]]]
	}
	^case[hash]{
		$t[^self._load[table;$sFileSpec]]
		$c[^t.columns[]]
		$result[^t.hash[$c.column]]
	}
	^case[file]{
		$result[^file::load[binary;$sFileSpec]]
	}
	^case[void]{
		$result[]
	}
}



#####################################
# backward

# use direct methods like ^oSQL.table{...} instead of ^oSQL.sql[table]{...}
@sql[sType;jQuery;hSQLOptions;hCacheOptions]
^switch[$sType]{
	^case[int;double]{
		$result(^self.[$sType]{$jQuery}[$hSQLOptions;$hCacheOptions])
	}
	^case[void;table;hash;string;file]{
		$result[^self.[$sType]{$jQuery}[$hSQLOptions;$hCacheOptions]]
	}
	^case[DEFAULT]{
		^throw[$self.CLASS_NAME;Unknown type '$sType']
	}
}

