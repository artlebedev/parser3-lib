###########################################################################
# $Id: NConvert.p,v 1.10 2013/10/18 03:31:07 misha Exp $
# Author: Den Kulikoff <http://www.kulikoff.net/parser3/img/>
# Implementation for working with images using NConvert <http://www.xnview.com>


@CLASS
NConvert

@USE
Img.p

@BASE
Img



###########################################################################
@auto[]
$sDefaultScript[nconvert]
#end @auto



###########################################################################
@create[hParams]
^BASE:create[$hParams]
#end @create



###########################################################################
@_parseInfo[fInfo][sDummy]
$result[
	$.hRaw[^hash::create[]]
]
^if(!$fInfo.status && def $fInfo.text){
	$sDummy[^fInfo.text.match[^^\s*(\S.+\S)\s+:\s+(.+)\s*^$][gm]{
		$result.hRaw.[$match.1][$match.2]
		^switch[$match.1]{
			^case[Name]{$result.sFormat[$match.2]}
			^case[Compression;Orientation]{$result.[s$match.1][$match.2]}
			^case[Width;Height]{$result.[i$match.1]($match.2)}
			^case[Xdpi;Ydpi]{$result.[i$match.1][$match.2]}
			^case[# colors]{$result.iColors[$match.2]}
		}
	}]
}
#end @_parseInfo



###########################################################################
@_exec[sAction;hParams][hOptions]
^if($hParams.sFormat ne "gif"){
	^hParams.delete[iColors]
}
$hOptions[^if(def $sCharset && $sCharset ne $request:charset){$.charset[$sCharset]}{^hash::create[]}]
$result[^switch[$sAction]{
	^case[info]{^file::exec[$hScript.$sAction;$hOptions;-info;$hParams.sInput]}
	^case[convert]{^file::exec[$hScript.$sAction;$hOptions;-o;$hParams.sOutput;^if(^hParams.bRemoveMeta.int(0)){-rmeta}{-quiet};-out;$hParams.sFormat;-q;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};$hParams.sInput]}
	^case[rotateJPG]{^file::exec[$hScript.$sAction;$hOptions;-jpegtrans;$hParams.sAngle;$hParams.sInput]}
	^case[rotate]{^file::exec[$hScript.$sAction;$hOptions;-o;$hParams.sOutput;-rotate;$hParams.iAngle;-bgcolor;$hParams.iR;$hParams.iG;$hParams.iB;^if($hParams.bRemoveMeta){-rmeta}{-quiet};-out;$hParams.sFormat;-q;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};$hParams.sInput]}
	^case[crop]{^file::exec[$hScript.$sAction;$hOptions;-o;$hParams.sOutput;-crop;$hParams.iX;$hParams.iY;$hParams.iCropWidth;$hParams.iCropHeight;^if($hParams.bRemoveMeta){-rmeta}{-quiet};-out;$hParams.sFormat;-q;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};$hParams.sInput]}
	^case[resize]{^file::exec[$hScript.$sAction;$hOptions;-o;$hParams.sOutput;-resize;^if(def $hParams.sWidth){$hParams.sWidth}{0};^if(def $hParams.sHeight){$hParams.sHeight}{0};^if($hParams.bKeepRatio){-ratio}{-quiet};^if(def $hParams.sFlag){-rflag}{-quiet};^if(def $hParams.sFlag){$hParams.sFlag}{-quiet};-out;$hParams.sFormat;-q;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};^if($hParams.bRemoveMeta){-rmeta}{-quiet};-rtype;$hParams.sRType;$hParams.sInput]}
	^case[watermark]{^file::exec[$hScript.$sAction;$hOptions;-o;$hParams.sOutput;-wmfile;$hParams.sWMFile;-wmpos;^hParams.iX.int(0);^hParams.iY.int(0);^if(def $hParams.sPosition){-wmflag}{-quiet};^if(def $hParams.sPosition){$hParams.sPosition}{-quiet};^if($hParams.iOpacity){-wmopacity}{-quiet};^if($hParams.iOpacity){$hParams.iOpacity}{-quiet};^if($hParams.bRemoveMeta){-rmeta}{-quiet};-out;$hParams.sFormat;-q;$hParams.iQuality;$hParams.sInput]}
	^case[DEFAULT]{^throw[$sClassName;;Action '$sAction' is not implemented yet]}
}]
# info about last exec (for debugging)
$self.fResult[$result]
#end @_exec



@_getResampleType[sAction;sType]
$result[^switch[$sType]{
	^case[q;quick]{quick}
	^case[l;linear]{linear}
	^case[h;hermite]{hermite}
	^case[b;bell]{bell}
	^case[bs;bspline]{bspline}
	^case[DEFAULT]{^BASE:_getResampleType[$sAction;$sType]}
}]
#end @_getResampleType



@_getAngle[sAction;iAngle]
$result[^switch[^iAngle.int(0)]{
	^case(90;-270){rot90}
	^case(180;-180){rot180}
	^case(270;-90){rot270}
	^case[DEFAULT]{^throw[$sClassName;$sAction;Unsupported angle '$iAngle']}
}]
#end @_getAngle



@_getResizeType[sAction;sResizeType]
$result[^switch[$sResizeType]{
	^case[orient]{$sResizeType}
	^case[DEFAULT]{^BASE:_getResizeType[$sAction;$sResizeType]}
}]
#end @_getResizeType



@_getPosition[sAction;sPosition]
$result[^switch[$sPosition]{
	^case[top-left;left-top]{top-left}
	^case[top-center;center-top]{top-center}
	^case[top-right;right-top]{top-right}
	^case[center-left;left-center]{center-left}
	^case[center]{center}
	^case[center-right;right-center]{center-right}
	^case[bottom-left;left-bottom]{bottom-left}
	^case[bottom-center;center-bottom]{bottom-center}
	^case[bottom-right;right-bottom]{bottom-right}
	^case[DEFAULT]{^throw[$sClassName;$sAction;Unknown position type '$sPosition']}
}]
#end _getPosition
