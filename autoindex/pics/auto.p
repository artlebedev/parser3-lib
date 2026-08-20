@USE
AutoIndex.p
NConvert.p



###########################################################################
@auto[sFileSpec]
$sRootDir[^file:dirname[$sFileSpec]]
$sRootDir[^sRootDir.match[^^^taint[regex][$env:DOCUMENT_ROOT]][]{/}]
$sDir[^request:uri.match[\?.+][]{}]
$sRelativeDir[^sDir.match[^^^taint[regex][$sRootDir/]][]{}]
#end @auto[]



###########################################################################
@main[][oAutoIndex]
$oAutoIndex[^AutoIndex::create[$sDir;

# options for generate previews
	$.bAutoCreatePreviews(true)
	$.oImg[^NConvert::create[
		$.sScriptPath[/../exec]
		$.sScriptName[nconvert.exe]
		
		$.bRemoveMeta(true)
		$.bKeepRatio(true)
		$.iQuality(75)
		$.iColors(^hParams.iColors.int(64))
	]]
	$.iWidth(120)
	$.iHeight(120)

# operation options
#	$.bRemoveUnusedPreviews(true)

# display options
	$.hOrder[
		$.sField[N]
#		$.sDirection[desc]
	]
	$.tExclude[^table::create{sName^#0Aindex.htm}]
#	$.bIconsAreLinks(false)
#	$.bSuppressSorting(true)
#	$.bSuppressPreview(true)
#	$.bSuppressIcon(true)
#	$.bSuppressLastModified(true)
#	$.bSuppressSize(true)
#	$.bSuppressDescription(true)
]]

^oAutoIndex.exec[]

#end @main[]

