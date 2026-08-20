###########################################################################
# $Id: ArrayListEnumerator.p,v 1.2 2007-08-02 12:51:49 misha Exp $
###########################################################################

@CLASS
ArrayListEnumerator



###########################################################################
@create[oArrayList;iCount;sVar]
$self.oArrayList[$oArrayList]
$self.iCount($iCount)
$self.sVar[$sVar]

^reset[]
#end @create[]



###########################################################################
@reset[]
$iIndex(0)
$uCurrent[]
#end @reset[]



###########################################################################
@getIndex[]
$result($iIndex-1)
#end @getIndex[]



###########################################################################
@moveNext[]
$result($iIndex < $iCount)
^if($result){
	$uCurrent[^oArrayList.getItem($iIndex)]
	^iIndex.inc[]
	^if(def $sVar){$caller.$sVar[$uCurrent]} 
}
#end @moveNext[]



###########################################################################
@current[]
$result[$uCurrent]
#end @current[]


