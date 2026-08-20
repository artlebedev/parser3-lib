###########################################################################
# $Id: AntispamTuringCaptcha.p,v 1.2 2010-10-14 05:13:01 misha Exp $

@CLASS
AntispamTuringCaptcha

@USE
AntispamTuring.p
utils/Cached.p

@BASE
AntispamTuring



###########################################################################
@auto[]
$oCachedSymbolDir[^Cached::create[]]
$oCachedSymbolImage[^Cached::create[]]
#end @auto[]



###########################################################################
@create[hParam]
$hParam[^hash::create[$hParam]]

$sImageDir[$hParam.sImageDir]
^if(!def $sImageDir){
	^self._abort[create;^$.sImageDir value must be defined]
}

$tSymbol[^file:list[$sImageDir;^^[a-zA-Z\d]^$]]
$tSymbol[^tSymbol.select(-d "$sImageDir/$tSymbol.name")]
^if(!$tSymbol){
	^self._abort[create;Directory $sImageDir doesn't contain information about available symbols]
}

$iLimit(^hParam.iLimit.int(5))
^if($iLimit < 3){
	^self._abort[create;^$.iLimit value much be 3 or higher]
}

$iCaptchaImageWidth(^if($hParam.iCaptchaImageWidth)($hParam.iCaptchaImageWidth;300))
$iCaptchaImageHeight(^if($hParam.iCaptchaImageHeight)($hParam.iCaptchaImageHeight;25))

$iSpaceWidth(^if($hParam.iSpaceWidth)($hParam.iSpaceWidth;5))

^if($hParam.tColor is "table"){
	$tColor[$hParam.tColor]
}{
	$tColor[^table::create{iColor
0x000000
0xCC0000
0x008800
0x0000FF
}]
}

$iNoiseDensity(^if($hParam.iNoiseDensity)($hParam.iNoiseDensity;30))

$bCropWidth(^hParam.bCropWidth.bool(true))

$iShiftX(^hParam.iShiftX.int(2))
$iShiftY(^hParam.iShiftY.int(2))

^BASE:create[$hParam]
#end @create[]



###########################################################################
@getTuringTest[sHREF][sCode;iCount]
$sCode[]
$iCount($tSymbol)
^for[i](1;$iLimit){
	^tSymbol.offset(^math:random($iCount))
	$sCode[${sCode}$tSymbol.name]
}
^self.set[$sCode]

^if(!def $sHREF){
	$sHREF[/_/captcha.html]
}
$result[$sHREF^if(^sHREF.pos[?]>=0){&amp^;}{?}$FIELD.hUid.sName=$UID]
#end @getTuringTest[]



###########################################################################
@generateImage[][fImage;sValidValue;i;sSymbol;sSymbolDir;tVariant;tList;fSymbol;iOffsetX;iOffsetY;fResult;iPosX;iNoisePixelsCount;tNoiseColor;iX;iSymbolWidth]
$fImage[^image::create($iCaptchaImageWidth;$iCaptchaImageHeight;0xFFFFFF)] 
^try{
	$sValidValue[^self.get[]]
	^if(!def $sValidValue){
		^self._warning[unknown-uid;Unknown UID (duplicate post or UID is expired)]
	}

	$iPosX(5)
	$iOffsetX(0)
	$iOffsetY(0)
	^for[i](1;$iLimit){
		$sSymbol[^sValidValue.mid($i-1;1)]

		^rem{ *** get random symbol's image *** }
		$sSymbolDir[$sImageDir/$sSymbol]
		
		$tVariant[^oCachedSymbolDir.exec[$sSymbol]{
			$tList[^file:list[$sSymbolDir/;\.gif^$]]
			$tList[^tList.select(-f "$sSymbolDir/$tList.name")]
			^if(!$tList){
				^self._abort[runtime;Symbol '$sSymbol' doesn't have any imagees]
			}
			$tList
		}]
		^tVariant.offset(^math:random($tVariant))
		$fSymbol[^oCachedSymbolImage.exec[$sSymbol=$tVariant.name]{^image::load[$sSymbolDir/$tVariant.name]}]

		^rem{ *** random shifts *** }
		^if($iShiftX){
			$iOffsetX(^math:random(2*$iShiftX+1)-$iShiftX)
		}
		$iX($iPosX+$iOffsetX)
		^if($iShiftY){
			$iOffsetY(^math:random(2*$iShiftY+1)-$iShiftY)
		}
		$iSymbolWidth($fSymbol.width)
		^fImage.copy[$fSymbol](0;0;$iSymbolWidth;$fSymbol.height;$iX;$iOffsetY)

		^if($tColor){
			^rem{ *** replace symbol's color *** }
			^tColor.offset(^math:random($tColor))
			^fImage.replace(0x000000;$tColor.iColor)[^table::create{x	y
$iX	0
^eval($iX+$iSymbolWidth)	0
^eval($iX+$iSymbolWidth)	^eval($iCaptchaImageHeight-1)
$iX	^eval($iCaptchaImageHeight-1)}]
		}

		^iPosX.inc($iSymbolWidth + $iSpaceWidth)
	}

	^if($bCropWidth && $iPosX+1 < $iCaptchaImageWidth){
		^rem{ *** crop resulting image *** }
		$fResult[^image::create($iPosX+1;$iCaptchaImageHeight;0)]
		^fResult.copy[$fImage](0;0;$iPosX+1;$iCaptchaImageHeight;0;0)
	}{
		$fResult[$fImage]
	}

	^if($iNoiseDensity){
		^rem{ *** add simple noise *** }
		$iNoisePixelsCount($fResult.width * $fResult.height / $iNoiseDensity)
		$tNoiseColor[^table::create{iColor}]
		^for[i](0;32){^tNoiseColor.append{^math:random(0x1000000)}}
		^for[i](0;$iNoisePixelsCount){
			^fResult.pixel(^math:random($fResult.width);^math:random($fResult.height);$tNoiseColor.iColor)
			^tNoiseColor.offset[cur](1)
		}
	}
	$result[^fResult.gif[]]
}{
	$exception.handled(true)
	^fImage.line(0;0;$iCaptchaImageWidth-1;$iCaptchaImageHeight-1;0xAAAAAA)
	^fImage.line(0;$iCaptchaImageHeight-1;$iCaptchaImageWidth-1;0;0xAAAAAA)
	^fImage.rectangle(0;0;$iCaptchaImageWidth-1;$iCaptchaImageHeight-1;0xAAAAAA)
	$result[^fImage.gif[]]
}
#end @generateImage[]
