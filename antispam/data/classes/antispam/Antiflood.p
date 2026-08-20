@CLASS
Antiflood

@USE
Antispam.p

@BASE
Antispam


@create[hParams]
$hParams[^hash::create[$hParams]]
^if(!def $hParams.hFields){
	$hParams.hFields[$.bRefuseUnknown(false)]
}
^if(!def $hParams.hAction){
	$hParams.hAction[$.bRealRequired(false)]
}

^BASE:create[$hParams]
