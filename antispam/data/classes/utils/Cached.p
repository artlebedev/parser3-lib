############################################################
# $Id: Cached.p,v 1.3 2011-03-25 09:02:32 misha Exp $

@CLASS
Cached


@create[hParams]
$hParams[^hash::create[$hParams]]
$hData[^hash::create[]]
$bDisableCaching($hParams.bDisableCaching)


@exec[sKey;jBody;hParams]
$hParams[^hash::create[$hParams]]
^if($bDisableCaching || $hParams.bSkipCaching || !^hData.contains[$sKey]){
	$hData.[$sKey][dummy] ^rem{ *** required if jBoby execution triggers an exception. todo@ need an option for switching this feature on and off *** }
	$hData.[$sKey][^self._process[$sKey]{$jBody}[$hParams]]
}
$result[$hData.$sKey]


@get[sKey]
$result[$hData.$sKey]


@put[sKey;uValue]
$hData.[$sKey][$uValue]
$result[]


@delete[sKey]
^hData.delete[$sKey]
$result[]


@contains[sKey]
$result(^hData.contains[$sKey])


@add[hValue]
^hData.add[$hValue]
$result[]


@hash[]
$result[$hData]


@disableCaching[]
$bDisableCaching(true)


@enableCaching[]
$bDisableCaching(false)


@_process[sKey;jBody;hParams]
$result[$jBody]
