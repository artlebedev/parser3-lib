###########################################################################
# $Id: Doc.p,v 1.4 2010-03-01 00:37:37 misha Exp $
###########################################################################


@CLASS
Doc



###########################################################################
# print $xDoc as string without DOCTYPE and XML declaration
@toString[xDoc]
$result[^xDoc.string[
	$.omit-xml-declaration[yes]
	$.indent[no]
]]
$result[^result.match[<!DOCTYPE[^^>]+>\s*][i]{}]
$result[^result.trim[]]
#end @toString[]



###########################################################################
@create[sXML;hParam]
$result[^xdoc::create{<?xml version="1.0" encoding="^if(def $hParam && def $hParam.sCharset){$hParam.sCharset}{$request:charset}"?>
$sXML}]
#end @create[]
