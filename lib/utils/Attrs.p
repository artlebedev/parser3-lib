###########################################################################
# $Id: Attrs.p,v 1.8 2011-10-10 01:48:40 misha Exp $
#
# Requirements: Parser 3.4.1+ (@SET_DEFAULT[...] and @method[*args] are used)


@CLASS
Attrs



###########################################################################
@create[uData;uExclude;uAddon]
$self.hData[^self._parse[$uData]]
^if(def $uExclude){
	^self.sub[$uExclude]
}
^if(def $uAddon){
	^self.add[$uAddon]
}


###########################################################################
# .string[]       -- print all attrs
# .string[class]  -- pring 'class' attr value
# :string[uAttrs] -- parse and print all attrs
# :string[uAttrs;class] -- parse and print 'class' attr value
# :string[uAttrs;;uExclude;uAddon] -- parse using $uExclude + $uAddon and print all attrs
@string[*hParams][result;sAttrName;hData;sName]
^if(^reflection:dynamical[]){
	^if($hParams > 1){
		^self._throw[string;Only one param is supported in dynamic call]
	}
	$hData[$self.hData]
	$sAttrName[$hParams.0]
}{
	$hData[^self._parse[$hParams.0]]
	$sAttrName[$hParams.1]
	^if(def $hParams.2){
		^hData.sub[$hParams.2]
	}
	^if(def $hParams.3){
		^hData.add[$hParams.3]
	}
}
^if($hData){
	^if(def $sAttrName){
		$result[^self._value[$hData;$sAttrName]]
	}{
		$result[^hData.foreach[sName;]{^self._print[$hData;$sName]}]
	}
}{
	$result[]
}


###########################################################################
# .hash[] -- return attrs as a hash
# :hash[uAttrs] -- parse and return as a hash
@hash[uAttrs][result]
^if(^reflection:dynamical[]){
	^if(def $uAttrs){
		^self._throw[hash;Method doesn't accept any params]
	}
	$result[^hash::create[$self.hData]]
}{
	$result[^self._parse[$uAttrs]]
}


###########################################################################
@add[uData][result]
^if(def $uData){
	^self.hData.add[^self._parse[$uData]]
}


###########################################################################
@union[uData][result]
^if(def $uData){
	^self.hData.union[^self._parse[$uData]]
}


###########################################################################
@delete[sName][result]
^if(def $sName){
	^self.hData.delete[$sName]
}


###########################################################################
@sub[uData][result]
^if(def $uData){
	^self.hData.sub[^self._parse[$uData]]
}


###########################################################################
@contains[sName;sValue][result;uValue;i]
$result(^self.hData.contains[$sName])
^if($result && def $sValue){
	$uValue[$self.hData.$sName]
	^if($uValue is "hash"){
		$result(false)
		^for[i](0;$uValue-1){
			^if($uValue.$i eq $sValue){
				$result(true)
				^break[]
			}
		}
	}{
		$result($uValue eq $sValue)
	}
}


###########################################################################
@append[sName;sValue;hParam][result]
$hParam[^hash::create[$hParam]]
^if(def $sValue && (!$hParam.bUnique || !^self.contains[$sName;$sValue])){
	^if(!^self.contains[$sName]){
		$self.hData.[$sName][$sValue]
	}{
		^if($self.hData.$sName is "hash"){
			$self.hData.[$sName].[^self.hData.[$sName]._count[]][$sValue]
		}{
			$self.hData.[$sName][
				$.0[$self.hData.$sName]
				$.1[$sValue]
			]
		}
	}
}


###########################################################################
@GET_DEFAULT[sName][result]
$result[$self.hData.$sName]


###########################################################################
@SET_DEFAULT[sName;uValue]
$self.hData.[$sName][$uValue]



@_parse[uData][result;xAttr;sDummy;sName;uValue]
$result[^hash::create[]]
^if(def $uData){
	^if($uData is "Attrs"){
		$result[^uData.hash[]]
	}{
		^switch[$uData.CLASS_NAME]{
			^case[xnode]{
				^if($uData.attributes){
					^uData.attributes.foreach[;xAttr]{$result.[$xAttr.nodeName][^taint[$xAttr.nodeValue]]}
				}
			}
			^case[string]{
				^if(^uData.pos[<] >= 0){
					$sDummy[^uData.match[<\w[-\w:]*\s+([^^>]+)\s*/?>][]{$result[^self._parse[$match.1]]}]
				}{
					$sDummy[^uData.match[([-\w:]+?)\s*=\s*(["'])(.*?)\2][g]{$result.[$match.1][^taint[$match.3]]}]
				}
			}
			^case[hash]{
				^uData.foreach[sName;uValue]{
					^switch[$uValue.CLASS_NAME]{
						^case[string;int;double;void;bool]{$result.[$sName][$uValue]}
						^case[DEFAULT]{^self._throw[parse;Unsupported attr type ($uValue.CLASS_NAME)]}
					}
				}
			}
#			^case[table]{ someday -- use 1st and _last_ columns, including nameless tables (match) }
			^case[DEFAULT]{^self._throw[parse;Unsupported input value type ($uData.CLASS_NAME)]}
		}
	}
}


@_print[hData;sName][result]
$result[ $sName="^self._value[$hData;$sName]"]


@_value[hData;sName][result;uValue;i]
$uValue[$hData.$sName]
$result[^switch[$uValue.CLASS_NAME]{
	^case[string;int;double;void]{$uValue}
	^case[bool]{^if($uValue){true;false}}
	^case[hash]{^for[i](0;$uValue-1){$uValue.$i}[ ]}
}]


@_throw[sSource;sComment][result]
^throw[$self.CLASS_NAME;$sSource;$sComment]
