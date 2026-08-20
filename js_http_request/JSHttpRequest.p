###########################################################################
# $Id: JSHttpRequest.p,v 1.12 2007-12-11 15:39:07 misha Exp $
#
# class JSHttpRequest for working with
#	JsHttpRequest <http://dklab.ru/lib/JsHttpRequest/>
#	by Dmitry Koterov
# based on some methods from Sergey M. <http://www.parser.ru/forum/?id=41408>
# changes for working with JsHttpRequest 5 from MadCow and Sergey M.
# table for decode %u0430 & Co based on Eugene Sperance table
#
###########################################################################


@CLASS
JSHttpRequest


###########################################################################
@auto[]
$sJsClassNameDefault[JsHttpRequest]
$bInitialized(0)

$sJsClassName[$sJsClassNameDefault]
$bOldStyle(0)
#end @auto[]



###########################################################################
@init[hParam][tField]
^if(def $hParam){
	$hParam[^hash::create[$hParam]]
	^if(def $hParam.sJsClassName){
		$sJsClassName[$hParam.sJsClassName]
	}
	^if(def $hParam.bOldStyle){
		$bOldStyle(^hParam.bOldStyle.int(0))
	}
	
	^if(def $hParam.bForce){
		$bInitialized(^hParam.bForce.int(0))
	}
	
	^if(def $hParam.bAllowUnicodeChars){
		$bAllowUnicodeChars(^hParam.bAllowUnicodeChars.int(0))
	}
}
^if(!$bInitialized){
	$bInitialized(1)

	$tField[^request:query.match[^^(?:.*)(?:&|^^)JsHttpRequest=(?:(\d+)-)?([^^&]+)((?:&|^$).*)^$]]
	$ID[$tField.1]
	$LOADER[$tField.2]
}
#end @init[]



###########################################################################
@decodeRequest[]
^if(^self._isForm[]){
	$result[^hash::create[$form:fields]]
}{
	$result[^self.decodeText[$request:query]]
	^if(def $request:body){^result.add[^self.decodeText[$request:body]]}
}
#end @decodeRequest[]



###########################################################################
@printResponse[sText;uVar][hData;hLoader]
^if($bOldStyle){
	$result[${sJsClassName}.dataReady('^self.getId[]', '$sText', ^self._object2js[$uVar])]
}{
	$hData[
		$.script[
			$.sContentType[text/javascript]
			$.sPrefix[${sJsClassName}.dataReady^(]
			$.sSuffix[^)]
		]
		$.xml[
			$.sContentType[text/plain]
			$.sPrefix[]
			$.sSuffix[]
		]
		$.form[
			$.sContentType[text/html]
			$.sPrefix[<script type="text/javascript" language="JavaScript"><!--
				top && top.JsHttpRequestGlobal && top.JsHttpRequestGlobal.dataReady^(
			]
			$.sSuffix[^)//--></script>]
		]
		$._default[
			$.sContentType[text/plain]
			$.sPrefix[]
			$.sSuffix[]
		]
	]
	$hLoader[$hData.[^self.getLoader[]]]
	$result[$hLoader.sPrefix { 'id':'^self.getId[]', 'js':^self._object2js[$uVar], 'text':'^taint[js][$sText]' } $hLoader.sSuffix]

	$response:content-type[
		$.value[$hLoader.sContentType]
		$.charset[$response:charset]
	]
}
#end @printResponse[]



###########################################################################
@decodeText[sText][_tmp]
^if(!def $tDecode){
	$tDecode[^self._getDecodeTable[]]
}

$result[^hash::create[]]

$_tmp[^sText.match[(?:^^|&|\?)([^^=]+)=([^^&]+)][gm]{$result.[^self._decode[$match.1]][^self._decode[$match.2]]}]
#end @decodeText[]



###########################################################################
@getId[]
^self.init[]
$result[$self.ID]
#end @getId[]



###########################################################################
@getLoader[]
^self.init[]
$result[$self.LOADER]
#end @getLoader[]



###########################################################################
@_isForm[]
^self.init[]
$result($self.LOADER eq "form")
#end @_isForm[]



###########################################################################
# carefull: for empty strings returned 'null'
@_object2js[uVar]
$result[]
^if(!(
	($uVar is "bool" && ($uVar && ^self._return[true] || ^self._return[false]))
	|| (!def $uVar && ^self._return[null])
	|| ($uVar is "string" && ^self._return[^self._string2js[$uVar]])
	|| ($uVar is "double" && ^self._return[$uVar])
	|| ($uVar is "int" && ^self._return[$uVar])
	|| ($uVar is "table" && (($uVar && ^self._return[^self._table2js[$uVar]]) || ^self._return[null]))
	|| ($uVar is "hash" && (($uVar && ^self._return[^self._hash2js[$uVar]]) || ^self._return[null]))
	|| ($uVar is "date" && ^self._return[new Date(^uVar.unix-timestamp[]000)])
)){
	^self._return[null]
}
#end @_object2js[]



###########################################################################
@_return[sType]
$caller.result[$sType]
$result(1)
#end @_return[]



###########################################################################
@_decode[sText]
$result[^taint[^sText.replace[$tDecode]]]
^if(def $result && $bAllowUnicodeChars){
	$result[^result.match[%u([\dA-F]{4})][gi]{&#x$match.1^;}]
}
#end @_decode[]



###########################################################################
@_string2js[sData]
$result['^taint[js][$sData]']
#end @_string2js[]



###########################################################################
@_hash2js[hData][bIsHashOfBool;sKey;uValue]
$bIsHashOfBool(1)
# check if our hash is hash of bool with only 'true' values
^hData.foreach[sKey;uValue]{
	^if($bIsHashOfBool && !($uValue is "bool" && $uValue)){
		$bIsHashOfBool(0)
	}
}

^if($bIsHashOfBool){
	$result[[
		^hData.foreach[sKey;]{
			^self._string2js[$sKey]
		}[, ]
	]]
}{
	^rem{ *** in other case return associated array *** }
	$result[{
		^hData.foreach[sKey;uValue]{
			^self._string2js[$sKey]:
			^if($uValue is "double" || $uValue is "bool" || $uValue is "int"){
				^self._object2js($uValue)
			}{
				^self._object2js[$uValue]
			}
		}[, ]
	}]
}
#end @_hash2js[]



###########################################################################
@_table2js[tData][tKeys]
$tKeys[^tData.columns[]]
^if($tKeys){
	$result[[
		^tData.menu{
			{
				^tKeys.menu{
					^self._string2js[$tKeys.column]:^self._string2js[$tData.[$tKeys.column]]
				}[, ]
			}
		}[, ]
	]]
}{
	^rem{ *** nameless tables are deprecated, lah. *** }
	$result[null]
}
#end @_table2js[]



###########################################################################
@_getDecodeTable[]
$result[^table::create{from	to
%0D%0A	^taint[^#0A]
%0D	^taint[^#0A]
%0A	^taint[^#0A]
%09	^taint[^#09]
%20	^#20
%21	!
%22	"
%23	#
%24	^$
%25	%
%26	&
%27	'
%28	(
%29	)
%2B	+
%2C	,
%3A	:
%3B	^;
%3C	<
%3D	=
%3E	>
%3F	?
%5B	^[
%5C	\
%5D	^]
%5E	^^
%60	`
%7B	^{
%7C	|
%7D	^}
%7E	~
%A0	^#A0
%A7	§
%A9	©
%AB	«
%AE	®
%B0	°
%B1	±
%BB	»
%u0430	à
%u0431	á
%u0432	â
%u0433	ã
%u0434	ä
%u0435	å
%u0451	¸
%u0436	æ
%u0437	ç
%u0438	è
%u0439	é
%u043A	ê
%u043B	ë
%u043C	ì
%u043D	í
%u043E	î
%u043F	ï
%u0440	ð
%u0441	ñ
%u0442	ò
%u0443	ó
%u0444	ô
%u0445	õ
%u0446	ö
%u0447	÷
%u0448	ø
%u0449	ù
%u044A	ú
%u044B	û
%u044C	ü
%u044D	ý
%u044E	þ
%u044F	ÿ
%u0410	À
%u0411	Á
%u0412	Â
%u0413	Ã
%u0414	Ä
%u0415	Å
%u0401	¨
%u0416	Æ
%u0417	Ç
%u0418	È
%u0419	É
%u041A	Ê
%u041B	Ë
%u041C	Ì
%u041D	Í
%u041E	Î
%u041F	Ï
%u0420	Ð
%u0421	Ñ
%u0422	Ò
%u0423	Ó
%u0424	Ô
%u0425	Õ
%u0426	Ö
%u0427	×
%u0428	Ø
%u0429	Ù
%u042A	Ú
%u042B	Û
%u042C	Ü
%u042D	Ý
%u042E	Þ
%u042F	ß
%u2013	–
%u2014	—
%u201C	“
%u201D	”
%u201E	„
%u2026	…
%u2030	‰
%u20AC	ˆ
%u2116	¹
%u2122	™
}]
#end @_getDecodeTable[]



