###########################################################################
# $Id: Lib.p,v 1.22 2011-05-10 02:49:45 misha Exp $
###########################################################################


@CLASS
Lib



###########################################################################
# cut trailing and leading chars $sChars (whitespaces by default) for $sText
@trim[sText;sChars][result]
^if(def $sText){
	$result[^sText.trim[both;$sChars]]
}{
	$result[]
}
#end @trim[]



###########################################################################
# print link to $sURI with attributes $uAttr (string or hash) if $sURI specified, otherwise just print $sLabel
@href[sURI;sLabel;uAttr][result;sKey;sValue]
^if(!def $sLabel){$sLabel[$sURI]}
^if(def $sURI){
	$result[<a href="$sURI"^if(def $uAttr){^if($uAttr is "string"){ $uAttr}{^if($uAttr is "hash"){^uAttr.foreach[sKey;sValue]{ ^taint[$sKey]="$sValue"}}}}>$sLabel</a>]
}{
	$result[$sLabel]
}
#end @href[]



###########################################################################
# set location header for redirecting to $sURI and prevent caching
# $.bExternal option makes redirect 
@location[sURI;hParam][result;p1;p2;sRequestURL;iQueryPos;iSlashPos;p]
^if(def $sURI){
	^try{
		^cache(0)
	}{
		$exception.handled(true)
	}
	^if(def $hParam && ($hParam.bExternal || $hParam.is_external) && ^sURI.pos[://] < 1){
		^if(^sURI.pos[./]==0){
			$sRequestURL[^if(def $request:uri){$request:uri}{/}]

			$iQueryPos(^sRequestURL.pos[?])
			^if($iQueryPos<0){
				$iQueryPos(^sRequestURL.length[])
			}

			$iSlashPos(0)
			^while(true){
				$p(^sRequestURL.pos[/]($iSlashPos+1))
				^if($p > 0 && $p < $iQueryPos){
					$iSlashPos($p)
				}{
					^break[]
				}
			}
			$sURI[^sRequestURL.left($iSlashPos+1)^sURI.mid(2)]
		}
		$response:location[http^if(def $env:HTTPS){s}://^if(def $env:HTTP_HOST){$env:HTTP_HOST}{$env:SERVER_NAME^if(def $env:SERVER_PORT && $env:SERVER_PORT ne "80"){:$env:SERVER_PORT}}$sURI]
	}{
		$response:location[$sURI]
	}
}
$result[]
#end @location[]



###########################################################################
@list[uData;sColumnName;sDefault;sEncloser][result;s;t]
$result[]
^switch[$uData.CLASS_NAME]{
	^case[string;int;double]{
		$s[$uData]
		$s[^s.trim[both][^#09, ^#0A^#0D]]
		^if(def $s){
			$result[${sEncloser}${s}$sEncloser]
		}
	}
	^case[table]{
		^if(!def $sColumnName){
			$t[^uData.columns[]]
			$sColumnName[^if(def $t.column){$t.column}{0}]
		}
		$result[^uData.menu{${sEncloser}${uData.$sColumnName}$sEncloser}[,]]
	}
	^case[hash]{
		$result[^uData.foreach[s;]{${sEncloser}${s}$sEncloser}[,]]
	}
}
^if(!def $result && def $sDefault){
	$result[$sDefault]
}
#end @list[]



###########################################################################
# check email format
@isEmail[sEmail][result]
$result(
	def $sEmail
	&& ^sEmail.pos[@] > 0
	&& ^sEmail.match[^^(?:[-a-z\d\+\*\/\?!{}`~_%&'=^^^$#]+(?:\.[-a-z\d\+\*\/\?!{}`~_%&'=^^^$#]+)*)@(?:[-a-z\d_]+\.){1,60}[a-z]{2,6}^$][i]
)
#end @isEmail[]



###########################################################################
# print $iNum as a binary string
@dec2bin[iNum;iLength][result;i]
$i(1 << (^iLength.int(24)-1))
$result[^while($i>=1){^if($iNum & $i){1}{0}$i($i >> 1)}]
#end @dec2bin[]



###########################################################################
# makes hash of tables from $tData. if $sKeyColumn is not specified 'parent_id' will be used
@createTreeHash[tData;sKeyColumn][result]
^if($tData is "table"){
	$result[^tData.hash[^if(def $sKeyColumn){$sKeyColumn}{parent_id}][$.distinct[tables]]]
}{
	$result[^hash::create[]]
}
#end @createTreeHash[]



###########################################################################
# print number. options $.iFracLength, $.sThousandDivider and $.sDecimalDivider are available
@numberFormat[dNumber;hParam][sNumber;iFracLength;iTriadCount;tPart;sIntegerPart;sMantissa;sNumberOut;tIncomplTriad;iZeroCount;sZero;sThousandDivider;iIncomplTriadLength]
$hParam[^hash::create[$hParam]]
$sNumber[$dNumber]
$tPart[^sNumber.split[.][lh]]
$sIntegerPart[^eval(^math:abs($tPart.0))[%.0f]]
$sMantissa[$tPart.1]
$iFracLength(^hParam.iFracLength.int(^sMantissa.length[]))
$sThousandDivider[^if(def $hParam.sThousandDivider){$hParam.sThousandDivider}{&nbsp^;}]

^if(^sIntegerPart.length[] > 4){
	$iIncomplTriadLength(^sIntegerPart.length[] % 3)
	^if($iIncomplTriadLength){
		$tIncomplTriad[^sIntegerPart.match[^^(\d{$iIncomplTriadLength})(\d*)]]
		$sNumberOut[$tIncomplTriad.1]
		$sIntegerPart[$tIncomplTriad.2]
		$iTriadCount(1)
	}{
		$sNumberOut[]
		$iTriadCount(0)
	}
	$sNumberOut[$sNumberOut^sIntegerPart.match[(\d{3})][g]{^if($iTriadCount){$sThousandDivider}$match.1^iTriadCount.inc(1)}]
}{
	$sNumberOut[$sIntegerPart]
}

$result[^if($dNumber < 0){-}$sNumberOut^if($iFracLength > 0){^if(def $hParam.sDecimalDivider){$hParam.sDecimalDivider}{,}^sMantissa.left($iFracLength)$iZeroCount($iFracLength-^if(def $sMantissa)(^sMantissa.length[])(0))^if($iZeroCount > 0){$sZero[0]^sZero.format[%0${iZeroCount}d]}}]
#end @numberFormat[]



###########################################################################
# looks over hash elements in specified order
@foreach[hHash;sKeyName;sValueName;jCode;sSeparator;sDirection][result;tKey]
^if($hHash is "hash"){
	$tKey[^hHash._keys[]]
	^if(!def $sDirection){$sDirection[asc]}
	^try{
		^tKey.sort($tKey.key)[$sDirection]
	}{
		$exception.handled(true)
		^tKey.sort{$tKey.key}[$sDirection]
	}
	$result[^tKey.menu{^if(def $sKeyName){$caller.[$sKeyName][$tKey.key]}^if(def $sValueName){$caller.[$sValueName][$hHash.[$tKey.key]]}$jCode}[$sSeparator]]
}{
	^throw[Lib;foreach;Variable must be hash]
}
#end @foreach[]



###########################################################################
# returns hash with parser version
@getParserVersion[][result]
$result[^hash::create[]]
^if(def $env:PARSER_VERSION){
	^env:PARSER_VERSION.match[^^(.*?\d+)\.((\d+)(?:\.(\d+))?)(\S*)(?:\s+(.+))?^$][]{
		$result[
			$.sName[$match.1]
			$.iVersion(^match.3.int(0))
			$.iSubVersion(^match.4.int(0))
			$.dFullVersion(^match.2.double(0))
			$.sSp[$match.5]
			$.sComment[$match.6]
		]
	}
}
#end @getParserVersion[]



###########################################################################
# every odd call returns $sColor1, every even - $sColor2, without parameters - reset sequence
@color[sColor1;sColor2][result]
^if(!def $iColorSwitcher || (!def $sColor1 && !def $sColor2)){$iColorSwitcher(false)}
$result[^if($iColorSwitcher){$sColor2}{$sColor1}]
$iColorSwitcher(!$iColorSwitcher)
#end @color[]



###########################################################################
@getType[uValue][result]
^try{
	$result[$uValue.CLASS_NAME]
}{
	$exception.handled(true)
}
^if(!def $result){
	$result[^switch(true){
		^case($uValue is "string"){string}
		^case($uValue is "int"){int}
		^case($uValue is "double"){double}
		^case($uValue is "date"){date}
		^case($uValue is "hash"){hash}
		^case($uValue is "table"){table}
		^case($uValue is "bool"){bool}
		^case($uValue is "image"){image}
		^case($uValue is "file"){file}
		^case($uValue is "xnode"){xnode}
		^case($uValue is "xdoc"){xdoc}
		^case[DEFAULT]{}
	}]
}
#end @getType[]



###########################################################################
# creates 2-levels hash
@create2LevelHash[uData;sField1;sField2][result;sValue1;hValue]
$result[^hash::create[]]
^if($uData is "table"){
	^uData.menu{
		$sValue1[$uData.$sField1]
		^if(!def $result.$sValue1){$result.[$sValue1][^hash::create[]]}
		$result.[$sValue1].[$uData.$sField2][$uData.fields]
	}
}{
	^if($uData is "hash"){
		^uData.foreach[;hValue]{
			$sValue1[$hValue.$sField1]
			^if(!def $result.$sValue1){$result.[$sValue1][^hash::create[]]}
			$result.[$sValue1].[$hValue.$sField2][$hValue]
		}
	}
}
#end @create2LevelHash[]



##############################
##############################
# deprecated

# use 'list' instead
@makeList[uData;sColumnName;sDefault;sEncloser]
$result[^self.list[$uData;$sColumnName;;$sEncloser]]
^if(!def $result){
	$result[^if(def $sDefault){$sDefault}{0}]
}
