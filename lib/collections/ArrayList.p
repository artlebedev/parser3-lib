###########################################################################
# $Id: ArrayList.p,v 1.5 2010-10-21 12:38:09 misha Exp $
###########################################################################

@CLASS
ArrayList

#@USE
#^use[ArrayListEnumerator.p]



###########################################################################
@auto[]
$sClassName[ArrayList]
#end @auto[]



###########################################################################
@create[iSize][i]
^clear[]

^if($iSize){
	^for[i](0;$iSize-1){^add[]}
}
#end @create[]


###########################################################################
@count[]
$result($iCount)
#end @count[]


###########################################################################
@add[uValue]
$hList.[$iCount][$uValue]
^iCount.inc[]
$result[]
#end @add[]



###########################################################################
@getItem[iIndex]
^checkRange($iIndex)
$result[$hList.$iIndex]
#end @getItem[]



###########################################################################
@setItem[iIndex;uValue]
^checkRange($iIndex)
$hList.[$iIndex][$uValue]
$result[]
#end @setItem[]



###########################################################################
@removeAt[iIndex][iCurrent;iNext]
^checkRange($iIndex)
$iNext($iIndex+1)
^for[iCurrent]($iIndex;$iCount-2){
	$hList.[$iCurrent][$hList.[$iNext]]
	^iNext.inc[]
}
$hList.[$iCount][]
^iCount.dec[]
$result[]
#end @removeAt[]



###########################################################################
@clear[]
$hList[^hash::create[]]
$iCount(0)
$result[]
#end @clear[]



###########################################################################
@getEnumerator[sVar]
^use[ArrayListEnumerator.p]
$result[^ArrayListEnumerator::create[$self;$iCount;$sVar]]
#end @getEnumerator[]



###########################################################################
@checkRange[iIndex]
^if($iIndex < 0 && $iIndex >= $iCount){
	^throw[$sClassName;Item index '$iIndex' is not in valid range ^[0..$iCount^)]
}
$result[]
#end @checkRange[]



