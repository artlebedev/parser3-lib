###########################################################################
# $Id: SqlInfo.p,v 2.4 2012-07-30 11:44:45 misha Exp $


@CLASS
SqlInfo



###########################################################################
@create[]
$iConnectionsCount(0)
$hQuery[^hash::create[]]
$hStat[^hash::create[]]



###########################################################################
@storeConnectionInfo[iCount]
^iConnectionsCount.inc($iCount)
$result[]



###########################################################################
@storeQueryInfo[hOption;hQueryStat;uResult]
^self._updateTypeStat[TOTAL;$hQueryStat]
^self._updateTypeStat[$hOption.sType;$hQueryStat]
$hQuery.[$hStat.TOTAL.iCount][
	$.hOption[$hOption]
	$.hStat[$hQueryStat]
	$.sResult[^switch[$hOption.sType]{
		^case[void;table;hash;file]{}
		^case[int;double]($uResult)
		^case[string]{^if(def $uResult){^uResult.left(40)}}
	}]
	$.iRowsCount(^switch[$hOption.sType]{
		^case[void]{0}
		^case[table;hash]($uResult)
		^case[int;double;string;file]{1}
	})
]
$result[]



@_initStat[]
$result[
	$.iCount(0)
	$.dTime(0)
	$.iMemoryKB(0)
	$.iMemoryBlock(0)
]



@_updateTypeStat[sType;hQueryStat][h;result]
$h[$hStat.$sType]
^if(!$h){
	$h[^self._initStat[]]
	$hStat.[$sType][$h]
}
^h.iCount.inc(1)
^if(def $hQueryStat){
	^h.dTime.inc($hQueryStat.dTime)
	^h.iMemoryKB.inc($hQueryStat.iMemoryKB)
	^h.iMemoryBlock.inc($hQueryStat.iMemoryBlock)
}
$result[]
