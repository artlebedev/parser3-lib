##############################
# $Id: Img.p,v 1.11 2013/10/18 03:31:07 misha Exp $
# Author: Den Kulikoff <http://www.kulikoff.net/parser3/img/>
# Base class for working with images.
# Some methods must be overrided: see NConvert.p or ImageMagic.p for details.
#
# Common input params for most methods:
#	sFileSrc  - source image file
#	sFileDest - dest image file. methods will modify source if dest wasn't specified
#	sFormat   - dest image format. it will taked from file extension if wasn't specified
#	not required params can be specified in hParams
##############################

@CLASS
Img


##############################
@auto[]
$sClassName[Img]

# declaration
$sDefaultPath[]
$sDefaultScript[]

$sDocRoot[$request:document-root]
$sDummy[dummy]
#end @auto



##############################
#	Params which can be used by other methods as default
#	$.iColors - number of colors for gif (256, 216, 128, 64 [default], 32, 16 or 8)
#	$.iQuality - jpeg quality (default - 80)
#	$.bRemoveMeta - remove meta information (exif, ...)
#	$.bKeepRatio - keep aspect ratio
@create[hParams][sDir;sScriptName]
$hScript[^hash::create[]]
$hParams[^hash::create[$hParams]]

$sDir[^if(def $hParams.sScriptPath){$hParams.sScriptPath}{$sDefaultPath}]
$sScriptName[^if(def $hParams.sScriptName){$hParams.sScriptName}{$sDefaultScript}]
^self._addActionScript[_default;$sDir/$sScriptName]

^if($hParams.hScriptName is "hash"){
	^hParams.hScriptName.foreach[sAction;sScriptName]{
		^self._addActionScript[$sAction;$sDir/$sScriptName]
	}
}

$hDefault[
	$.iColors(^hParams.iColors.int(64))
	$.iQuality(^hParams.iQuality.int(80))
	$.bRemoveMeta(^hParams.bRemoveMeta.int(0))
	$.bKeepRatio(^hParams.bKeepRatio.int(0))
]
$sCharset[$hParams.sCharset]
#end @create



##############################
# get image info
@info[sFileSrc][fResult]

^self._checkInputFile[info;$sFileSrc]

$fResult[^self._exec[info;
	$.sInput[$sDocRoot/$sFileSrc]
]]

$result[^self._parseInfo[$fResult]]

^if(!$result.hRaw){
	^throw[$sClassName;info;Unknown image format '$sFileSrc']
}
#end @info



##############################
#	$.bRemoveMeta, $.iQuality and $.iColors are applicable in hParams
@convert[sFileSrc;sFileDest;sFormat;hParams][fResult]
$hParams[^self._prepareParams[$hParams]]

^if(!def $sFormat && !def $sFileDest){
	^throw[$sClassName;convert;Format or destination file MUST be specified]
}

^hParams.add[^self._getFiles[convert;$sFileSrc;$sFileDest;$sFormat;$hParams]]

$fResult[^self._createDirAndExec[convert;$hParams]]

$result($fResult.status)
#end @convert



##############################
#	$iAngle - angle in degrees (+/-90, 180, +/-270)
@rotateJPG[sFileSrc;iAngle][fResult]
$fResult[^self._exec[rotateJPG;
	^self._getFiles[rotateJPG;$sFileSrc]
	$.sAngle[^self._getAngle[rotateJPG]($iAngle)]
]]

$result($fResult.status)
#end @rotateJPG



##############################
#	$iAngle - angle in degrees
#	$.sBGColor - background color (format: "R,G,B")
#	$.sFormat, $.bRemoveMeta, $.iQuality and $.iColors are applicable in hParams
@rotate[sFileSrc;sFileDest;iAngle;hParams][tColor;fResult]
$hParams[^self._prepareParams[$hParams]]

^if(def $hParams.sBGColor){
	$tColor[^hParams.sBGColor.split[,;lh]]
	^self._checkColor[rotate;$tColor.0]
	^self._checkColor[rotate;$tColor.1]
	^self._checkColor[rotate;$tColor.2]
}

^hParams.add[
	^self._getFiles[rotate;$sFileSrc;$sFileDest;$hParams.sFormat;$hParams]
	$.iAngle(^self._int[$iAngle])
	$.iR($tColor.0)
	$.iG($tColor.1)
	$.iB($tColor.2)
]

$fResult[^self._createDirAndExec[rotate;$hParams]]

$result($fResult.status)
#end @rotate



##############################
#	$iX, $iY - coords of top-left corner
#	$iCropWidth, $iCropHeight - selected area
#	$.sFormat, $.bRemoveMeta, $.iQuality and $.iColors are applicable in hParams
@crop[sFileSrc;sFileDest;iX;iY;iCropWidth;iCropHeight;hParams][fResult;iCropWidth;iCropHeight]
$iCropWidth(^self._int[$iCropWidth])
$iCropHeight(^self._int[$iCropHeight])
^if(!$iCropWidth || !$iCropHeight){
	^throw[$sClassName;crop;Crop width and height MUST be specified]
}

$hParams[^self._prepareParams[$hParams]]
^hParams.add[
	^self._getFiles[crop;$sFileSrc;$sFileDest;$hParams.sFormat;$hParams]
	$.iX(^self._int[$iX])
	$.iY(^self._int[$iY])
	$.iCropWidth($iCropWidth)
	$.iCropHeight($iCropHeight)
]

$fResult[^self._createDirAndExec[crop;$hParams]]

$result($fResult.status)
#end @crop



##############################
#	$sWidth, $sHeight - dest sizes (can be in %)
#	$.sResizeType - resize type (see @_getResizeType[] implementation)
#	$.sResampleType - resize algorithm (see @_getResampleType[] implementation)
#	$.sFormat, $.bRemoveMeta, $.iQuality, $.iColors and $.bKeepRatio are applicable in hParams
@resize[sFileSrc;sFileDest;sWidth;sHeight;hParams][fResult]
$hParams[^self._prepareParams[$hParams]]

^if(!def $sWidth && !def $sHeight){
	^throw[$sClassName;resize;Width or height MUST be specified]
}

^hParams.add[
	^self._getFiles[resize;$sFileSrc;$sFileDest;$hParams.sFormat;$hParams]
	$.sWidth[$sWidth]
	$.sHeight[$sHeight]
	$.sRType[^self._getResampleType[resize;$hParams.sResampleType]]
	^if(def $hParams.sResizeType){
		$.sFlag[^self._getResizeType[resize;$hParams.sResizeType]]
	}
]

$fResult[^self._createDirAndExec[resize;$hParams]]

$result($fResult.status)
#end @resize



##############################
#	$sWMFile - applying image (the best way -- use transparented png)
#	$.iX, $.iY - coords of top-left corner
#	$.sPosition - watermark's position (see @_getPosition[])
#	$.sFormat - GIF format not applicable here
#	$.bRemoveMeta and $.iQuality are applicable in hParams
@watermark[sFileSrc;sFileDest;sWMFile;hParams][fResult]
$hParams[^self._prepareParams[$hParams]]

^if(def $hParams.sPosition && (def $hParams.iX || def $hParams.iY)){
	^throw[$sClassName;watermark;Only position or coordinates can be specified]
}

^if(def $sWMFile){
	^if(!-f $sWMFile){
		^throw[$sClassName;watermark;File '$sWMFile' not found]
	}
}{
	^throw[$sClassName;watermark;Watermark image MUST be specified]
}

^hParams.add[
	^self._getFiles[watermark;$sFileSrc;$sFileDest;$hParams.sFormat;$hParams]
	$.sWMFile[$sDocRoot/$sWMFile]
	^if(def $hParams.sPosition){
		$.sPosition[^self._getPosition[watermark;$hParams.sPosition]]
	}
	^if(def $hParams.iX || def $hParams.iY){
		$.iX(^self._int[$hParams.iX])
		$.iY(^self._int[$hParams.iY])
	}
	$.iOpacity(^self._getOpacity[watermark;$hParams.iOpacity])
]

$fResult[^self._createDirAndExec[watermark;$hParams]]

$result($fResult.status)
#end @watermark



##############################
# for internal use only

##############################

@_addActionScript[sAction;sScriptFileSpec]
^if(!-f $sScriptFileSpec){
	^throw[$sClassName;create;Script file '$sScriptFileSpec' not found]
}
$hScript.[$sAction][$sScriptFileSpec]
#end @_addActionScript



@_prepareParams[hParams]
^if($hParams is "hash"){
	$result[^hParams.union[$hDefault]]
}{
	$result[^hash::create[$hDefault]]
}
#end @_prepareParams



@_getFiles[sAction;sFileSrc;sFileDest;sFormat;hParams]
^self._checkInputFile[$sAction;$sFileSrc]
$result[
	$.sInput[$sDocRoot/$sFileSrc]
	$.sOutput[$sDocRoot/^if(def $sFileDest){$sFileDest}{$sFileSrc}]
	$.sFileDest[$sFileDest]
	$.sFormat[^self._getDestFormat[$sAction;$sFileSrc;$sFileDest;$sFormat]]
]
^if($result.sFormat eq "gif"){
	^self._checkNumberOfColors[$sAction;$hParams.iColors]
}
#end @_getFiles



@_checkColor[sAction;iColor]
^if(^iColor.int(-1) < 0 || ^iColor.int(0) > 255){
	^throw[$sClassName;$sAction;Invalid color specification, must be in [0..255]]
}
$result[]
#end @_checkColor



@_checkNumberOfColors[sAction;iColor]
^if(^iColor.int(0) < 1 || ^iColor.int(0) > 256){
	^throw[$sClassName;$sAction;Invalid number of colors value, must be in [1..256]]
}
$result[]
#end @_checkNumberOfColors



@_getOpacity[sAction;iOpacity]
$result(^iOpacity.int(0))
^if($result > 100){
	^throw[$sClassName;$sAction;Invalid opacity specification, must be in [1..100]]
}
^if($result == 100){
	$result(0)
}
#end @_getOpacity



@_checkInputFile[sAction;sFileSrc]
^if(!def $sFileSrc){^throw[$sClassName;$sAction;Source image MUST be specified]}
^if(!-f $sFileSrc){^throw[$sClassName;$sAction;Image '$sFileSrc' not found]}
$result[]
#end @_checkInputFile



@_createDirAndExec[sAction;hParams][sOutputDir;sDummyFileSpec;jDelete]
^if(def $hParams.sFileDest){
	$sOutputDir[^file:dirname[$hParams.sFileDest]]
}
^if(def $sOutputDir && !-d $sOutputDir){
	$sDummyFileSpec[$sOutputDir/$sDummy]
	^sDummy.save[$sDummyFileSpec]
	$jDelete{^file:delete[$sDummyFileSpec]}
	^try{
		$result[^self._exec[$sAction;$hParams]]
		$jDelete
	}{
		$jDelete
	}
}{
	$result[^self._exec[$sAction;$hParams]]
}
#end @_createDirAndExec



@_getDestFormat[sAction;sFileSrc;sFileDest;sFormat]
^if(!def $sFormat){
	$sFormat[^file:justext[^if(def $sFileDest){$sFileDest}{$sFileSrc}]]
}
$result[^switch[^sFormat.lower[]]{
	^case[j;jpg;jpeg;jpe]{jpeg}
	^case[g;gif;giff]{gif}
	^case[p;png]{png}
	^case[b;bmp]{bmp}
	^case[t;tif;tiff]{tiff}
	^case[DEFAULT]{^throw[$sClassName;$sAction;Unknown format type '$sFormat']}
}]
#end @_getDestFormat



@_int[sValue]
$result(^math:round(^sValue.double(0)))
#end @_int



##############################
# could be overrided

#	more types are implemented in NConvert.p
@_getResizeType[sAction;sResizeType]
$result[^switch[$sResizeType]{
	^case[incr;decr]{$sResizeType}
	^case[DEFAULT]{^throw[$sClassName;$sAction;Unknown resize type '$sResizeType']}
}]
#end @_getResizeType



#	more types are implemented in NConvert.p
@_getResampleType[sAction;sType]
$result[^switch[$sType]{
	^case[lz;lanczos;]{lanczos}
	^case[g;gaussian]{gaussian}
	^case[m;mitchell]{mitchell}
	^case[DEFAULT]{^throw[$sClassName;$sAction;Unknown resample type '$sType']}
}]
#end @_getResampleType[]




##############################
# must be overrided

@_getAngle[sAction;iAngle]
^throw[$sClassName;$sAction;Method '_getAngle' is not implemented yet]
#end @_getAngle



@_getPosition[sAction;sPosition]
^throw[$sClassName;$sAction;Method '_getPosition' is not implemented yet]
#end _getPosition



@_parseInfo[fInfo]
$result[^hash::create[]]
#end @_parseInfo



@_exec[sAction;hParams]
$result[
	$.stderr[Method '_exec' must be overrided]
	$.status(-1)
	$.text[]
]
#end @_exec

