###########################################################################
# $Id: auth.p,v 1.84 2009-08-22 23:38:28 misha Exp $
#
# КЛАСС auth
#
# Класс предназначен для установления сессии работы, состояние запоминается в куках auth.uid и auth.sid 
# auth.uid - кука пользователя, которая дается на определенный срок и продляется при каждом новом сеансе работы
# auth.sid - кука сессии
# все выданые куки пишутся в таблицу asession
#
# СВОЙСТВА ОБЪЕКТА:
# $init_type - int, тип инициализации сессии произошел
#	-1 - еще не знаем, включены куки у этого пользователя или нет
#	 0 - продолжение текущей сессии
#	 1 - обновили в базе дату
#	 2 - в базе sid не соответствовало sid в куках, выдали новый sid, обновили базу
#	 3 - sid и uid в базе не соответствовали тому, что в куках, выбрали новый sid, uid, обновили базу.
# $status		int, статус последней операции. сразу после конструирования объекта - результат логина
# $session		hash, информация о текущей сессии
#				[ session_id, sid, uid, dt_access, dt_logon, dt_logout ]
# $groups		table, информация о всех группах
#				[ group_id, name, description, rights, is_default ]
# $user			hash, параметры пользователя, если он подключен 
#				[ user_id, name, email, dt_register, dt_logon, dt_logout, rights, event_type, connections_limit, groups ]
# $is_logon		int, залогинен пользователь (1) или нет (0)
# $last_name	string, имя последнего удачно залогиненого пользователя (берем из $icookie_data)
#
# МЕТОДЫ ОБЪЕКТА:
# @init[icookie_data;ilogon_data;params]	инициализирует сессию, обновляя/добавляя запись в таблицу asession
#											если def $logon_data.[auth.logon], то идет вызов ^logon[]
#											если def $logon_data.[auth.logout], то идет вызов ^logout[]
#											$params определяет поведение класса
# @logon[logon_data]						логин пользователя с $logon_data.[auth.name] и $logon_data.[auth.passwd],
#											если определена $logon_data.[auth.logon]
# @logout[]									отключение текущего пользователя
# @insertUser[user_data]					добавляет в базу информацию о пользователе, записывая параметры
#											$logon_data.[auth.name], $logon_data.[auth.email] и $logon_data.[auth.passwd]
#											возвращает статусы
# @updateUser[user_data]					обновляет в базе информацию о текущем пользователе, записывая параметры
#											$logon_data.[auth.name], $logon_data.[auth.email] и $logon_data.[auth.passwd]
# @makeRandomID[]							make random code using ^math:md5[]
# @makeSessionID[]							make random session code
# @saveParam[sParamName;sParamValue;iExpires]	сохраняет значение (по умолчанию в куках, если надо иное - перекрыть)
# @setTemporaryPasswd[email;name]			вставляет в базу сгенерированный временный пароль (чтобы его активировать 
#											нужно подтверждение) и возвращает его. Если пользователя с таким адресом 
#											нет - возвращает пустое значение.
# @setPasswdFromTemporary[email;name;code]	проверяет комбинацию email[/name]/code [new_passwd] и в случае совпадения
#											переписывает его в passwd
# @getUser[hParams]							достает из БД информацию о пользователе по заданым параметрам
# @getAllUsers[]							достает из БД список всех пользователей
# @getGroups[]								достает из БД список групп
# @getUserGroups[sUserList]					возвращает список групп, в которых состоят пользователи
# @getGroupUsers[iGroupId]					возвращает список пользователей для заданой группы с их правами
# @getACL[object_list;user_list]			достает из БД ACL списка пользователей (групп) на объекты
# @getFullACL[object_list]					возвращает ACL пользователя и групп, в которых он состоит на объекты
# @getRightsToObject[object;thread;acl;is_owner]	вычисляет эффективные права пользователя на объект
# @setExpireHeaders[date]					ставит заданную дату в  Last-Modified, иначе ставит Expires
# @xmlFormLogon[hParams]					print xml for logon form
# @xmlFormLogout[hParams]					print xml for logout form
# @htmlFormLogon[hParams]					print html for logon form
# @htmlFormLogout[hParams]					print html for logout form
# @cryptPassword[sPassword]					crypt password using ^math:crypt[]
# @isValidPassword[sPassword;sPasswordCrypted]	проверяет пароль и возвращает bool




@CLASS
auth

@USE
Lib.p
dtf.p


###########################################################################
@auto[]
# constants for auser_type_id
$USER_ID(0)
$GROUP_ID(1)
$OWNER_ID(2)

# for caching calculated rights
$rights_hash[^hash::create[]]
#end @auto[]


###########################################################################
# constructor
# в качестве $icookie_data обычно передаются все cookie ($cookie:CLASS)
# если определена $ilogon_data, то при инициализации идет попытка logon/logout пользователя
# обычно в $ilogon_data стОит передавать $form:fields со странички, с которой осуществляется logon/logout
# $params - хеш, определяющий поведение класса. возможные ключи (в скобках указаны значения по умолчанию):
#	$.is_groups_disabled(0)		- не доставать группы
#	$.is_delay_groups(0)		- не доставать полный список групп пока он не потребуется
#	$.session_lifetime(14)		- время хранения записей в табличке asession, дней
#	$.cookie_sid_lifetime(0)	- время, на которое ставится сессионная кука, дней (0 - сессионная кука)
#	$.cookie_uid_lifetime(365)	- время, на которое ставится пользовательская кука, дней
#	$.timeout(15)				- время, через которое мы обновляем поле dt_access в asession, минут
#	$.event_lifetime(7)			- время хранения записей в табличке aevent_log, дней
#	$.event_min_count(30)		- количество последних хранящихся записей событий для каждого пользователя, записей
#	$.new_user_event_type(147)	- какие события у вновь создаваемых пользователей будем писать в лог

@init[icookie_data;ilogon_data;params]
# если нам не передали $icookie_data - то данные берем из кук.
$cookie_data[^if(def $icookie_data){$icookie_data}{$cookie:CLASS}]

$logon_data[^hash::create[$ilogon_data]]

^self.declareVars[^hash::create[$params]]

^self.initSession[$cookie_data]

# инициализируем пользователя
^try{
	^self.logon[$logon_data]
}{
	$exception.handled(1)
}

^if(def $logon_data.[auth.logout]){
	^self.logout[]
}
#end @init[]




###########################################################################
# НЕ ПЕРЕКРЫВАТЬ, иначе переменные не будут видны из родительского класса
@declareVars[params]
$now[^date::now[]]
$last_name[]

$is_logon(0)

$init_type(0)

$is_groups_loaded(0)
$is_user_groups_loaded(0)

$session[^hash::create[]]
$groups[]

$events[^getEvents[]]
$errors[^getErrors[]]

$user[
	$.id(0)
	$.user_id(0)
]

^self.initStatus(0)

^self.initErrorTable[]

# нам ОБЯЗАТЕЛЬНО должны передать объект, через который будут делаться все sql запросы
$oSql[^if(def $params.oSql){$params.oSql}{$params.csql}]
^if(!def $oSql){
	^throw[auth;Initialization failure. ^$.oSql or ^$.csql option MUST be specified.]
}
# backward
$csql[$oSql]

$EVENT[^events.menu{$.[$events.name][$events.id]}]
$ERROR[^errors.menu{$.[$errors.name][$errors.id]}]

# если нам не нужны группы - можно отключить их
$is_groups_disabled(^params.is_groups_disabled.int(0))

# если полный список групп пока не нужен (определен флаг $is_delay_groups) - не достаем их
^if($is_groups_disabled || ^params.is_delay_groups.int(0)){
	$groups[^table::create{}]
}{
	^self.getGroups[]
}

# если идет logon то запоминаем значение пришеднее в logon_data.[auth.persistent]
^if(def $logon_data.[auth.logon]){
	$is_persistent(^if(^logon_data.[auth.persistent].int(0)){1}{0})
	^self.saveParam[auth.persistent;$is_persistent;365]
}{
	$is_persistent(^cookie_data.[auth.persistent].int(0))
}

# время хранения записей в табличке asession (дней)
$session_lifetime(^params.session_lifetime.int(14))

# время, на которое ставится сессионная кука (дней, 0 - сессионная, если установлен persistent, то ставим на год )
$cookie_sid_lifetime(^params.cookie_sid_lifetime.double(^if($is_persistent){365}{0}))

# время, на которое ставится пользовательская кука (дней)
$cookie_uid_lifetime(^params.cookie_uid_lifetime.double(365))

# время, через которое мы обновляем поле dt_access в таблице asession (минут)
$timeout(^params.timeout.int(15))

# время жизни записей в табличке aevent_log (дней)
$event_lifetime(^params.event_lifetime.int(7))

# сколько минимально последних записей мы храним по каждому пользователю
$event_min_count(^params.event_min_count.int(30))

# event_type, который автоматически прописывается новым юзерам: пишем логин/логаут/изменение имени
$new_user_event_type(^params.new_user_event_type.int($EVENT.update_user + $EVENT.logon + $EVENT.logout + $EVENT.change_name))

^if($params.additional_fields is "table"){
	$additional_fields[$params.additional_fields]
}{
	$additional_fields[^table::create{select	update	field}]
}
#end @declareVars[]



###########################################################################
# события, которые у нас бывают
@getEvents[]
$result[^table::create{id	name	description	is_editable
1	logon	Login	1
2	logout	Logout	1
4	request_password	Запрос пароля	1
8	change_password	Изменение пароля	1
16	change_name	Изменение логина	1
32	change_email	Изменение email	1
64	change_rights	Изменение прав
128	update_user	Изменение пользователя
256	insert_user	Добавление пользователя
}]
#end @getEvents[]



###########################################################################
# коды ошибок, думаю 16 бит должно хватить
@getErrors[]
$result[^table::create{id	name
1	not_logged
2	login_empty
4	login_exist
8	password_empty
16	password_confirmation_error
32	email_empty
64	email_wrong
128	user_not_found
256	multiple_user_found
32768	unknown
}]
#end @getErrors[]


###########################################################################
# инициализация сессии на основании $cookie_data
@initSession[cookie_data][last_sessions;valid_session;sid;uid]
$valid_session[^hash::create[]]
^if(def $cookie_data.[cookie] || def $cookie_data.[auth.uid]){
	^if(def $cookie_data.[auth.uid]){
		^rem{ *** достаем все записи с auid, который пришел от пользователя. записей может быть несколько, *** }
		^rem{ *** но актуальная только одна - та, у которой наша sid или, *** }
		^rem{ *** если от юзера не пришла sid (новая сессия) - самая последняя. *** }
		$last_sessions[^oSql.table{
			SELECT
				asession_id AS session_id,
				auser_id AS user_id,
				auid AS ^if($oSql.server_name eq "oracle"){"uid"}{uid},
				sid,
				dt_access,
				dt_logon,
				dt_logout
			FROM
				asession
			WHERE
				auid = '$cookie_data.[auth.uid]'
			ORDER BY
				dt_access DESC
		}]
		^if((!def $cookie_data.[auth.sid] && $last_sessions) || ^last_sessions.locate[sid;$cookie_data.[auth.sid]]){
			$valid_session[$last_sessions.fields]
		}
	}
	^if($valid_session){
		$uid[$valid_session.uid]
		^if($valid_session.sid eq $cookie_data.[auth.sid]){
			$sid[$valid_session.sid]
			^if(^date::create[$valid_session.dt_access] < ^date::create($now-$timeout/(24*60))){
				$init_type(1)
			}
		}{
			$sid[^self.makeSessionID[]]
			$init_type(2)
		}
	}{
		$uid[^self.makeSessionID[]]
		$sid[^self.makeSessionID[]]
		$init_type(3)
	}
}{
	$init_type(-1)
}
^self.saveParam[cookie;on;365]
$session[$valid_session]
^if($init_type > 0){
	^session.add[^self.updateSession[$uid;$sid;$valid_session.session_id]]
}
#end @initSession[]




###########################################################################
# если задана logon_data, то попытка логина с задаными параметрами, 
# иначе - попытка установить связь по текущей asession_id
# если $init_type = 0 - у нас продолжение секущей сессии
@logon[logon_data][_type;_user]
^self.initStatus(0)
$_type[auth.logon]
^try{
	^if($init_type >= 0 && $init_type < 3){
		^rem{ *** достаем информацию о текущем юзере по $session.user_id *** }
		$_user[^self.getUser[
			$.user_id(^session.user_id.int(0))
		]]
		^if($init_type == 2){
			^rem{ *** ни фига не помню, зачем я это делаю... надо разобраться... *** }
			^oSql.void{
				UPDATE
					asession
				SET
					auser_id = 0
				WHERE
					asession_id = $session.session_id
			}
			$session.user_id(0)
			$_user[]
		}{
			^if(def $logon_data.[auth.logon]){
				^rem{ *** если при этом идет logon - то надо отлогинить текущего юзера *** }
				^self.logout[]
			}
		}
	}
	^if($init_type >= 0 && def $logon_data.[auth.logon] && def $logon_data.[auth.name] && def $logon_data.[auth.passwd]){
		^rem{ *** если идет logon - достаем информацию о пользователе по введенным имени/паролю *** }
		$_user[^self.getUser[
			$.name[$logon_data.[auth.name]]
			$.password[$logon_data.[auth.passwd]]
		]]
		^if(!$_user){
			^self.addErrorCode[user_not_found]
			^throw[$_type;errors]
		}
		^rem{ *** обновляем информацию о сессии и пользователе в базе *** }
		^oSql.void{
			UPDATE
				asession
			SET
				auser_id = '$_user.user_id',
				dt_access = ^oSql.now[],
				dt_logon = ^oSql.now[],
				dt_logout = ^if(def $_user.dt_logout){'$_user.dt_logout'}{NULL}
			WHERE
				asession_id = $session.session_id
		}
		^oSql.void{
			UPDATE
				auser
			SET
				dt_logon = ^oSql.now[]
			WHERE
				auser_id = $_user.user_id
		}

		^self.logEvent[$_user.fields]($EVENT.logon)(0)
		^self.updateSessionParams[$session.sid;$session.uid;is_force_update_uid]
	}
	^if($_user){
		$is_logon(1)
		$user[$_user.fields]

		$user.dt_access[$session.dt_access]
		$user.groups[^table::create{}]
		^if(!$is_groups_disabled && ($groups || !$is_groups_loaded)){
			^self.loadUserGroups[]
		}

		^if($cookie_data.[auth.name] ne $user.name){
			^self.saveParam[auth.name;$user.name;365]
		}
	}
}{
	$exception.handled(1)
	^if($exception.type ne $_type){
		^self.addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$.name[$logon_data.[auth.name]]]($EVENT.logon)($status)
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
$last_name[$cookie_data.[auth.name]]
#end @logon[]




###########################################################################
# завершение текущей авторизированой сессии пользователя
@logout[]
^if($session){
	^oSql.void{
		UPDATE
			asession
		SET
			auser_id = 0,
			dt_access = ^oSql.now[],
			dt_logout = ^oSql.now[]
		WHERE
			asession_id = $session.session_id
	}
	^if($user.user_id){
		^oSql.void{
			UPDATE
				auser
			SET
				dt_logout = ^oSql.now[]
			WHERE
				auser_id = $user.user_id
		}
		^rem{ *** пишем в лог об этом событии *** }
		^self.logEvent[$user]($EVENT.logout)
	}
}
$is_logon(0)
$user[
	$.user_id(0)
	$.groups[^table::create{}]
]
#end @logout[]



###########################################################################
@initErrorTable[]
$error[^table::create{type	code}]
#end @initErrorTable[]



###########################################################################
@initStatus[iCode]
$status($iCode)
$result[]
#end @initStatus[]



###########################################################################
@addErrorCode[sErrorName]
$status($status | $ERROR.$sErrorName)
$result[]
#end @addErrorCode[]



###########################################################################
@appendError[sType;sCode]
^error.append{$sType	$sCode}
$result[]
#end @appendError[]



###########################################################################
@decodeError[iErrorCode][_iCode]
$_iCode(^if(def $iErrorCode){$iErrorCode}{$status})
$result[^table::create{code	name}]
^errors.menu{
	^if($_iCode & $errors.id){
		^result.append{$errors.id	$errors.name}
	}
}
#end @decodeError[]



###########################################################################
# возвращает 1 если в последней операции произошла ошибка $name
@isError[sErrorName]
$result(^if($status & $ERROR.$sErrorName){1}{0})
#end @isError[]



###########################################################################
# запись логов в соответствии с event_type
# если у данного пользователя установлен бит на протоколирование текущего события - добавляем в лог запись
@logEvent[user;event_type;status;content][user_id;event;exist;keep_events;addon]
^if($user && $user.event_type & $event_type){
	$event($event_type)
	$user_id(^user.user_id.int(0))
}{
	^if($user && (def $user.name || def $user.email)){
		$event($event_type)
		$exist[^self.getUser[
			$.name[$user.name]
			$.email[$user.email]
		]]
		^if($exist && ^exist.count[] == 1){
			$user_id($exist.user_id)
		}{
			$user_id(0)
			$addon[^if(def $user.name){, name=$user.name}^if(def $user.email){, email=$user.email}]
		}
	}
}
^if($event){
	^oSql.void{INSERT INTO aevent_log (
		auser_id,
		event_type,
		dt,
		stat,
		content
	) VALUES (
		$user_id,
		$event,
		^oSql.now[],
		^status.int(0),
		'^self.getStationAddr[]${addon}^if(def $content){, $content}'
	)}

	^rem{ *** надо удалить все сообщения старее чем now() - $event_lifetime, но оставить не меньше чем $event_min_count *** }
	$keep_events[^oSql.table{
		SELECT
			aevent_log_id AS id
		FROM
			aevent_log
		WHERE
			auser_id = $user_id
		ORDER BY
			dt DESC
	}[$.limit($event_min_count)]]

	^oSql.void{
		DELETE FROM
			aevent_log
		WHERE
			auser_id = $user_id AND
			aevent_log_id NOT IN (^if($keep_events){^keep_events.menu{$keep_events.id}[,]}{0}) AND
			dt < ^oSql.date_sub[;^date_diff.int($event_lifetime)]
	}
}
#end @logEvent[]




###########################################################################
@checkEmail[sEmail]
^if(!def $sEmail){
	^self.addErrorCode[email_empty]
}
^if(
	def $sEmail
	&& !^self.isEmail[$sEmail]
){
	^self.addErrorCode[email_wrong]
}
$result[]
#end @checkEmail[]



###########################################################################
# checking before insert new user
@beforeInsert[hUser]
$result[]
^if(!def $hUser.[auth.name]){
	^self.addErrorCode[login_empty]
}
^if(!def $hUser.[auth.passwd]){
	^self.addErrorCode[password_empty]
}
^if(
	def $hUser.[auth.passwd]
	&& $hUser.[auth.passwd] ne $hUser.[auth.passwd_confirm]
){
	^self.addErrorCode[password_confirmation_error]
}

^self.checkEmail[$hUser.[auth.email]]

^if(
	def $hUser.[auth.name]
	&& ^self.getUserCount[
		$.name[$hUser.[auth.name]]
	]
){
	^self.addErrorCode[login_exist]
}
#end @beforeInsert[]



###########################################################################
# добавление нового пользователя
@insertUser[user_data][_type]
$_type[auth.insert]
^self.initStatus(0)
^try{
	^self.beforeInsert[$user_data]

	^if($status){
		^throw[$_type;errors]
	}
	
	^oSql.void{INSERT INTO auser (
		auser_type_id,
		name,
		email,
		passwd,
		dt_register,
		event_type
		^if(def $user_data.[auth.rights]){, rights}
		^additional_fields.menu{
			^if(def $additional_fields.fields.update && def $additional_fields.fields.field){
				, $additional_fields.fields.update
			}
		}
	) VALUES (
		$USER_ID,
		'$user_data.[auth.name]',
		'$user_data.[auth.email]',
		'^self.cryptPassword[$user_data.[auth.passwd]]',
		^oSql.now[],
		$new_user_event_type
		^if(def $user_data.[auth.rights]){, $user_data.[auth.rights]}
		^additional_fields.menu{
			^if(def $additional_fields.fields.update && def $additional_fields.fields.field){
				, '$user_data.[$additional_fields.fields.field]'
			}
		}
	)}

	$new_user[
		$.user_id(^oSql.last_insert_id[auser])
		$.name[$user_data.[auth.name]]
		$.email[$user_data.[auth.email]]
		$.rights[$user_data.rights]
		$.event_type[$EVENT.insert_user]
	]

	^try{
		^rem{ *** загружаем полный список групп *** }
		^self.getGroups[]
    	
		^rem{ *** включаем вновь добавленного пользователя в группы, у которых установлен флаг is_default *** }
		^groups.menu{
			^if($groups.is_default){
				^oSql.void{INSERT INTO auser_to_auser (
					auser_id,
					parent_id
				) VALUES (
					$new_user.user_id,
					$groups.group_id
				)}
			}
		}
	}{
		^rem{ *** если не удалось добавить пользователя в группы - ну и хрен с ними (пока) *** }
		$exception.handled(1)
	}
	^self.postInsert[$new_user.user_id;$user_data]

	^self.logEvent[$new_user;$EVENT.insert_user;$status]
}{
	$exception.handled(1)
	^if($exception.type ne $_type){
		^addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$new_user;$EVENT.insert_user;$status]
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
#end @insertUser[]



###########################################################################
# метод выполняется после успешного добавления нового пользователя
@postInsert[iUserId;hUser]
#end @postInsert[]



###########################################################################
# checkings before update user
@beforeUpdate[hUser]
$result[]
^if(!$is_logon){
	^self.addErrorCode[not_logged]
}
^if(!def $hUser.[auth.name]){
	^self.addErrorCode[login_empty]
}
^if(
	def $hUser.[auth.passwd]
	&& $hUser.[auth.passwd] ne $hUser.[auth.passwd_confirm]
){
	^self.addErrorCode[password_confirmation_error]
}
^if(
	def $hUser.[auth.name]
	&& $hUser.[auth.name] ne $user.name
	&& ^self.getUserCount[
		$.name[$hUser.[auth.name]]
		$.user_id($user.user_id)
	]
){
	^self.addErrorCode[login_exist]
}

^self.checkEmail[$hUser.[auth.email]]
#end @beforeUpdate[]



###########################################################################
# изменение параметров пользователя
@updateUser[user_data][_type;_event_type;_comment;_user]
$_type[auth.update]
^self.initStatus(0)
^try{
	^self.beforeUpdate[$user_data]
	
	^if($status){
		^throw[$_type;errors]
	}
	
	$_event_type($EVENT.update_user)
	$_comment[]
	^if($user_data.[auth.name] ne $user.name){
		^_event_type.inc($EVENT.change_name)
		$_comment[${_comment}prev_name: $user.name ]
	}
	^if(def $user_data.[auth.passwd]){
		^_event_type.inc($EVENT.change_password)
	}
	^if(
		$user_data.[auth.email] ne $user.email
		&& ^self.isEmail[$user_data.[auth.email]]
	){
		^_event_type.inc($EVENT.change_email)
		$_comment[${_comment}prev_email: $user.email ]
	}
	$_user[
		$.user_id($user.user_id)
		$.name[$user_data.[auth.name]]
		$.email[$user_data.[auth.email]]
		$.event_type[$user.event_type]
	]

	^oSql.void{
		UPDATE
			auser
		SET
			name = '$user_data.[auth.name]'
			^if(^isEmail[$user_data.[auth.email]]){, email = '$user_data.[auth.email]'}
			^if(def $user_data.description){, description = /**description**/'$user_data.description'}
			^if(def $user_data.[auth.passwd]){, passwd = '^cryptPassword[$user_data.[auth.passwd]]'}
			^if(def $user_data.[auth.rights]){, rights = $user_data.[auth.rights]}
			^additional_fields.menu{
				^if(def $additional_fields.fields.update && def $additional_fields.fields.field){
					, $additional_fields.fields.update = '$user_data.[$additional_fields.fields.field]'
				}
			}
		WHERE
			auser_id = $user.user_id
	}
	^if(def $user_data.[auth.passwd]){
		^self.clearUserSessions[$user.user_id;$session.session_id]
	}

	^self.postUpdate[$user.user_id;$user_data]

	^self.logEvent[$_user;$_event_type;$status;$_comment]
}{
	$exception.handled(1)
	
	^if($exception.type ne $_type){
		^self.addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$_user;$_event_type;$status;$_comment]
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
#end @updateUser[]




###########################################################################
# метод выполняется после успешного изменения параметров пользователя
@postUpdate[iUserId;hUser]
#end @postUpdate[]


###########################################################################
# генерит и запоминает новый пароль для пользователя с заданым email/name
# в случае наличия пользователя с этим email/name (причем валидным) возвращает пароль, иначе возвращает пустую строку
@setTemporaryPasswd[email;name][_type;_exist;_user]
$result[]
$_type[auth.set_temporary_password]
^self.initStatus(0)
^try{
	$_user[
		$.name[$name]
		$.email[$email]
	]

	^if(!def $email){
		^self.addErrorCode[email_empty]
	}
	^if(
		def $email
		&& !^isEmail[$email]
	){
		^self.addErrorCode[email_wrong]
	}
	$_exist[^getUser[
		$.email[$email]
		$.name[$name]
	]]
	^if(!$_exist){
		^self.addErrorCode[user_not_found]
	}
	^if($_exist > 1){
		^self.addErrorCode[multiple_user_found]
	}
	^if($status){
		^throw[$_type;errors]
	}
	$result[^self.makeRandomID[]]
	^oSql.void{
		UPDATE
			auser
		SET
			new_passwd = '^self.cryptPassword[$result]'
		WHERE
			auser_type_id = $USER_ID AND
			^oSql.lower[email] = '^email.lower[]'
			^if(def $name){
				AND ^oSql.lower[name] = '^name.lower[]'
			}
	}
	^self.logEvent[$_user;$EVENT.request_password;$status]
}{
	$exception.handled(1)
	^if($exception.type ne $_type){
		^self.addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$_user;$EVENT.request_password;$status]
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
#end @setTemporaryPassword[]




###########################################################################
# для пользователя с заданной комбинацией $email[/$name]/$code делает временный пароль в постоянным
@setPasswdFromTemporary[email;name;code][_exist;_stat;_user]
$_type[auth.set_password_from_temporary]
^self.initStatus(0)
^try{
	$_user[
		$.name[$name]
		$.email[$email]
	]
	^if(!def $email){
		^self.addErrorCode[email_empty]
	}
	^if(
		def $email
		&& !^self.isEmail[$email]
	){
		^self.addErrorCode[email_wrong]
	}
	$_stat(2)
	$_exist[^self.getUser[
		$.email[$email]
		$.name[$name]
	]]
	^_exist.menu{
		^if($_stat && ^self.isValidPassword[$code;$_exist.new_passwd]){
			^oSql.void{
				UPDATE
					auser
				SET
					passwd = new_passwd,
					new_passwd = ''
				WHERE
					auser_id = $_exist.user_id
			}
			$_stat(0)
		}
	}
	^if($_stat){
		^self.addErrorCode[user_not_found]
		^throw[$_type;errors]
	}
	^self.clearUserSessions[$user.user_id;$session.session_id]
	^self.logEvent[$_user;$EVENT.change_password;$status]
}{
	$exception.handled(1)
	^if($exception.type ne $_type){
		^self.addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$_user;$EVENT.change_password;$status;code=$code]
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
#end @setPasswdFromTemporary[]



###########################################################################
# метод апдейтит запись в таблице asession
@updateSession[uid;sid;session_id]
^oSql.void{
	DELETE FROM
		asession
	WHERE
		auid = '$uid'
		^if(def $session_id){AND asession_id != ^session_id.int(0)}
}
^if(def $session_id){
	^rem{ *** апдейтим запись в базе *** }
	^oSql.void{
		UPDATE
			asession
		SET
			auid = '$uid',
			sid = '$sid',
			dt_access = ^oSql.now[]
		WHERE
			asession_id = ^session_id.int(0)
	}
	$result[
		$.session_id($session_id)
		$.uid[$uid]
		$.sid[$sid]
		$.dt_access[^now.sql-string[]]
	]
}{
	^rem{ *** добавляем запись в базу *** }
	^oSql.void{INSERT INTO asession (
		auid,
		sid,
		dt_access
	) VALUES (
		'$uid',
		'$sid',
		^oSql.now[]
	)}
	$result[
		$.session_id(^oSql.last_insert_id[asession])
		$.uid[$uid]
		$.sid[$sid]
		$.dt_access[^now.sql-string[]]
	]
}
^self.updateSessionParams[$sid;$uid]

# sometime clear old and not used session records
^if(^math:random(100) < 10){
	^self.clearSession[]
}
#end @updateSession[]



###########################################################################
# метод пишет сессионные параметры пользователю
# смысл парметра auth.uid.updated в том, что он выдается на достаточно небольшой период (7 дней), и если вдруг он 
# уже устарел, то заново сохраняем его и auth.uid, таким образом не нужно каждый раз сохранять auth.uid...
@updateSessionParams[sid;uid;is_force_set_uid]
^if(def $is_force_set_uid || !def $cookie_data.[auth.uid.updated] || $cookie_data.[auth.uid] ne $uid){
	^self.saveParam[auth.uid;$uid;$cookie_uid_lifetime]
	^self.saveParam[auth.uid.updated;^now.sql-string[];7]
}
^self.saveParam[auth.sid;$sid;$cookie_sid_lifetime]
$result[]
#end @updateSessionParams[]



###########################################################################
# return random code
@makeRandomID[]
$result[^math:md5[^now.sql-string[]^math:random(1000000)]]
#end @makeRandomID[]



###########################################################################
# метод возвращает информацию о компьютере посетителя
@getStationAddr[]
$result[^if(def $env:REMOTE_ADDR){$env:REMOTE_ADDR}{NULL}:^if(def $env:HTTP_X_FORWARDED_FOR){$env:HTTP_X_FORWARDED_FOR}{NULL}]
#end @getStationAddr[]



###########################################################################
# make code for session
@makeSessionID[]
$result[^self.getStationAddr[]=^self.makeRandomID[]]
^if(^result.length[] >= 63){$result[^result.left(63)]}
#end @makeSessionID[]



###########################################################################
# у каждого пользователя сохраняем самую последнюю запись в asession т.к. по ней мы
# сможет восстановить его сессию после долгого перерыва и получить дату последнего визита
@clearSession[date_diff][cleared_users;deleted_sessions;uid;cnt;ids;tmp]

# clear expired non authorized sessions
^oSql.void{
	DELETE FROM
		asession
	WHERE
		auser_id = 0 AND
		dt_access < ^oSql.date_sub[;^date_diff.int($session_lifetime)]
}

# clear authorized sessions
$cleared_users[^oSql.table{
	SELECT
		auser_id AS id
	FROM
		asession
	WHERE
		auser_id != 0
	GROUP BY
		auser_id
	HAVING
		COUNT(*) > 1
}]
^if($cleared_users){
	^rem{ *** достаем сессии, которые надо будет удалять *** }
	$deleted_sessions[^oSql.table{
		SELECT
			asession_id AS id,
			auser_id
		FROM
			asession
		WHERE
			auser_id IN (^cleared_users.menu{$cleared_users.id}[,]) AND
			dt_access < ^oSql.date_sub[;^date_diff.int($session_lifetime)]
		ORDER BY
			auser_id,
			dt_access DESC
	}]
	^if($deleted_sessions){
		$uid(-1)
		$cnt(1)
		$ids[^deleted_sessions.menu{^if($cnt < 1000 && $uid == $deleted_sessions.auser_id){^cnt.inc(1)$deleted_sessions.id}{$uid($deleted_sessions.auser_id)}}[,]]

		^if(def $ids){
			^oSql.void{
				DELETE FROM
					asession
				WHERE
					asession_id IN ($ids)
			}
		}
	}
}
^if($oSql.server_name eq "mysql" && ^math:random(1000) < 5){
	^rem{ *** with mysql server optimize table asession from time to time *** }
	$tmp[^oSql.table{OPTIMIZE TABLE asession}]
}
$result[]
#end @clearSession[]



###########################################################################
# delete user sessions saving specified
@clearUserSessions[iUserId;iSessionId]
^oSql.void{
	DELETE FROM
		asession
	WHERE
		auser_id = $iUserId
		^if($iSessionId){
			AND asession_id != $iSessionId
		}
}
$result[]
#end @clearUserSessions[]


###########################################################################
# get number of users with specified params
@getUserCount[hParam]
$hParam[^hash::create[$hParam]]
$result(^oSql.int{
	SELECT
		COUNT(*)
	FROM
		auser
	WHERE
		auser_type_id = $USER_ID
		^if(def $hParam.name){
			AND ^oSql.lower[name] = '^hParam.name.lower[]'
		}
		^if(def $hParam.email){
			AND ^oSql.lower[email] = '^hParam.email.lower[]'
		}
		^if($hParam.user_id){
			AND auser_id != $hParam.user_id
		}
		^if(def $hParam.user_ids){
			AND auser_id IN ($hParam.user_ids)
		}
})
#end @getUserCount[]



###########################################################################
# get user with specified params
@getUser[hParams][_hParams]
$_hParams[^hash::create[$hParams]]
^if(def $_hParams.user_id && !^_hParams.user_id.int(0)){
	$result[^table::create{}]
}{
	$result[^oSql.table{
		SELECT
			auser_id AS id,
			auser_id AS user_id,
			name,
			email,
			description,
			rights,
			passwd,
			new_passwd,
			dt_register,
			dt_logon,
			dt_logout,
			connections_limit,
			event_type
			^additional_fields.menu{
				, $additional_fields.fields.select ^if(def $additional_fields.field){ AS $additional_fields.field}
			}
		FROM
			auser
		WHERE
			is_published = 1
			AND auser_type_id = $USER_ID
			^if(def $_hParams.user_id){
				AND auser_id != 0
				AND auser_id = ^_hParams.user_id.int(0)
			}
			^if(def $_hParams.user_ids){
				AND auser_id IN ($_hParams.user_ids)
			}
			^if(def $_hParams.email){
				AND ^oSql.lower[email] = '^_hParams.email.lower[]'
			}
			^if(def $_hParams.name){
				AND ^oSql.lower[name] = '^_hParams.name.lower[]'
			}
		ORDER BY
			dt_logon DESC
	}]
	^rem{ *** check password if it was specified *** }
	^if(
		def $_hParams.password
		&& $result
		&& !^self.isValidPassword[$_hParams.password;$result.passwd]
	){
		$result[^table::create{}]
	}
}
#end @getUser[]



###########################################################################
# get ALL users from DB
@getAllUsers[]
$result[^oSql.table{
	SELECT
		auser_id AS id,
		name,
		is_published
	FROM
		auser
	WHERE
		auser_type_id = $USER_ID
	ORDER BY
		name
}]
#end @getAllUsers[]



###########################################################################
# get groups from DB if needed
@getGroups[]
^if(!$is_groups_loaded){
	$groups[^oSql.table{
		SELECT	
			auser_id AS group_id,
			name,
			description,
			rights,
			is_published,
			is_default
		FROM
			auser
		WHERE
			auser_type_id = $GROUP_ID
		ORDER BY
			name
	}]
	$is_groups_loaded(1)
}
#end @getGroups[]



###########################################################################
@loadUserGroups[]
^if(
	$is_logon
	&& $user
	&& !$is_user_groups_loaded
){
	$user.groups[^self.getUserGroups[$user.user_id]]
	$is_user_groups_loaded(1)
}
$result[]
#end @loadUserGroups[]



###########################################################################
# достает ид БД список групп в которых состоят пользователи с их правами на root
# если не задали $sUserList то возвращаем данные о принадлежности к группам для текущего пользователя
@getUserGroups[sUserList]
$result[^oSql.table{
	SELECT
		auser_to_auser.parent_id AS group_id,
		auser_to_auser.auser_id,
		auser.name AS name,
		auser.rights,
		auser.is_default,
		auser_to_auser.rights AS user_rights
	FROM
		auser_to_auser,
		auser
	WHERE
		auser_to_auser.parent_id = auser.auser_id
		AND auser_to_auser.auser_id IN (^if(def $sUserList){$sUserList}{$user.user_id})
		AND auser.auser_type_id = $GROUP_ID
	ORDER BY
		auser.name
}]
#end @getUserGroups[]



###########################################################################
# get group users
@getGroupUsers[iGroupId]
$result[^oSql.table{
	SELECT
		auser.auser_id,
		auser.auser_type_id,
		auser.name,
		auser.email,
		auser.is_published,
		auser.rights,
		auser.description
	FROM
		auser_to_auser,
		auser
	WHERE
		auser_to_auser.auser_id = auser.auser_id
		AND auser_to_auser.parent_id IN (^iGroupId.int(0))
		AND auser.auser_type_id = $USER_ID
	ORDER BY
		auser.name
}]
#end @getGroupUsers[]



###########################################################################
# достает из БД Access Control List (ACL) списка пользователей (групп, овнера) на объекты
@getACL[sObjectList;sUserList]
$result[^oSql.table{
	SELECT
		acl.object_id,
		acl.rights,
		auser.auser_id,
		auser.name,
		auser.description,
		auser.auser_type_id,
		auser.rights AS user_rights
	FROM
		acl,
		auser
	WHERE
		acl.auser_id = auser.auser_id
		^if(def $sObjectList){
			AND acl.object_id IN ($sObjectList)
		}
		^if(def $sUserList){
			AND acl.auser_id IN ($sUserList)
		}
	ORDER BY
		auser.name
}]
#end @getACL[]




###########################################################################
# возвращает информацию о ACL пользователя и групп, в которых он состоит на объекты
@getFullACL[object_list][obj_list;acl]
$obj_list[^if($object_list is "table" && $object_list){^object_list.menu{$object_list.id}[,]}{$object_list}]

^self.loadUserGroups[]

^rem{ *** у объекта owner auser_id = 1 *** }
$acl[^self.getACL[$obj_list;1,^user.groups.menu{$user.groups.group_id,}$user.user_id]]
$result[
	$.user[^acl.select($acl.auser_type_id == $USER_ID)]
	$.group[^acl.select($acl.auser_type_id == $GROUP_ID)]
	$.owner[^acl.select($acl.auser_type_id == $OWNER_ID)]
]
#end @getFullACL[]




###########################################################################
@addRightsToHash[h;sKey;iRights]
^if($h is "hash" && def $sKey){
	$h.[$sKey]($iRights)
}
$result[]
#end @addRightsToHash[]



###########################################################################
# Вычисляет эффективные права текущего пользователя на объект, рекурсивно вызывая себя при необходимости
# Полученые права сохраняет в хеше, чтобы повторно не считать их
# в $object [table/hash] должен быть сам объект ($object.id, $object.parent_id, $object.irf)
# в $thread [table] должны быть все его родители (с такими-же полями, как минимум)
# в $acl [hash] должны быть права юзера, овнера, групп, в которых он состоит, на все объекты треда
@getRightsToObject[object;thread;acl;is_owner][parent_rights;level_user_acl;level_group_acl;level_owner_acl;level_rights]
^if($object){
	^if($rights_hash.[$object.id]){
		^rem{ *** если права есть в хеше - забираем их *** }
		$result($rights_hash.[$object.id])
	}{
		^if($thread){
			^if(^object.irf.int(0)){
				^rem{ *** если у объекта irf не равен 0 - вычисляем права на родителя, вызывая себя рекурсивно *** }
				^rem{ *** если locate не находит очередного родителя - значит достаем права данные на root *** }
				$parent_rights(^self.getRightsToObject[^if(^thread.locate[id;$object.parent_id]){$thread.fields};$thread;$acl;$is_owner])
			}{
				^rem{ *** irf равен 0 (все замаскировано) - права можно не считать *** }
				$parent_rights(0)
			}
			^rem{ *** вычисляем права, данные на текущий объект пользователю (+ как овнеру) и группам в которых он состоит *** }
			$level_rights(0)
			$level_user_acl[^acl.user.select($acl.user.object_id == $object.id)]
			^if($level_user_acl){
				^rem{ *** если есть право данное непосредственно пользователю, то это право перекрывает право данное через группы *** }
				$level_rights($level_rights | $level_user_acl.rights)
			}{
				^rem{ *** добавляем права, данные ему через членство в группах *** }
				$level_group_acl[^acl.group.select($acl.group.object_id == $object.id)]
				^level_group_acl.menu{$level_rights($level_rights | $level_group_acl.rights)}
			}
			^rem{ *** добавляем его права как owner-а, если установлен флаг $is_owner *** }
			^if($is_owner){
				$level_owner_acl[^acl.owner.select($acl.owner.object_id == $object.id)]
				^level_owner_acl.menu{$level_rights($level_rights | $level_owner_acl.rights)}
			}
			
			^rem{ *** к правам пришедших от родителя добавляем права, данные на этот объект (с учетом irf объекта) *** }
			$result(($parent_rights & ^object.irf.int(0)) | $level_rights)
        	
			^rem{ *** кладем посчитаное значение в хеш, чтобы не считать еще раз, если понадобится *** }
			^self.addRightsToHash[rights_hash;$object.id;$result]
		}{
			^rem{ *** не передали информацию о треде, а он нам нужен. посчитать ничего не можем... *** }
			^throw[auth;Thread with objects MUST be defined.]
		}
	}
}{
	^rem{ *** не задан object, значит просят права на root - отдаем их *** }
	^if($rights_hash.[0]){
		^rem{ *** если права есть в хеше - забираем их *** }
		$result($rights_hash.[0])
	}{
		^if($user.rights){
			$result($user.rights)
		}{
			$result(0)
			^user.groups.menu{
				$result($result | $user.groups.rights)
			}
		}
		^self.addRightsToHash[rights_hash;0;$result]
	}
}
#end @getRightsToObject[]




###########################################################################
@saveParam[sName;sValue;iExpires]
^if(def $sName){
	$cookie:[$sName][
		$.value[$sValue]
		^if($iExpires){
			$.expires($iExpires)
		}{
			$.expires[session]
		}
	]
}
$result[]
#end @saveParam[]




###########################################################################
@isEmail[sEmail]
$result(^Lib:isEmail[$sEmail])
#end @isEmail[]



###########################################################################
# set Last-Modified or Expires http headers
@setExpireHeaders[uDate]
^dtf:setExpireHeaders[$uDate]
$result[]
#end @setExpireHeaders[]
 


###########################################################################
# cript sPassword. generate random if it wasn't cpecified 
@cryptPassword[sPassword]
$result[^math:crypt[^if(def $sPassword){$sPassword}{^math:random(1000000)};^$apr1^$]]
#end @cryptPassword[]



###########################################################################
@isValidPassword[sPassword;sPasswordCrypted]
^try{
	$result(
		def $sPassword
		&& def $sPasswordCrypted
		&& ^math:crypt[$sPassword;$sPasswordCrypted] eq $sPasswordCrypted
	)
}{
	$exception.handled(1)
	$result(false)
}
#end @isValidPassword[]



###########################################################################
# print xml for logon form
@xmlFormLogon[hParam]
$hParam[^hash::create[$hParam]]
^untaint[xml]{
	<^if(def $hParam.tag_name){$hParam.tag_name}{auth-logon}
		method="post"
		^if(def $hParam.target_url){
			action="$hParam.target_url"
		}
	>
		$hParam.addon
		<field type="hidden" name="auth.logon" value="do" />
		<field type="text" name="auth.name" value="^if(def $logon_data.[auth.logon]){$logon_data.[auth.name]}{$last_name}" description="Логин" />
		<field type="password" name="auth.passwd" description="Пароль" />
		<field type="checkbox" name="auth.persistent" value="1"^if($is_persistent){ selected="selected"} description="Запомнить" />
		<field type="submit" name="action" value="^if(def $hParam.action_name){$hParam.action_name}{Войти}" />
	</^if(def $hParam.tag_name){$hParam.tag_name}{auth-logon}>
}
#end @xmlFormLogon[]



###########################################################################
# print xml for logout form
@xmlFormLogout[hParam]
^if($is_logon){
	$hParam[^hash::create[$hParam]]
	^untaint[xml]{
		<^if(def $hParam.tag_name){$hParam.tag_name}{auth-logout}
			method="post"
			^if(def $hParam.target_url){
				action="$hParam.target_url"
			}
		>
			$hParam.addon
			<login-name>$user.name</login-name>
			<field type="hidden" name="auth.logout" value="do" />
			<field type="submit" name="action" value="^if(def $hParam.action_name){$hParam.action_name}{Завершить работу}" />
		</^if(def $hParam.tag_name){$hParam.tag_name}{auth-logout}>
	}
}
#end @xmlFormLogout[]



###########################################################################
@xmlFormProfile[hParams][_hParams]
^self.setExpireHeaders[]
$_hParams[^hash::create[$hParams]]
<^if(def $_hParams.tag_name){$_hParams.tag_name}{form}
	method="post"
	^if(def $_hParams.target_url){
		action="$_hParams.target_url"
	}
>
^untaint[xml]{
	$_hParams.addon
	<field type="hidden" name="do" value="^if(def $_hParams.do){$_hParams.do}{register}" />

	<field type="text" name="auth.name" value="^if(def $_hParams.fields.[auth.name]){$_hParams.fields.[auth.name]}{$user.name}" description="Login" required="1" />
	<field type="text" name="auth.email" value="^if(def $_hParams.fields.[auth.email]){$_hParams.fields.[auth.email]}{$user.email}" description="E-mail" required="1" />
	<field type="password" name="auth.passwd" description="Пароль"^if(!$is_logon){ required="1"} />
	<field type="password" name="auth.passwd_confirm" description="Подтверждение пароля"^if(!$is_logon){ required="1"} />

	<field type="submit" name="action" value="^if(def $_hParams.action_name){$_hParams.action_name}{^if($is_logon){Сохранить}{Зарегистрироваться}}" />
	$_hParams.post_addon
}
</^if(def $_hParams.tag_name){$_hParams.tag_name}{form}>
#end @xmlFormProfile[]



###########################################################################
# print html for logon form
@htmlFormLogon[hParam]
$hParam[^hash::create[$hParam]]
^untaint[html]{
	<form
		method="post"
		^if(def $hParam.target_url){
			action="$hParam.target_url"
		}
	>
		<input type="hidden" name="auth.logon" value="do" />
		Логин:<br />
		<input type="text" name="auth.name" value="^if(def $logon_data.[auth.logon]){$logon_data.[auth.name]}{$last_name}" /><br />
		Пароль:<br />
		<input type="password" name="auth.passwd" description="Пароль" /><br />
		<input type="checkbox" name="auth.persistent" value="1"^if($is_persistent){ checked="checked"} id="auth.persistent"/><label for="auth.persistent"> Запомнить</label><br />
		<input type="submit" name="action" value="^if(def $hParam.action_name){$hParam.action_name}{Войти}" />
	</form>
}
#end @htmlFormLogon[]



###########################################################################
# print html for logout form
@htmlFormLogout[hParam]
^if($is_logon){
	$hParam[^hash::create[$hParam]]
	^untaint[html]{
		<form
			method="post"
			^if(def $hParam.target_url){
				action="$hParam.target_url"
			}
		>
			<input type="hidden" name="auth.logout" value="do" />
			<input type="submit" name="action" value="^if(def $hParam.action_name){$hParam.action_name}{Завершить работу}" />
		</form>
	}
}
#end @htmlFormLogout[]



###########################################################################
@htmlFormProfile[hParams][_hParams]
^self.setExpireHeaders[]
$_hParams[^hash::create[$hParams]]
<form
	method="post"
	^if(def $_hParams.target_url){
		action="$_hParams.target_url"
	}
>
^untaint[html]{
	$_hParams.addon
	<input type="hidden" name="do" value="^if(def $_hParams.do){$_hParams.do}{register}" />

	* Login:<br />
	<input type="text" name="auth.name" value="^if(def $_hParams.fields.[auth.name]){$_hParams.fields.[auth.name]}{$user.name}" /><br />
	* E-mail:<br />
	<input type="text" name="auth.email" value="^if(def $_hParams.fields.[auth.email]){$_hParams.fields.[auth.email]}{$user.email}"/><br />
	^if(!$is_logon){* }Пароль:<br />
	<input type="password" name="auth.passwd" /><br />
	^if(!$is_logon){* }Подтверждение пароля:<br />
	<input type="password" name="auth.passwd_confirm" /><br />

	<input type="submit" name="action" value="^if(def $_hParams.action_name){$_hParams.action_name}{^if($is_logon){Сохранить}{Зарегистрироваться}}" />
	$_hParams.post_addon
}
</form>
#end @htmlFormProfile[]
