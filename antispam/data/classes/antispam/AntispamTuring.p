###########################################################################
# $Id: AntispamTuring.p,v 1.1 2010-10-13 22:58:06 misha Exp $

# It is used as a base for AntispamTuringMath and AntispamTuringCaptcha
# You should'n create the instance of this class.

@CLASS
AntispamTuring

@USE
Antispam.p

@BASE
Antispam



###########################################################################
@auto[]



###########################################################################
@create[hParam]
^BASE:create[$hParam]

$hParam[^hash::create[$hParam]]
$sTuringAnswerFieldName[^if(def $hParam.sTuringAnswerFieldName){$hParam.sTuringAnswerFieldName}{result}]
#end @create[]



###########################################################################
@set[sValue]
^BASE:set[^sValue.lower[]]
$result[]
#end @set[]



###########################################################################
@_checkAndExec[jCode][sValue]
^BASE:_checkAndExec[]
$sValue[^self._getVisitorTuringAnswer[]]
^if(!def $sValue){
	^self._warning[turing.empty;Turing test result is empty]
}{
	^if($sValue ne ^self.get[]){
		^self._warning[turing.failed;Turing test is failed]
	}
}
$result[$jCode]



###########################################################################
@_getVisitorTuringAnswer[]
$result[$form:[$sTuringAnswerFieldName]]
$result[^result.lower[]]


