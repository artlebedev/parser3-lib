###########################################################################
# $Id: FeedChannel.p,v 1.4 2007/08/15 15:49:41 misha Exp $
###########################################################################

@CLASS
FeedChannel

@USE
ArrayList.p
FeedAbstract.p

@BASE
FeedAbstract



###########################################################################
@auto[]
$sClassName[FeedChannel]

$sTag[channel]

$tField[^table::create{sName	sType	bRequired	uDefault
title	string	1
link	string	1
description	string	1
language	string	0
copyright	string	0
managingEditor	string	0
webMaster	string	0
pubDate	date	0
lastBuildDate	date	0
category	string	0
generator	string	0	^if(def $env:PARSER_VERSION){$env:PARSER_VERSION}{Parser 3}
docs	string	0	http://blogs.law.harvard.edu/tech/rss
cloud	string	0
ttl	int	0
image	string	0
rating	int	0
#textInput	string	0
skipHours	string	0
skipDays	string	0
item	ArrayList	0
}]
#end @auto[]



###########################################################################
@create[hData]
^BASE:create[$hData]

^if(!(^getField[item] is "ArrayList")){
	^setField[item;^ArrayList::create[]]
}
#end @create[]



###########################################################################
@addItem[oItem][oItemList]
$oItemList[^getField[item]]
^oItemList.add[$oItem]
$result[]
#end @addItem[]



###########################################################################
@getLastItemPubDate[][oItemList;e;oItem;dtPubDate]
$oItemList[^getField[item]]
$e[^oItemList.getEnumerator[oItem]]
$result[]
^while(^e.moveNext[]){
	$dtPubDate[^oItem.getField[pubDate]]
	^if(def $dtPubDate && $dtPubDate > $result){
		$result[$dtPubDate]
	}
}
#end @getLastItemPubDate[]



###########################################################################
@printField[hField;hParam]
$result[^switch[$hField.sName]{
	^case[item]{^printItems[^getField[$hField.sName];$hParam]}
	^case[DEFAULT]{^BASE:printField[$hField;$hParam]}
}]
#end @printField[]



###########################################################################
@printItems[oValue;hParam][hItem;tIndex;e;oItem]
$hItem[^hash::create[]]
$tIndex[^table::create{iValue}]

$e[^oValue.getEnumerator[oItem]]
^while(^e.moveNext[]){
	$iIndex(^e.getIndex[])
	^tIndex.append{$iIndex}
	$hItem.[$iIndex][$oItem]
}

^if($hParam.bOrderItems){
	^tIndex.sort(^hItem.[$tIndex.iValue].getField[pubDate])[desc]
}
^if($hParam.iItemLimit){
	$tIndex[^table::create[$tIndex][$.limit($hParam.iItemLimit)]]
}
$result[^tIndex.menu{^hItem.[$tIndex.iValue].print[$hParam]}[^#0A]]
#end @printItems[]
