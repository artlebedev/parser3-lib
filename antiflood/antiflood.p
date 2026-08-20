###########################################################################
# $Id: antiflood.p,v 1.13 2007/04/20 14:20:09 misha Exp $
###########################################################################
@CLASS
antiflood



###########################################################################
@auto[]
^self._vars[]
#end @auto[]



###########################################################################
# set expiration headers and return UID
@get[sUid]
^self._anti_cache[]
$VISITOR[^self._visitor[]]
^if(def $sUid){
	$UID[$sUid]
}{
	$UID[^self._get[$VISITOR]]
	^if(!def $UID){
		$UID[^self._generate[]]
		
		^self._set[$UID;$VALUE;$EXPIRES_UID]
		^self._set[$VISITOR;$UID;$EXPIRES_VISITOR]
		^self._release[]
	}
}
$result[$UID]
#end @get[]



###########################################################################
# if record for current uid exist in hashfile $jCode will be executed
@exec[jCode]
$result[]
^file:lock[$DATA_DIR/$LOCK_FILE]{
	^if(def $UID && ^self._get[$UID] eq $VALUE){
		$result[$jCode]
		
		^self.clear[]
	}{
		^throw[antiflood;Unknown UID]
	}
}
#end @exec[]



###########################################################################
# clear records from hashfile which assosiated with current UID (we must call it if we detect spammer for example)
@clear[][result]
^self._open[]
^self._delete[$UID]
^self._delete[$VISITOR]
^self._clear[]
^self._release[]
$result[]
#end @clear[]



###########################################################################
# vars initialization
@_vars[][sDummy]
# path where files will be located
$DATA_DIR[/../data/cache]

# UID will be stored in hashfile for 2 hours
$EXPIRES_UID(2/24)

# we don't change UID for one user often then once in 5 secs
# in other case if someone put something on F5 key on his keyboard he flood our hashfile too much
$EXPIRES_VISITOR(5/24/60/60)

# hashfile name
$ANTIFLOOD_FILE[_antiflood]

# lock file name
$LOCK_FILE[_antiflood.lock]
$HF[]
$UID[]
$VISITOR[]
$VALUE[1]
#end @_vars[]



###########################################################################
@_open[][result]
^if(!^self._is_open[]){
	$HF[^hashfile::open[$DATA_DIR/$ANTIFLOOD_FILE]]
}
$result[]
#end @_open[]



###########################################################################
@_is_open[][result]
$result(def $HF)
#end @_is_open[]



###########################################################################
# set expire headers
@_anti_cache[]
$response:expires[Fri, 23 Mar 2001 09:32:23 GMT]
$response:cache-control[no-store, no-cache, must-revalidate, proxy-revalidate]
$response:pragma[no-cache]
# cancel caching if code executed inside ^cache[]
^try{
	^cache(0)
}{
	$exception.handled(1)
}
#end @_anti_cache[]



###########################################################################
# return new uid
@_generate[][result]
$result[^math:uuid[]]
#end @_generate[]



###########################################################################
# get record from hashfile 
@_get[sKey][result]
^if(def $sKey){
	^self._open[]
	$result[$HF.$sKey]
}{
	$result[]
}
#end @_get[]



###########################################################################
# put record to hashfile 
@_set[sKey;sValue;iExpire][result]
^if(def $sKey){
	^self._open[]
	$HF.[$sKey][
		$.value[$sValue]
		^if(def $iExpire){
			$.expires($iExpire)
		}
	]
}
$result[]
#end @_set[]



###########################################################################
# delete record with $sKey from hashfile
@_delete[sKey][result]
^if(def $sKey){
	^self._open[]
	^HF.delete[$sKey]
}
$result[]
#end @_delete[]



###########################################################################
# remove expired records from hashfile
@_clear[][result;sKey]
^self._open[]
^try{
	^HF.cleanup[]
}{
	$exception.handled(1)
	^HF.foreach[sKey;]{}
}
$result[]
#end @_clear[]



###########################################################################
@_release[][result]
^if(^self._is_open[]){
	^try{
		^HF.release[]
	}{
		$exception.handled(1)
	}
}
$result[]
#end @_release[]



###########################################################################
# generate visitor ID
@_visitor[][result]
$result[${env:REMOTE_ADDR}:^if(def $env:HTTP_X_FORWARDED_FOR){$env:HTTP_X_FORWARDED_FOR}{NULL}]
#end @_visitor[]

