@CLASS
MyAntispam

@USE
antispam/Antispam.p

@BASE
Antispam


@create[hParams]
$hParams[^hash::create[$hParams]]
^BASE:create[$hParams]

^if(!def $hParams.hAction.hRealAttr){
	$bDefaultRealAction(true)
}
^if(!def $hParams.hAction.hFakeAttr){
	$bDefaultFakeAction(true)
}

$hActionClass[^hash::create[]]
$bShowForm(true)



###########################################################################
@exec[jCode;jErrorHandler]
$result[]
^try{
	$result[^BASE:exec{${jCode}$bShowForm(false)}]
}{
	^switch[$exception.type]{
		^case[$self.CLASS_NAME]{
			$exception.handled(true)
			$bShowForm(false)

			^switch[$exception.source]{
				^case[unknown-uid]{
					$result[<p class="alert">Ваше сообщение уже было добавлено ранее.</p>]
				}
				^case[empty-uid;suspected-content]{
					^rem{ *** с большой вероятностью спамер *** }
					$result[^self.printSpamError[]]
				}
				^case[fake-uid-exist;no-real-uid;referer]{
					^rem{ *** точно спамер *** }
					$result[^self.printSpamError[]]
				}
			}
		}

		^case[check.fields]{
			$exception.handled(true)
			$result[<p class="error">Не заполнены обязательные поля формы.</p>]
		}
		
		^case[DEFAULT]{
			$caller.exception[$exception]
			$result[$jErrorHandler]
		}
	}
}
#end @exec[]



###########################################################################
@print[jForm;jErrorHandler][sType;tUUID]
^if($bShowForm){
	^rem{ *** little hack, because it's impossible to define junction-variable in constructor *** }
	^if($bDefaultRealAction){
		$FIELD.hAction.hRealAttr[$.class{^self._getClassName[block]}]
	}
	^if($bDefaultRealAction){
		$FIELD.hAction.hFakeAttr[$.class{^self._getClassName[none]}]
	}

	^try{
		$result[^BASE:print{$jForm}]

		^if($hActionClass){
			$result[$result
				<style>
				^hActionClass.foreach[sType;tUUID]{
					^tUUID.menu{input.$tUUID.uuid}[, ] {
						display: $sType^;
					}
				}
				</style>
			]
		}
	}{
		^if($exception.type eq $self.CLASS_NAME){
			$exception.handled(true)
			$result[^self.printSpamError[]]
		}{
			$caller.exception[$exception]
			$result[$jErrorHandler]
		}
	}
}
#end @print[]



@printSpamError[]
<p class="error">Обнаружены признаки спам-активности. Если вы не робот — обратитесь к администратору сайта.</p>



@_getClassName[sType]
$result[C^math:uid64[]]
^if(!def $hActionClass.$sType){
	$hActionClass.[$sType][^table::create{uuid}]
}
^hActionClass.[$sType].append{$result}
