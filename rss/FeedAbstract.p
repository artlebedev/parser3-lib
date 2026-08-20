###########################################################################
# $Id: FeedAbstract.p,v 1.4 2007/08/06 14:31:13 misha Exp $
###########################################################################

@CLASS
FeedAbstract


@USE
dtf.p



###########################################################################
@create[hInputData]
$hData[^hash::create[]]
$hField[^tField.hash[sName]]

^set[$hInputData]
#end @create[]



###########################################################################
@set[hInputData][uValue]
^if(def $hInputData){
	$hInputData[^hash::create[$hInputData]]
	^tField.menu{
		$uValue[^if(def $hInputData.[$tField.sName]){$hInputData.[$tField.sName]}{$tField.uDefault}]
		^if(def $uValue){
			^setField[$tField.sName;$uValue]
		}
	}
}
$result[]
#end @set[]



###########################################################################
@print[hParam][tFilled]
$hParam[^hash::create[$hParam]]

^check[]

$tFilled[^tField.select(def ^getField[$tField.sName])]

$result[<$sTag>
^tFilled.menu{^printField[$tFilled.fields;$hParam]}[^#0A]
</$sTag>]
#end @print[]



###########################################################################
@getField[sName]
$result[$hData.$sName]
#end @getField[]



###########################################################################
@setField[sName;uValue]
^if(def $uValue){
	$hData.[$sName][^convert[$uValue;$hField.[$sName].sType]]
}{
	^hData.delete[$sName]
}
$result[]
#end @setField[]



###########################################################################
@printField[hField;hParam][uValue]
$uValue[^getField[$hField.sName]]
$result[^switch[$hField.sType]{
	^case[string;int;double]{<$hField.sName>$uValue</$hField.sName>}
	^case[date]{<$hField.sName>^dtf:format[%_ ^if(def $hParam.sTZ){$hParam.sTZ}{GMT};$uValue]</$hField.sName>}
	^case[DEFAULT]{^throw[$sClassName;Unsupported field type '$hField.sType'.]}
}]
#end @printField[]



###########################################################################
@check[][tEmpty]
$tEmpty[^tField.select($tField.bRequired && !def ^getField[$tField.sName])]
^if($tEmpty){
	^throw[$sClassName;Required fields which wasn't defined: ^tEmpty.menu{^$.$tEmpty.sName}[, ]]
}
#end @check[]



###########################################################################
@convert[uValue;sTypeTo][sTypeFrom]
$sTypeFrom[^getType[$uValue]]
^if($sTypeFrom eq $sTypeTo){
	$result[$uValue]
}{
	^switch[$sTypeFrom=>$sTypeTo]{
		^case[string=>date]{
			$result[^date::create[$uValue]]
		}
		^case[string=>int]{
			$result(^uValue.int(0))
		}
		^case[string=>double]{
			$result(^uValue.double(0))
		}
		^case[date=>string]{
			$result[^uValue.sql-string[]]
		}
		^case[date=>int;date=>double]{
			$result(^uValue.unix-timestamp[])
		}
		^case[int=>string;double=>string]{
			$result[$uValue]
		}
		^case[int=>date;double=>date]{
			$result[^date::create($uValue)]
		}
		^case[DEFAULT]{
			^throw[$sClassName;Can't convert value from '$sTypeFrom' to '$sTypeTo'.]
		}
	}
}
#end @convert[]



###########################################################################
@getType[uValue]
$result[^switch(true){
	^case($uValue is "string"){string}
	^case($uValue is "date"){date}
	^case($uValue is "int"){int}
	^case($uValue is "double"){double}
	^case($uValue is "bool"){bool}
	^case($uValue is "hash"){hash}
	^case($uValue is "table"){table}
	^case($uValue is "ArrayList"){ArrayList}
	^case[DEFAULT]{}
}]
#end @getType[]
