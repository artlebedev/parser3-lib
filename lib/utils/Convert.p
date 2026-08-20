###########################################################################
# $Id: Convert.p,v 1.3 2010-10-14 05:12:52 misha Exp $
###########################################################################


@CLASS
Convert

@USE
Lib.p


@auto[]
$sClassName[Convert]



@object2str[uValue;sType]
^if(!def $sType){
	$sType[^if($uValue is "double" || $uValue is "int"){^Lib:getType($uValue)}{^Lib:getType[$uValue]}]
}
$result[^switch[$sType]{
	^case[string]{$uValue}
	^case[double;int]{$uValue}
	^case[date]{^self.date2str[$uValue]}
	^case[bool]{^self.bool2str($uValue)}
	^case[hash]{^self.hash2str[$uValue]}
	^case[table]{^self.table2str[$uValue]}
	^case[file]{^self.file2str[$uValue]}
	^case[xdoc]{^self.xdoc2str[$uValue]}
	^case[xnode]{^self.xnode2str[$uValue]}
	^case[DEFAULT]{^throw[$sClassName;Converting '$sType' to string not implemented.]} ^rem{ *** image, user objects *** }
}]



@str2object[sType;sValue]
^switch[$sType]{
	^case[string]{$result[$sValue]}
	^case[double]{$result(^sValue.double[])}
	^case[int]{$result(^sValue.int[])}
	^case[date]{$result[^self.str2date[$sValue]]}
	^case[bool]{$result(^self.str2bool[$sValue])}
	^case[hash]{$result[^self.str2hash[$sValue]]}
	^case[table]{$result[^self.str2table[$sValue]]}
	^case[file]{$result[^self.str2file[$sValue]]}
	^case[xdoc]{$result[^self.str2xdoc[$sValue]]}
	^case[xnode]{$result[^self.str2xnode[$sValue]]}
	^case[DEFAULT]{^throw[$sClassName;Converting string to '$sType' not implemented.]} ^rem{ *** image, user objects *** }
}


@bool2str[bValue]
$result[^if($bValue){1}{0}]


@date2str[dtValue]
$result[^dtValue.sql-string[]]


@table2str[tValue][tColumn]
$tColumn[^tValue.columns[]]
$result[^tColumn.menu{$tColumn.column^#09}^#0A^tValue.menu{^tColumn.menu{$tValue.[$tColumn.column]^#09}}[^#0A]]


@hash2str[hValue]
$result[^self.table2str[^self.hash2table[$hValue]]]


@file2str[fValue]
$result[^fValue.base64[]]


@xdoc2str[xDoc]
$result[^xDoc.string[
	$.omit-xml-declaration[yes]
	$.indent[no]
]]
$result[^result.match[<!DOCTYPE[^^>]+>\s*][i]{}]
$result[^result.trim[]]


@xnode2str[xNode]
$result[^self.xdoc2str[^self.xnode2xdoc[$xNode]]]


@str2bool[sValue]
$result(^sValue.bool[])


@str2date[sValue]
$result[^date::create[$sValue]]


@str2table[sValue]
$result[^table::create{$sValue}]


@str2hash[sValue]
$result[^self.table2hash[^self.str2table[$sValue]]]


@str2file[sValue]
$result[^file::base64[$sValue]]


@str2xdoc[sValue]
$result[^xdoc::create{<?xml version="1.0" encoding="$request:charset"?>$sValue}]


@str2xnode[sValue][xDoc]
$result[^self.xdoc2xnode[^self.str2xdoc[$sValue]]]



@hash2table[hData;sParent][sKey;uValue;sType;sValue]
$result[^table::create{parent	key	type	value}]
^hData.foreach[sKey;uValue]{
	$sType[^Lib:getType[$uValue]]
	$sValue[^switch[$sType]{
		^case[hash]{}
		^case[table]{^throw[$sClassName;Not implemented yet.]^self.table2str[$uValue]}
		^case[DEFAULT]{^self.object2str[$uValue;$sType]}
	}]
	^result.append{^taint[$sParent]	^taint[$sKey]	$sType^if(def $sValue){	^taint[$sValue]}}
	^if($sType eq "hash"){
		^result.join[^self.hash2table[$uValue;$sKey]]
	}
}


@table2hash[tData;hTree;sParent][tLevel]
$result[^hash::create[]]
^if(!def $hTree){
	$hTree[^tData.hash[parent][$.distinct[tables]]]
	$sParent[]
}
^if($hTree.$sParent){
	$tLevel[$hTree.$sParent]
	^tLevel.menu{
		$result.[$tLevel.key][^switch[$tLevel.type]{
			^case[hash]{^self.table2hash[;$hTree;$tLevel.key]}
			^case[table]{^throw[$sClassName;Not implemented yet.]^self.str2table[^taint[as-is][$uValue]]}
			^case[DEFAULT]{^self.str2object[$tLevel.type;^taint[as-is][$tLevel.value]]}
		}]
	}
}


@xnode2xdoc[xNode][_tmp]
$result[^self.str2xdoc[<root/>]]
$_tmp[^result.documentElement.appendChild[^result.importNode[$xNode](1)]]


@xdoc2xnode[xDoc]
$result[$xDoc.documentElement.firstChild]


