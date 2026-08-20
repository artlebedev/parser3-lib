###########################################################################
# $Id: Logger.p,v 1.2 2011-10-31 06:13:37 misha Exp $

@CLASS
Logger


@auto[]
$tRepl[^table::create[nameless]{^taint[^#0A]	^taint[^#20]}]



@create[sFileName;hParams]
$hParams[^hash::create[$hParams]]
$self.sFileName[$sFileName]
$self.sEncloser[^if(^hParams.bEscapeStrings.bool(true)){"}]
$self.sValuesSeparator[^if(def $hParams.sValuesSeparator){$hParams.sValuesSeparator}{, }]
$self.sEndOfRecord[^if(def $hParams.sEndOfRecord){$hParams.sEndOfRecord}{^#0A}]



@write[uData;hParams][s;k;v;dt;sSeparator]
$hParams[^hash::create[$hParams]]
^if($uData is "string"){
	$s[$uData]
}{
	^if($uData is "hash"){
		$sSeparator[^if(def $hParams.sValuesSeparator){$hParams.sValuesSeparator}{$self.sValuesSeparator}]
		$s[^uData.foreach[k;v]{${k}: ^self._print[$v]}[$sSeparator]]
	}{
		^rem{ *** todo@ *** }
		^throw[$self.CLASS_NAME;write;Unsupported type $uData.CLASS_NAME]
	}
}
^if(def $s){
	$s[$s^if(def $hParams.sEndOfRecord){$hParams.sEndOfRecord}{$self.sEndOfRecord}]
	^s.save[append;$self.sFileName]
}
$result[]



@_print[uValue][k;v;c]
$result[^switch[$uValue.CLASS_NAME]{
	^case[void;string]{^self._toLine[$uValue]}
	^case[int;double]{$uValue}
	^case[bool]{^if($uValue){true}{false}}
	^case[date]{^uValue.sql-string[]}
	^case[table]{[$c[^uValue.columns[]]^if($c){[^c.menu{${self.sEncloser}${c.column}$self.sEncloser}[, ]]^if($uValue){, }^uValue.menu{[^c.menu{^self._toLine[$uValue.[$c.column]]}[, ]]}[, ]}{Nameless tables are not supported}]}
	^case[hash]{{^uValue.foreach[k;v]{${k}: ^self._print[$v]}[, ]}}
	^case[DEFAULT]{Unsupported type $uValue.CLASS_NAME}
}]


@_toLine[sText]
$result[$self.sEncloser^if(def $sText){^sText.replace[$tRepl]}$self.sEncloser]

