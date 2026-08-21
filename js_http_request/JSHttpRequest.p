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
%u0430	а
%u0431	б
%u0432	в
%u0433	г
%u0434	д
%u0435	е
%u0451	ё
%u0436	ж
%u0437	з
%u0438	и
%u0439	й
%u043A	к
%u043B	л
%u043C	м
%u043D	н
%u043E	о
%u043F	п
%u0440	р
%u0441	с
%u0442	т
%u0443	у
%u0444	ф
%u0445	х
%u0446	ц
%u0447	ч
%u0448	ш
%u0449	щ
%u044A	ъ
%u044B	ы
%u044C	ь
%u044D	э
%u044E	ю
%u044F	я
%u0410	А
%u0411	Б
%u0412	В
%u0413	Г
%u0414	Д
%u0415	Е
%u0401	Ё
%u0416	Ж
%u0417	З
%u0418	И
%u0419	Й
%u041A	К
%u041B	Л
%u041C	М
%u041D	Н
%u041E	О
%u041F	П
%u0420	Р
%u0421	С
%u0422	Т
%u0423	У
%u0424	Ф
%u0425	Х
%u0426	Ц
%u0427	Ч
%u0428	Ш
%u0429	Щ
%u042A	Ъ
%u042B	Ы
%u042C	Ь
%u042D	Э
%u042E	Ю
%u042F	Я
%u2013	–
%u2014	—
%u201C	“
%u201D	”
%u201E	„
%u2026	…
%u2030	‰
%u20AC	€
%u2116	№
%u2122	™
}]
#end @_getDecodeTable[]



