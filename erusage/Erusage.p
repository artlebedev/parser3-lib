###########################################################################
# $Id: Erusage.p,v 1.5 2009-03-15 01:32:31 misha Exp $
###########################################################################
#
# Usage:
# Firts call: ^Erusage:init[$.iLimit(2048)] (can be omited)
# Others calls: ^Erusage:compact[]
# Real ^memory:compact[] will be called if used more then $iLimit KB since last compact 
#  or if $.bForce(1) option is specified.
#
# At the end (in @postprocess for ex.) you can analize statistics or call ^Erusage:log[] or ^Erusage:print[].


@CLASS
Erusage



###########################################################################
@auto[]
$hRusageBegin[$status:rusage]
$hStat[
	$.iCalls(0)
	$.iCompact(0)
	$.hMemory[
		$.iBegin(0)
		$.iEnd(0)
		$.iCollected(0)
	]
]
$iLimit(2048)
^self._saveMemoryUsage[iBegin]
#end @auto[]



###########################################################################
@init[hParam][result]
$iLimit(^hParam.iLimit.int($iLimit))
$result[]
#end @init[]



###########################################################################
@compact[hParam][hMem]
$hStat.iCalls($hStat.iCalls+1)
$hMem[$status:memory]
^if($hParam.bForce || ($iLimit && ($hMem.used-$hStat.hMemory.iEnd)>$iLimit)){
	$hStat.iCompact($hStat.iCompact+1)
	^memory:compact[]
	$hStat.hMemory.iCollected($hStat.hMemory.iCollected+$hMem.used-$status:memory.used)
	^self._saveMemoryUsage[iEnd]
}
$result[]
#end @compact[]



###########################################################################
# measure time/memory usage while running $jCode
# .time - 'dirty' execution time (millisecond)
# .utime - 'pure' execution time (second)
# .memory_kb - used memory (KB)
# .memory_block - used memory (blocks)
@measure[jCode;sVarName][hBegin;hEnd]
^if(def $sVarName){
	^try{
		$hBegin[
			$.rusage[$status:rusage]
			$.memory[$status:memory]
		]
	}{
		$exception.handled(1)
	}
	$result[$jCode]
	^try{
		$hEnd[
			$.rusage[$status:rusage]
			$.memory[$status:memory]
		]
	}{
		$exception.handled(1)
	}
	$caller.[$sVarName][
		$.time((^hEnd.rusage.tv_sec.double[]-^hBegin.rusage.tv_sec.double[])*1000+(^hEnd.rusage.tv_usec.double[]-^hBegin.rusage.tv_usec.double[])/1000)
		$.utime($hEnd.rusage.utime-$hBegin.rusage.utime)
		$.memory_block($hEnd.rusage.maxrss-$hBegin.rusage.maxrss)
		^if($hBegin.memory){
			$.memory_kb($hEnd.memory.used-$hBegin.memory.used)
		}
	]
}{
	$result[$jCode]
}
#end @measure[]



###########################################################################
@print[hParam][dtNow;result]
$dtNow[^date::now[]]
$result[^dtNow.sql-string[]	memory begin/end/collected: $hStat.hMemory.iBegin/$hStat.hMemory.iEnd/$hStat.hMemory.iCollected KB	calls/compacts: $hStat.iCalls/$hStat.iCompact	http://${env:SERVER_NAME}$request:uri^#0A]
^if(def $hParam && def $hParam.sFile){
	^result.save[append;$hParam.sFile]
}
#end @print[]



###########################################################################
@log[hParam][dNow;sResult;sMark;hLimit;hRusage;hMemory;result]
^if(def $hParam && def $hParam.sFile){
	$sMark[^if(def $hParam.sMarkChar){$hParam.sMarkChar}{!}]
	$hLimit[
		$.dUTime(^hParam.dUTime.double(0))
		$.dTime(^hParam.dTime.double(0))
		$.dMaxRss(^hParam.dMaxRss.double(0))
	]
	$dNow[^date::now[]]
	$hRusage[$status:rusage]
	$hMemory[$status:memory]
	$sResult[[^dNow.sql-string[]]	^self._print[$hRusage.utime;%0.4f;$hLimit.dUTime;$sMark]	^self._print(^hRusage.tv_sec.double[]-^hRusageBegin.tv_sec.double[]+(^hRusage.tv_usec.double[]-^hRusageBegin.tv_usec.double[])/1000000)[%0.4f;$hLimit.dTime;$sMark]	^self._print[$hRusage.maxrss;%d;$hLimit.dMaxRss;$sMark]	[$hMemory.used/$hMemory.free]	$env:REMOTE_ADDR	$request:uri^if(def $hParam.sMessage){ $hParam.sMessage}^#0A]
	^sResult.save[append;$hParam.sFile]
}
$result[]
#end @log[]




#####################################
@_print[uValue;sFormat;dLimit;sMark][dValue;result]
$dValue($uValue)
$result[^if($dLimit && $dValue>$dLimit){$sMark}^if(def $sFormat){^dValue.format[$sFormat]}{$dValue}]


@_saveMemoryUsage[sType][result]
$hStat.hMemory.$sType($status:memory.used)
$result[]
