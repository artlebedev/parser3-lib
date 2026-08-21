# $Id: mdate.p,v 1.1 2005/11/04 16:35:00 Никита Козин [wonder@nightmail.ru] Exp $
@CLASS
mDate


@USE
dtf.p


@init[lparams]
$self.params[^hash::create[$lparams]]
^if(!def $self.params.format_string){
	$self.params.format_string[%o / %n]
}
^if(!def $self.params.dtf_format_string){
	$self.params.dtf_format_string[%d.%m.%Y %H:%M]
}
^if(!def $self.params.new_tag){
	$self.params.new_tag[font]
	$self.params.new_addtags[color="#cc0000"]
}
$self.params.dt_limit[^dtf:create[$self.params.dt_limit][^date::now(-1)]]
# end @init[]


@print[dt_1;dt_2]
$dt_1[^dtf:create[$dt_1]]
$dt_2[^dtf:create[$dt_2]]
^if(def $params.canvas_tag){
	$result[^_printTag[^_printDate[$dt_1;$dt_2]][$params.canvas_tag;$params.canvas_addtags]]
}{
	$result[^_printDate[$dt_1;$dt_2]]
}
# end @print[]


@_printDate[dt_1;dt_2]
^if(!def $dt_2 || (^dt_1.sql-string[] eq ^dt_2.sql-string[])){
	$result[^_printDateString[$dt_1]]
}{
	$result[^params.format_string.match[%(.)][g]{^switch[$match.1]{
		^case[o]{^_printDateString[$dt_1]}
		^case[n]{^_printDateString[$dt_2]}
		^case[DEFAULT]{%$match.1}
	}}]
}
# end @_printDate[]


@_printDateString[dt]
$dt_string[^dtf:format[$params.dtf_format_string;$dt;$dtf:[$params.dtf_locale]]]
^if(^_isNewDate[$dt]){
	$result[^_printTag[$dt_string][$params.new_tag;$params.new_addtags]]
}{
	$result[^_printTag[$dt_string][$params.old_tag;$params.old_addtags]]
}
# end @_printDateString[]


@_isNewDate[dt]
$dt[^dtf:create[$dt]]
^if($dt > $params.dt_limit){
	$result(1)
}{
	$result(0)
}
# end @_isNewDate[]


@_printTag[string;tag;addtags]
^if(def $tag){
	$result[<$tag^if(def $addtags){ $addtags}>$string</$tag>]
}{
	$result[$string]
}
# end @_printTag[]