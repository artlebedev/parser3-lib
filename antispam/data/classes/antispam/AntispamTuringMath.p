###########################################################################
# $Id: AntispamTuringMath.p,v 1.1 2010-06-03 13:58:22 misha Exp $

@CLASS
AntispamTuringMath

@USE
AntispamTuring.p

@BASE
AntispamTuring



###########################################################################
@auto[]
$tOperation[^table::create{sMethodName	sTitle
_plus	плюc
_plus	прибaвить
_plus	слoжить с
_minus	минyc
_minus	вычеcть
}]
#end @auto[]



###########################################################################
@getTuringTest[][iValue1;iValue2;jMethod]
$iValue1(^math:random(9)+1)
$iValue2(^math:random(9)+1)
^tOperation.offset(^math:random($tOperation))

$jMethod[$self.[$tOperation.sMethodName]]
^self.set[^jMethod($iValue1;$iValue2)]

$result[$iValue1 $tOperation.sTitle $iValue2]
#end @getTuringTest[]



###########################################################################
@_plus[iValue1;iValue2]
$result($iValue1 + $iValue2)
#end @_plus[]



###########################################################################
@_minus[iValue1;iValue2]
$result($iValue1 - $iValue2)
#end @_minus[]
