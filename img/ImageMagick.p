###########################################################################
# $Id: ImageMagick.p,v 1.9 2013/10/18 03:31:07 misha Exp $
# Author: Michael V. Petrushin <http://www.parser.ru/forum/users/?uid=17>
# Implementation for working with images using ImageMagick <http://www.imagemagick.org/>


@CLASS
ImageMagick

@USE
Img.p

@BASE
Img



###########################################################################
@auto[]
$sDefaultScript[convert]
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
	$sDummy[^fInfo.text.match[^^\s*(\S.+\S):\s+(.+)\s*^$][gm]{
		$result.hRaw.[$match.1][$match.2]
		^switch[$match.1]{
			^case[Format]{
				$result.sFormat[^match.2.match[^^(\S+)\s.*][]{^match.1.lower[]}]
			}
			^case[Geometry]{
				$sDummy[^match.2.match[^^(\d+)x(\d+)][]{
					$result.iWidth($match.1)
					$result.iHeight($match.2)
				}]
			}
			^case[Compression;Orientation;Quality]{$result.[s$match.1][$match.2]}
			^case[Colors;Colormap]{$result.iColors($match.2)}
			^case[Resolution]{
				$sDummy[^match.2.match[^^(\d+)x(\d+)][]{
					$result.iXdpi($match.1)
					$result.iYdpi($match.2)
				}]
			}
		}
	}]
}
#end @_parseInfo



###########################################################################
@_exec[sAction;hParams][hOptions]
^if($sAction eq "watermark" && !$hScript && $hScript.$sAction eq $sDefaultScript){
#	watermark can't be applyed by 'convert' so it's necessary to specify another script name
	^throw[$sClassName;;For applying watermark ^$.ScriptName option must be specified in constructor]
}
^if($hParams.sFormat ne "gif"){
	^hParams.delete[iColors]
}
$hOptions[^if(def $sCharset && $sCharset ne $request:charset){$.charset[$sCharset]}{^hash::create[]}]
$result[^switch[$sAction]{
	^case[info]{^file::exec[$hScript.$sAction;$hOptions;-identify;-verbose;$hParams.sInput;null:]}
	^case[convert]{^file::exec[$hScript.$sAction;$hOptions;$hParams.sInput;^if($hParams.bRemoveMeta){-strip}{-quiet};-format;$hParams.sFormat;-quality;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};$hParams.sOutput]}
#	^case[rotateJPG]{^file::exec[$hScript.$sAction;$hOptions;$hParams.sInput;-jpegtrans;$hParams.sAngle;$hParams.sOutput]}
	^case[rotate]{^file::exec[$hScript.$sAction;$hOptions;$hParams.sInput;-background;rgb($hParams.iR,$hParams.iG,$hParams.iB);-rotate;$hParams.iAngle;^if($hParams.bRemoveMeta){-strip}{-quiet};-quality;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};$hParams.sOutput]}
	^case[crop]{^file::exec[$hScript.$sAction;$hOptions;$hParams.sInput;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};-quality;$hParams.iQuality;-crop;${hParams.iCropWidth}x${hParams.iCropHeight}+${hParams.iX}+${hParams.iY};^if($hParams.bRemoveMeta){-strip}{-quiet};-format;$hParams.sFormat;$hParams.sOutput]}
	^case[resize]{^file::exec[$hScript.$sAction;$hOptions;$hParams.sInput;-filter;$hParams.sRType;-quality;$hParams.iQuality;^if($hParams.iColors){-colors}{-quiet};^if($hParams.iColors){$hParams.iColors}{-quiet};-resize;${hParams.sWidth}x${hParams.sHeight}^if(!$hParams.bKeepRatio){!}^switch[$hParams.sFlag]{^case[incr]{<}^case[decr]{>}};^if($hParams.bRemoveMeta){-strip}{-quiet};-format;$hParams.sFormat;$hParams.sOutput]}
	^case[watermark]{^file::exec[$hScript.$sAction;$hOptions;^if(def $hParams.sPosition){-gravity}{-quiet};^if(def $hParams.sPosition){$hParams.sPosition}{-quiet};^if(def $hParams.iX || def $hParams.iY){-geometry}{-quiet};^if(def $hParams.iX || def $hParams.iY){^if(def $hParams.iX){+$hParams.iX}{0}^if(def $hParams.iY){+$hParams.iY}{0}}{-quiet};^if($hParams.iOpacity){-dissolve}{-quiet};^if($hParams.iOpacity){$hParams.iOpacity}{-quiet};^if($hParams.bRemoveMeta){-strip}{-quiet};-format;$hParams.sFormat;-quality;$hParams.iQuality;$hParams.sWMFile;$hParams.sInput;$hParams.sOutput]}
	^case[DEFAULT]{^throw[$sClassName;;Action '$sAction' is not implemented yet]}
}]
# info about last exec (for debugging)
$self.fResult[$result]
#end @_exec



@_getPosition[sAction;sPosition]
$result[^switch[$sPosition]{
	^case[top-left;left-top]{NorthWest}
	^case[top-center;center-top]{North}
	^case[top-right;right-top]{NorthEast}
	^case[center-left;left-center]{West}
	^case[center]{Center}
	^case[center-right;right-center]{East}
	^case[bottom-left;left-bottom]{SouthWest}
	^case[bottom-center;center-bottom]{South}
	^case[bottom-right;right-bottom]{SouthEast}
	^case[DEFAULT]{^throw[$sClassName;$sAction;Unknown position type '$sPosition']}
}]
#end _getPosition
