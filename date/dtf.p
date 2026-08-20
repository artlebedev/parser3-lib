###########################################################################
# $Id: dtf.p,v 1.38 2014/02/27 06:50:33 misha Exp $
#
# @create[uDate;uDefault]	create new date object from string/date
# @format[sFormat;uDate;hLocale]	print date using format string
# @last-day[uDate]			return date of last day for month of specified[current] day
# @from822[sDate]			create date object from date string in RFC822/2822 format [!!! still under construction]
# @to822[uDate;sTZ]			print specified date in RFC822/2822 format [!!! still under construction]
# @setLocale[hLocale]		set new locale returning old one
# @resetLocale[]			reset locale to default


@CLASS
dtf


###########################################################################
@auto[][tmp;k;v]
# russian locale
$rr-locale[
	$.month[
		$.1[Января]
		$.2[Февраля]
		$.3[Марта]
		$.4[Апреля]
		$.5[Мая]
		$.6[Июня]
		$.7[Июля]
		$.8[Августа]
		$.9[Сентября]
		$.10[Октября]
		$.11[Ноября]
		$.12[Декабря]
	]
	$.weekday[
		$.0[Воскресенья]
		$.1[Понедельника]
		$.2[Вторника]
		$.3[Среды]
		$.4[Четверга]
		$.5[Пятницы]
		$.6[Субботы]
		$.7[Воскресенья]
	]
]
$ri-locale[
	$.month[
		$.1[Январь]
		$.2[Февраль]
		$.3[Март]
		$.4[Апрель]
		$.5[Май]
		$.6[Июнь]
		$.7[Июль]
		$.8[Август]
		$.9[Сентябрь]
		$.10[Октябрь]
		$.11[Ноябрь]
		$.12[Декабрь]
	]
	$.weekday[
		$.0[Воскресенье]
		$.1[Понедельник]
		$.2[Вторник]
		$.3[Среда]
		$.4[Четверг]
		$.5[Пятница]
		$.6[Суббота]
		$.7[Воскресенье]
	]
]
$rs-locale[
	$.month[
		$.1[Янв]
		$.2[Фев]
		$.3[Мар]
		$.4[Апр]
		$.5[Май]
		$.6[Июн]
		$.7[Июл]
		$.8[Авг]
		$.9[Сен]
		$.10[Окт]
		$.11[Ноя]
		$.12[Дек]
	]
	$.weekday[
		$.0[Вс]
		$.1[Пн]
		$.2[Вт]
		$.3[Ср]
		$.4[Чт]
		$.5[Пт]
		$.6[Сб]
		$.7[Вс]
	]
]
# english locale
$es-locale[
	$.month[
		$.1[Jan]
		$.2[Feb]
		$.3[Mar]
		$.4[Apr]
		$.5[May]
		$.6[Jun]
		$.7[Jul]
		$.8[Aug]
		$.9[Sep]
		$.10[Oct]
		$.11[Nov]
		$.12[Dec]
	]
	$.weekday[
		$.0[Sun]
		$.1[Mon]
		$.2[Tue]
		$.3[Wed]
		$.4[Thu]
		$.5[Fri]
		$.6[Sat]
		$.7[Sun]
	]
]
$ei-locale[
	$.month[
		$.1[January]
		$.2[February]
		$.3[March]
		$.4[April]
		$.5[May]
		$.6[June]
		$.7[July]
		$.8[August]
		$.9[September]
		$.10[October]
		$.11[November]
		$.12[December]
	]
	$.weekday[
		$.0[Sunday]
		$.1[Monday]
		$.2[Tuesday]
		$.3[Wednesday]
		$.4[Thursday]
		$.5[Friday]
		$.6[Saturday]
		$.7[Sunday]
	]
]
# ukrainian locale
$us-locale[
	$.month[
		$.1[Сiч]
		$.2[Лют]
		$.3[Бер]
		$.4[Квi]
		$.5[Тра]
		$.6[Чер]
		$.7[Лип]
		$.8[Сер]
		$.9[Вер]
		$.10[Жов]
		$.11[Лис]
		$.12[Гру]
	]
	$.weekday[
		$.0[Нед]
		$.1[Пон]
		$.2[Вiв]
		$.3[Сер]
		$.4[Чет]
		$.5[П'я]
		$.6[Суб]
		$.7[Нед]
	]
]
$ui-locale[
	$.month[
		$.1[Сiчень]
		$.2[Лютий]
		$.3[Березень]
		$.4[Квiтень]
		$.5[Травень]
		$.6[Червень]
		$.7[Липень]
		$.8[Серпень]
		$.9[Вересень]
		$.10[Жовтень]
		$.11[Листопад]
		$.12[Грудень]
	]
	$.weekday[
		$.0[Недiля]
		$.1[Понедiлок]
		$.2[Вiвторок]
		$.3[Середа]
		$.4[Четвер]
		$.5[П'ятниця]
		$.6[Субота]
		$.7[Недiля]
	]
]

$tz[
	$.CST[CST6CDT]
	$.EST[EST5EDT]
	$.GMT[GMT0BST]
	$.MET[MET-1DST]
	$.MED[MET-2DST]
	$.MSK[MSK-3MSD]
	$.MSD[MSD-4MSK]
	$.MST[MST7MDT]
	$.PST[PST8PDT]
}]

$default[$ri-locale]

$yy[]
$mm[]
$dd[]

$tmp[^self.setLocale[$default]]

$hRegex[
	$.oDT2822[^regex::create[^^(?:(Sun|Mon|Tue|Wed|Thu|Fri|Sat),\s+)?(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{2,4})\s+(\d{2}):(\d{2})(?::(\d{2}))?(?:\s+(?:(?:([-+]?\d{2})(\d{2}))|(?:(\w{3,5}))))?^$][i]]
	$.oSubstChar[^regex::create[%(.)][g]]
]
$hLocaleReverse[
	$.es[
		$.month[^es-locale.month.foreach[k;v]{$.[^v.lower[]]($k)}]
		$.weekday[^es-locale.weekday.foreach[k;v]{$.[^v.lower[]]($k)}]
	]
]



###########################################################################
# create new date object from string/date
# accept sql-like strings (%Y[-%m[-%d[ %H:%M[:%S]]]])
@create[uDate;uDefault][l;t]
^if(!def $uDate){
	$uDate[$uDefault]
}
^if($uDate is "date"){
	$result[^date::create($uDate)]
}{
	^if($uDate is "string"){
		$t[^uDate.match[$self.hRegex.oDT2822]]
		^if($t){
			$result[^self.from822[$t]]
		}{
			$result[^date::create[$uDate]]
		}
	}{
		^if($uDate is "double" || $uDate is "int"){
			$result[^date::unix-timestamp($uDate)]
		}
	}
}
^if(!def $result){
	^throw[$self.CLASS_NAME;create;Can't create date.]
}




###########################################################################
# print date using format string (posix/mysql mix)
# example: ^dtf:format[%Y-%m-%d], ^dtf:format[%d.%m.%Y;$date], ^dtf:format[%d %h %Y;$date;$dtf:rr-locale]
@format[sFormat;uDate;hLocale][dt;match]
$dt[^self.create[$uDate]{^date::now[]}]

^if(!def $hLocale){$hLocale[$self.locale]}

$result[^sFormat.match[$self.hRegex.oSubstChar][]{^switch[$match.1]{
	^case[%]{%}
	^case[n]{^#0A}
	^case[t]{^#09}

	^case[e]{$dt.day}
	^case[d]{^dt.day.format[%02d]}

	^case[c]{$dt.month}
	^case[m]{^dt.month.format[%02d]}
	^case[h;B]{$hLocale.month.[$dt.month]}
	^case[b]{^hLocale.month.[$dt.month].left(3)}

	^case[Y]{$dt.year}
	^case[y]{^eval($dt.year % 100)[%02d]}
	^case[j]{$dt.yearday}

	^case[w]{$dt.weekday}
	^case[A]{$hLocale.weekday.[$dt.weekday]}
	^case[a]{^hLocale.weekday.[$dt.weekday].left(3)}

	^case[D]{^dt.month.format[%02d]/^dt.day.format[%02d]/$dt.year}
	^case[F]{$dt.year/^dt.month.format[%02d]/^dt.day.format[%02d]}

	^case[H]{^dt.hour.format[%02d]}
	^case[k]{$dt.hour}
	^case[i;M]{^dt.minute.format[%02d]}
	^case[S]{^dt.second.format[%02d]}
	^case[s]{^dt.unix-timestamp[]}

	^case[T]{^dt.hour.format[%02d]:^dt.minute.format[%02d]:^dt.second.format[%02d]}
	^case[R]{^dt.hour.format[%02d]:^dt.minute.format[%02d]}
	^case[r]{^if($dt.hour > 0 && $dt.hour < 13){$dt.hour}{^if($dt.hour < 1)($dt.hour + 12)($dt.hour - 12)}:^dt.minute.format[%02d]:^dt.second.format[%02d]}
	^case[p]{^if($dt.hour > 11){PM}{AM}}
	^case[P]{^if($dt.hour > 11){pm}{am}}
	
	^case[_]{$self.es-locale.weekday.[$dt.weekday], ^dt.day.format[%02d] $self.es-locale.month.[$dt.month] $dt.year ^dt.hour.format[%02d]:^dt.minute.format[%02d]:^dt.second.format[%02d]}
}}]



###########################################################################
# return last day for specified[current] month
@last-day[uDate][dt]
$dt[^self.create[$uDate]{^date::now[]}]
$result[^date::create($dt.year;$dt.month;^dt.last-day[];0;0;0)]



###########################################################################
# set new locale returning old one
@setLocale[hLocale]
$result[$self.locale]
^if(def $hLocale){
	$self.locale[$hLocale]
	^self._init[]
}



###########################################################################
# reset locale to default
@resetLocale[]
$self.locale[$self.default]



###########################################################################
# create a date object from date string in RFC822/2822 format ( http://www.faqs.org/rfcs/rfc2822.html, http://www.faqs.org/rfcs/rfc822.html )
# WARNING: still under construction
@from822[uDate][t;h;sTZ;dt;iDiff;match]
^if($uDate is "table"){
	$t[$uDate]
}{
	$t[^uDate.match[$self.hRegex.oDT2822]]
}
^if(!$t){
	^throw[$self.CLASS_NAME;from822;Datetime string^if($uDate is "string"){ '$uDate'} does not match to RFC2822 date and time format]
}
$h[
	$.weekday[^self._get_by_abbr[weekday;$t.1]]
	$.day($t.2)
	$.month(^self._get_by_abbr[month;$t.3])
	$.year(^self._get_year[$t.4])
	$.hour($t.5)
	$.minute($t.6)
	$.second(^t.7.int(0))
	$.offset[
		$.hour[$t.8]
		$.minute[$t.9]
	]
	$.tz[^if(def $t.8){GMT}{$t.10}]
]

^try{
	$result[^date::create($h.year;$h.month;$h.day;$h.hour;$h.minute;$h.second)]

	^if(def $h.weekday && $h.weekday != $result.weekday){
		^throw[$self.CLASS_NAME;from822;Incorrect day of week '$h.weekday_abbr' (must be '$hLocale.es.weekday.[$result.weekday]')]
	}

	$sTZ[$self.tz.[$h.tz]]
	^if(def $sTZ){
		^rem{ *** roll to timezone (if not specified -- roll to GMT as offset is GMT-related) *** }
		$dt[^date::create[$result]]
		^dt.roll[TZ;$sTZ]
		$iDiff(^date::create($dt.year;$dt.month;$dt.day;$dt.hour;$dt.minute;$dt.second) - $result)
		$result[^date::create($dt - $iDiff)]
	}
	^if(def $h.offset.hour){
		^rem{ *** apply timezone offset *** }
		$result[^date::create($result - (^h.offset.hour.int(0) + ^h.offset.minute.int(0) / 60) / 24)]
	}

	^rem{ *** apply DST offset *** }
	^if($result.daylightsaving){
		$result[^date::create($result+$result.daylightsaving/24)]
	}
}{
	^if($exception.type ne $self.CLASS_NAME){
		$exception.handled(true)
		^throw[$self.CLASS_NAME;from822;Can't create date (${h.year}-${h.month}-$h.day ${h.hour}:${h.minute}:${h.second}). ${exception.comment}.]
	}
}



###########################################################################
# print specified date in RFC822/2822 format
# WARNING: still under construction
@to822[uDate;sTZ][dt]
$dt[^self.create[$uDate]{^date::now[]}]
^if($dt.daylightsaving){
	$dt[^date::create($dt-$dt.daylightsaving/24)]
}
^if(!def $sTZ){$sTZ[GMT]}
^if(def $self.tz.$sTZ){
	^dt.roll[TZ;$self.tz.$sTZ]
}
$result[^self.format[%_ $sTZ;^date::create($dt.year;$dt.month;$dt.day;$dt.hour;$dt.minute;$dt.second)]]



###########################################################################
# set http headers for prevent caching by browsers/proxies
@setExpireHeaders[uDate][result;dt]
^if(def $uDate){
	$dt[^self.create[$uDate]]
}
^if($dt && $dt < ^date::now(-7)){
	$response:Last-Modified[$dt]
}{
	$response:expires[^date::create(2001;01;01;01;01;01)]
	$response:cache-control[no-store, no-cache, must-revalidate, proxy-revalidate]
	$response:pragma[no-cache]
#	Opera cache page without it
	$response:Last-Modified[^date::now[]]
}
$result[]



# create and return months table
@_months[locale;is_lowercase][i]
^if(!def $locale){$locale[$self.locale]}
$result[^table::create{number	name
^for[i](1;12){$i	^if($is_lowercase){^locale.month.$i.lower[]}{$locale.month.$i}}[^#0A]}]



# create tables for day/month/year based on current locale
@_init[][i;_now]
$_now[^date::now[]]

$yy[^table::create{number	name
^for[i]($_now.year - 5;$_now.year + 5){$i	$i}[^#0A]}]

$dd[^table::create{number	name
^for[i](1;31){$i	^i.format{%02d}}[^#0A]}]

$mm[^self._months[]]
$mm-r[^self._months[$rr-locale]]



# fix 2 and 3 digit's year (for obsolete format)
@_get_year[sYear]
$result($sYear)
^switch(^sYear.length[]){
	^case(2){
		^if($result < 50){
			^result.inc(2000)
		}{
			^result.inc(1900)
		}
	}
	^case(3){
		^result.inc(1900)
	}
}



@_get_by_abbr[sField;sAbbr]
^if(def $sAbbr){
	$result($self.hLocaleReverse.es.[$sField].[^sAbbr.lower[]])
	^if(!$result){
		^throw[$self.CLASS_NAME;from822;Unknown $sField '$sAbbr']
	}
}{
	$result[]
}



###########################################################################
# backward for a while

@parse[date]
$result[^self.create[$date]]

@last-modifyed[date]
$result[^self.to822[$date]]


