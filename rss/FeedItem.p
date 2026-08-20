###########################################################################
# $Id: FeedItem.p,v 1.2 2007/08/02 18:23:48 misha Exp $
###########################################################################

@CLASS
FeedItem

@USE
FeedAbstract.p

@BASE
FeedAbstract



###########################################################################
@auto[]
$sClassName[FeedItem]

$sTag[item]

$tField[^table::create{sName	sType	bRequired	uDefault
title	string
link	string
description	string
author	string
category	string
comments	string
enclosure	string
guid	string
pubDate	date
source	string
}]
#end @auto[]



###########################################################################
@create[hData]
^BASE:create[$hData]
#end @create[]



###########################################################################
@check[]
^if(!def ^getField[title] && !def ^getField[description]){
	^throw[$sClassName;At least one of fields: 'title' or 'derscription' must be specified.]
}
$result[]
#end @check[]



###########################################################################
@printField[hField;hParam]
$result[^switch[$hField.sName]{
	^case[guid]{<guid isPermaLink="true">^getField[$hField.sName]</guid>}
	^case[DEFAULT]{^BASE:printField[$hField;$hParam]}
}]
#end @printField[]



