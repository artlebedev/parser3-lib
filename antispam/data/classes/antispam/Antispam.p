###########################################################################
# $Id: Antispam.p,v 1.24 2011-08-17 03:05:48 misha Exp $

# pre-requirements: Parser 3.2.2 or higher

@CLASS
Antispam



###########################################################################
@auto[]
$HF[^hash::create[]]

# backward
$sClassName[Antispam]
#end @auto[]



###########################################################################
@create[hParam][sDummy]
$hParam[^hash::create[$hParam]]
^self._declare[]

^if(def $hParam.hAction.iFakeCount && ^hParam.hAction.iFakeCount.int(0) > 100){
	^self._abort[create;^$.iFakeCount value is too high (^hParam.hAction.iFakeCount.int(0))]
}

^if(def $hParam.sDataDir){
	$DATA_DIR[$hParam.sDataDir]
}
^if(def $hParam.iLogAccess){
	$LOG_ACCESS(^hParam.iLogAccess.int(0))
}
^if($hParam.hFields is "hash"){
	^FIELDS.add[$hParam.hFields]
}
^if($hParam.hFilter is "hash"){
	^FILTER.add[$hParam.hFilter]
}
^if($hParam.hReferer is "hash"){
	^REFERER.add[$hParam.hReferer]
}
^if(def $hParam.sFormTag){
	$FORM.sTag[$hParam.sFormTag]
}
^if($hParam.hAction is "hash"){
	^FIELD.hAction.add[$hParam.hAction]
}

^if($hParam.hUid is "hash"){
	^FIELD.hUid.add[$hParam.hUid]
}
^if($hParam.hExpires is "hash"){
	^EXPIRES.add[$hParam.hExpires]
}

# create directory if needed
^if(!-d $DATA_DIR){
	$sDummy[dummy]
	^sDummy.save[$DATA_DIR/dummy]
}

^self._preventCacheing[]
^self._open[]
^self._init[$form:[$FIELD.hUid.sName]]
#end @create[]



###########################################################################
@print[jForm;jErrorHandler]
^try{
	$result[^self._checkAndPrint{$jForm}]

	^self._log[print;ok]
	^self._release[]
}{
	^self._log[print;fail;$exception]
	^self._release[]
	$caller.exception[$exception]
	$result[$jErrorHandler]
}
#end @print[]



###########################################################################
# if hashfile contains the record with posted $form:uid and spam is not detected the $jCode will be executed
@exec[jCode;jErrorHandler]
$result[]
^try{
	^if(def $form:[$FIELD.hUid.sName]){
		$result[^self._checkAndExec{$jCode}]

		^self._log[exec;ok]
		^self.clear[]
	}{
		^if(^env:REQUEST_METHOD.upper[] ne "GET"){
			^self._spam[empty-uid;Empty UID]
		}
	}
	^rem{ *** get new uids *** }
	^self.reinit[]
	^self._release[]
}{
	^self._log[exec;fail;$exception]
	^self._release[]
	$caller.exception[$exception]
	$result[$jErrorHandler]
}
#end @exec[]



###########################################################################
@get[]
$result[]
^VALUE.match[:(.+)^$][]{$result[$match.1]}
#end @get[]



###########################################################################
@set[sValue]
^if(^sValue.length[] > 3000){
	^self._abort[runtime;^$sValue is too long]
}
$VALUE[^if(def $VALUE){^VALUE.match[:.+^$][]{}}:$sValue]
^self._set[$UID;$VALUE;$EXPIRES.dUid]
^self._release[]
$result[]
#end @set[]



###########################################################################
# clear records from hashfile which are assosiated to current UID
@clear[][result]
^self._delete[$UID]
^self._delete[$VISITOR]
^self._cleanup[]
$result[]
#end @clear[]



###########################################################################
@reinit[][result]
^self._init[]
$result[]
#end @reinit[]



###########################################################################
# private methods. don't modify them

###########################################################################
@_declare[]
# path where hashfile files will be located
$DATA_DIR[/../temp]

# bit constants: which actions write to log
$LOG_MASK[
	$.print[
		$.ok(1)
		$.fail(2)
	]
	$.exec[
		$.ok(16)
		$.fail(32)
	]
]

$LOG_ACCESS(0)

$EXPIRES[
#	time for storing UID in hashfile, days (default -- 2 hours)
	$.dUid(2/24)

#	time for keeping the same UID, days (default -- 5 secs)
#	we don't change visitor's UID often then once in 5 secs or somebody could flood hashfile by putting something on F5 key
	$.dVisitor(5/24/60/60)
	
#	time for ban spammers, days
	$.dBan(0)
]

$FILENAME[_antispam]
$BAN_FLAG[banned]

$UID[]
$UIDS[^self._getEmptyUIDSTable[]]
$VISITOR[]
$VALUE[]

$REFERER[
#	refuse all requests with empty referers. if set to 'true' hRefuseEmpty mean nothing
	$.bRefuseEmpty(false)
#	define which requests with empty referers should be refused separately
	$.hRefuseEmpty[
		$.print(false)
		$.exec(true)
	]

#	list of allowed referers (empty list means allow any referer)
#	not in common name convention because name is used as a method param
	$.print[^table::create{sHref}]
	$.exec[^table::create{sHref}]
]

$FIELDS[
#	refuse request if field which is not into the form and allowed list is present into request
	$.bRefuseUnknown(true)
	$.tAllowed[^table::create{sName^#0Ado^#0Arequest^#0Alang^#0Apage^#0Amode}]
]

$FILTER[
	$.tMask[^table::create{dScore	sRegexp^#0A1	WMZ}]
	$.dThreshold(20)
]

$FORM[
#	search for <form/> in HTML
	$.sTag[form]
]

$FIELD[
#	modity form and add UID in <input type="hidden" name="uid" value="UID"/>
	$.hUid[
		$.sTag[input]
		$.sType[hidden]
		$.sName[uid]
	]

#	modify <input name="action"/> with any @type
	$.hAction[
		$.sTag[input]
		$.sType[]
		$.sName[action]

#		the valid submit field must be defined for accepting data
		$.bRealRequired(true)

#		number of additional fake fields which will be added
		$.iFakeCount(0)

#		first action always be fake
		$.bFakeFirst(true)

#		attributes will be modified for real action field (value can be junction)
		$.hRealAttr[
			$.value[+]
			$.class[r]
		]

#		attributes will be modified for fake actions fields (value can be junction)
		$.hFakeAttr[
			$.value[-]
			$.class[f]
		]
	]
]



###########################################################################
@_init[sUID]
$VISITOR[^self._visitor[]]
^if(def $sUID){
	$UID[$sUID]
	$VALUE[^self._get[$UID]]
}{
	$UID[^self._get[$VISITOR]]
	^if(def $UID){
		^if(^self._isBanned[]){
			$VALUE[]
		}{
			$VALUE[^self._get[$UID]]
		}
	}{
		$UID[^math:uuid[]]
		$UIDS[^self._fillUIDS[]]
		$VALUE[^self._pack[$UIDS]]

		^self._set[$VISITOR;$UID;$EXPIRES.dVisitor]

		^self._set[$UID;$VALUE;$EXPIRES.dUid]
	}
}
^if(def $VALUE && !$UIDS){
	$UIDS[^self._unpack[$VALUE]]
}
$result[]



###########################################################################
@_getValueSusp[sValue]
$result(0)
^if(def $sValue && $FILTER.tMask){
	^FILTER.tMask.menu{
		^result.inc(^FILTER.tMask.dScore.double(1) * ^sValue.match[$FILTER.tMask.sRegexp][gn])
	}
}



###########################################################################
@_isBanned[]
$result($UID eq $BAN_FLAG)



###########################################################################
# parse action's attributes
@_parse[sInput]
$result[^hash::create[]]
^if(def $sInput){
	^sInput.match[(\S+)="([^^"]+)"][g]{$result.[^match.1.lower[]][$match.2]}
}



###########################################################################
# print real action with new name add some fake actions
@_print[sTag;hAttr;sContent][hLocalAttr;hPrinted;iCount;iPos]
$hLocalAttr[^hash::create[$hAttr]]
^hLocalAttr.delete[name]
^if(def $FIELD.hAction.sType){
	$hLocalAttr.type[$FIELD.hAction.sType]
}

$hPrinted[^hash::create[]]
$iCount($UIDS)
^while($hPrinted < $iCount){
	$iPos(-1)
	^while($iPos<0 || $hPrinted.$iPos){
		$iPos(^math:random($iCount))
		^UIDS.offset[set]($iPos)
		^if($hPrinted==0 && $FIELD.hAction.bFakeFirst && !$UIDS.bFake){
			$iPos(-1)
		}
	}
	^self._input[$sTag;$sContent;^hLocalAttr.union[$.name[$UIDS.sValue]];$FIELD.hAction.[^if($UIDS.bFake){hFakeAttr}{hRealAttr}]]
	$hPrinted.[$iPos](true)
}

^if(def $FIELD.hAction.sType && $FIELD.hAction.sType ne $hAttr.type){
	^rem{ *** print original input if @type is changed *** }
	$result[$result^self._input[$sTag;$sContent;$hAttr]]
}



###########################################################################
@_input[sTag;sContent;hAttr;hAddon][sKey;sValue;sAttr]
^if(!($hAttr is "hash")){
	$hAttr[^hash::create[]]
}
^if($hAddon is "hash"){
	^hAddon.foreach[sKey;sValue]{
		$hAttr.$sKey[^if(def $hAttr.$sKey){$hAttr.$sKey }$sValue]
	}
}
$sAttr[^hAttr.foreach[sKey;sValue]{$sKey="$sValue"}[ ]]
$result[<$sTag $sAttr^if(def $sContent){>$sContent^if(def $hAddon.value){ $hAddon.value}</$sTag>}{/>}]



###########################################################################
@_open[][result]
^if(!def $HF.[$DATA_DIR/$FILENAME]){
	$HF.[$DATA_DIR/$FILENAME][^hashfile::open[$DATA_DIR/$FILENAME]]
}
$result[]



###########################################################################
@_preventCacheing[]
$response:expires[^date::create(2001;01;01;01;01;01)]
$response:cache-control[no-store, no-cache, must-revalidate, proxy-revalidate]
$response:pragma[no-cache]

# cancel caching if inside ^cache[]
^try{
	^cache(0)
}{
	$exception.handled(true)
}
$result[]



###########################################################################
# get record from hashfile
@_get[sKey][result]
$result[]
^if(def $sKey){
	$result[$HF.[$DATA_DIR/$FILENAME].[$sKey]]
}



###########################################################################
# put record to hashfile 
@_set[sKey;sValue;iExpire][result]
^if(def $sKey){
	$HF.[$DATA_DIR/$FILENAME].[$sKey][
		$.value[$sValue]
		^if(def $iExpire){
			$.expires($iExpire)
		}
	]
}
$result[]



###########################################################################
# delete record with $sKey from hashfile
@_delete[sKey][result]
^if(def $sKey){
	^HF.[$DATA_DIR/$FILENAME].delete[$sKey]
}
$result[]



###########################################################################
# sometimes compact hashfile
@_cleanup[][result]
^if(^math:random(100) < 4){
	^HF.[$DATA_DIR/$FILENAME].cleanup[]
}
$result[]



###########################################################################
@_release[][result]
^HF.[$DATA_DIR/$FILENAME].release[]
$result[]



###########################################################################
# generate visitor ID
@_visitor[][result]
$result[^if(def $env:REMOTE_ADDR){$env:REMOTE_ADDR}{NULL}:^if(def $env:HTTP_X_FORWARDED_FOR){$env:HTTP_X_FORWARDED_FOR}{NULL}]



###########################################################################
@_checkAndPrint[jForm][tInput;hAllowed;hForm;sKey]
^self._checkReferer[print]
$result[$jForm]
^if(!^self._isBanned[] && $result is "string"){
	^if($FIELDS.bRefuseUnknown){
		^rem{ *** check for unknown fields *** }
		$tInput[^result.match[name\s*=\s*(["'])(.*?)\1][gi]]
		$hAllowed[^tInput.hash[2][$.distinct(1)]]
		$hAllowed.[$FIELD.hUid.sName](1)
		^if($FIELDS.tAllowed){
			^hAllowed.add[^FIELDS.tAllowed.hash[sName]]
		}
		^if(^UIDS.locate[bFake;0]){
			$hAllowed.[$UIDS.sValue][]
		}

		$hForm[$form:fields]
		^hForm.sub[$hAllowed]
		^if($hForm){
			^self._spam[unknown-fields;Unknown fields were detected while showing form: ^hForm.foreach[sKey;]{'$sKey'}[, ]]
		}
	}
	$result[^result.match[(</$FORM.sTag>)][ig]{<$FIELD.hUid.sTag type="$FIELD.hUid.sType" name="$FIELD.hUid.sName" value="$UID" />$match.1}]
	^if($FIELD.hAction.iFakeCount){
		$result[^result.match[(<($FIELD.hAction.sTag)\s[^^>]*name="$FIELD.hAction.sName"[^^>]*(?:(?:/>)|(?:>(.*?)</\2>)))][ig]{^self._print[$match.2;^self._parse[$match.1];$match.3]}]
	}
}



###########################################################################
@_checkAndExec[jCode][sField;hSuspected;dScore;dValue]
^self._checkReferer[exec]
^if(!^self._isBanned[]){
	^if(!$UIDS){
		^self._warning[unknown-uid;Unknown UID (duplicate post or UID is expired)]
	}

	^UIDS.menu{
		^if(def $form:[$UIDS.sValue] || def $form:[${UIDS.sValue}.x]){
			^if($UIDS.bFake){
				^self._spam[fake-uid-exist;Fake UID exist]
			}
		}{
			^if(!$UIDS.bFake && $FIELD.hAction.bRealRequired){
				^self._spam[no-real-uid;Real UID doesn't exist]
			}
		}
	}

	^if($FILTER.tMask && $FILTER.dThreshold){
		^rem{ *** check all incoming fields with filter *** }
		$hSuspected[^hash::create[]]
		^form:fields.foreach[sField;]{
			^if(def $form:tables.$sField){
				$hSuspected.[$sField](0)
				^form:tables.[$sField].menu{
					^hSuspected.[$sField].inc(^self._getValueSusp[$form:tables.[$sField].field])
				}
			}
		}
		^if($hSuspected){
			$dScore(0)
			^hSuspected.foreach[sField;dValue]{
				^dScore.inc($dValue)
			}
			^if($dScore > $FILTER.dThreshold){
				^self._spam[suspected-content;Suspected form content was detected]
			}
		}
	}
}
$result[$jCode]



###########################################################################
@_checkReferer[sType][tReferer;sReferer;sLocalURI]
^if(def $env:HTTP_REFERER){
	$tReferer[$REFERER.[$sType]]
	^if(def $tReferer){
		$sReferer[^env:HTTP_REFERER.match[[?&].*?^$][]{}]
		$sLocalURI[^sReferer.match[^^https?\:\/\/${env:SERVER_NAME}(?:\:${env:SERVER_PORT})?(.*?)^$][]{$match.1}]
		^if(!^tReferer.locate(
			(^tReferer.sHref.pos[/]==0 && $tReferer.sHref eq $sLocalURI)
			|| (^tReferer.sHref.pos[/]>0 && $tReferer.sHref eq $sReferer)
		)){
			^self._spam[referer;Wrong referer detected ($sReferer)]
		}
	}
}{
	^if($REFERER.bRefuseEmpty || ($REFERER.hRefuseEmpty && $REFERER.hRefuseEmpty.[$sType])){
		^self._spam[referer;Empty referer is not allowed]
	}
}
$result[]



###########################################################################
@_pack[tUID]
$result[^tUID.menu{$tUID.sValue=$tUID.bFake}[|]]



###########################################################################
@_unpack[sUIDs]
$result[^self._getEmptyUIDSTable[]]
^sUIDs.match[([-\dA-F]{36})=([01])][g]{^result.append{$match.1	$match.2}}



###########################################################################
@_getEmptyUIDSTable[]
$result[^table::create{sValue	bFake}]



###########################################################################
@_fillUIDS[][i]
$result[^self._getEmptyUIDSTable[]]
^result.append{^math:uuid[]	0}
^for[i](1;$FIELD.hAction.iFakeCount){
	^result.append{^math:uuid[]	1}
}



###########################################################################
@_abort[sSource;sComment]
^throw[$self.CLASS_NAME;$sSource;$sComment]



###########################################################################
@_warning[sSource;sComment]
^if(def $UID){
	^self.clear[]
}
^self._abort[$sSource;$sComment]
$result[]



###########################################################################
@_spam[sSource;sComment]
^if(def $UID){
	^self.clear[]
}
^if(def $VISITOR && $EXPIRES.dBan){
	^self._set[$VISITOR;$BAN_FLAG;$EXPIRES.dBan]
}
^self._abort[$sSource;$sComment]
$result[]



###########################################################################
@_log[sType;sStatus;hException][hStat;dtNow;i;sLog;sName;sValue]
$hStat[
	$.iThis(^self._stat[status=$sType=$sStatus])
	$.iTotal(^self._stat[total=])
]
^if($LOG_ACCESS && $LOG_MASK.[$sType].[$sStatus] && $LOG_MASK.[$sType].[$sStatus] & $LOG_ACCESS){
	$dtNow[^date::now[]]
	$sLog[TIME: ^dtNow.sql-string[], METHOD: $env:REQUEST_METHOD, URL: ${env:SERVER_NAME}$request:uri^#0ATYPE: $sType [$sStatus^if($hException){: $hException.type|$hException.source|$hException.comment}] ($hStat.iThis/$hStat.iTotal)^#0AFORM:    ^form:fields.foreach[sName;]{^if(def $form:tables.[$sName]){^form:tables.[$sName].menu{$sName=^if($form:tables.[$sName].field is "string"){'^self._toLine[$form:tables.[$sName].field]'}{not string}}[, ]}}[, ]^#0AREFERER: '^self._toLine[$env:HTTP_REFERER]'^#0AVISITOR: '^self._visitor[]'^#0AAGENT:   '^self._toLine[$env:HTTP_USER_AGENT]'^#0AUID:  $UID^#0AUIDS: ^UIDS.menu{^if($UIDS.bFake){-}$UIDS.sValue}[, ]^#0A^#0A^#0A]
	^sLog.save[append;$DATA_DIR/${FILENAME}.log]
}
$result[]



###########################################################################
@_stat[sKey]
$result[^self._get[$sKey]]
$result(^result.int(0)+1)
^self._set[$sKey;$result]



###########################################################################
@_toLine[sText]
$result[^if(def $sText){^sText.match[\n][g]{ }}]

