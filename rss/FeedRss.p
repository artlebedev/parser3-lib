###########################################################################
# $Id: FeedRss.p,v 1.3 2007/08/03 12:35:07 misha Exp $
###########################################################################

@CLASS
FeedRss

@USE
FeedChannel.p
FeedItem.p



###########################################################################
@auto[]
$sClassName[FeedRss]

$tVersion[^table::create{iValue	iID
2.0	4
0.92	2
0.91	1
}]
#end @auto[]



###########################################################################
@create[hChannel]
$oFeedChannel[^FeedChannel::create[]]

^set[$hChannel]
#end @create[]



###########################################################################
@set[hChannel]
^if(def $hChannel){
	^oFeedChannel.set[$hChannel]
}
$result[]
#end @set[]



###########################################################################
@addItem[hItem]
^oFeedChannel.addItem[^FeedItem::create[$hItem]]
$result[]
#end @addItem[]



###########################################################################
@print[hParam][sCharset;sVersion;dtLastItemPubDate]
$hParam[^hash::create[$hParam]]

^if(!def ^oFeedChannel.getField[pubDate] || !def ^oFeedChannel.getField[lastBuildDate]){
	$dtLastItemPubDate[^oFeedChannel.getLastItemPubDate[]]
	^if(def $dtLastItemPubDate){
		^if(!def ^oFeedChannel.getField[pubDate]){
			^oFeedChannel.setField[pubDate;$dtLastItemPubDate]
		}
		^if(!def ^oFeedChannel.getField[lastBuildDate]){
			^oFeedChannel.setField[lastBuildDate;$dtLastItemPubDate]
		}
	}
}

^if(def $hParam.sVersion){
	^if(^tVersion.locate[iValue;$hParam.sVersion]){
		$sVersion[$hParam.sVersion]
	}{
		^throw[$sClassName;Unsupported ^$.sVersion value '$hParam.sVersion' was specified.]
	}
}{
	$sVersion[$tVersion.iValue]
}

$sCharset[^if(def $hParam.sCharset){$hParam.sCharset}{$response:charset}]

^if(!$hParam.bOmitHTTPHeaders){
	$response:content-type[
		$.value[text/xml]
		$.charset[$sCharset]
	]
	
	^if(def ^oFeedChannel.getField[lastBuildDate]){
		$response:Last-Modified[^oFeedChannel.getField[lastBuildDate]]
	}
}

$result[^if(!$hParam.bOmitXMLDeclaration){<?xml version="1.0" encoding="$sCharset"?>^#0A}<rss version="$sVersion">
^untaint[xml]{^oFeedChannel.print[$hParam]}
</rss>]
#end @print[]



