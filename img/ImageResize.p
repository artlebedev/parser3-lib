@CLASS
ImageResize


@create[hParams]
^if(!def $MAIN:IMAGE_CLASS){
	^throw[$self.CLASS_NAME;Global variable ^$MAIN:IMAGE_CLASS with image class name must be defined]
}
^if(!def $MAIN:EXEC_DIR){
	^throw[$self.CLASS_NAME;Global variable ^$MAIN:EXEC_DIR must be defined]
}
^if(!def $MAIN:TEMP_DIR){
	^throw[$self.CLASS_NAME;Global variable ^$MAIN:TEMP_DIR must be defined]
}
# Could be "NConvert" or "ImageMagick". Usually it should be defined in /../cgi/auto.p
^use[${MAIN:IMAGE_CLASS}.p]
$oImage[^reflection:create[$MAIN:IMAGE_CLASS;create;
	$.sScriptPath[$MAIN:EXEC_DIR]
	$.sScriptName[convert.^if(def $env:PARSER_VERSION && ^env:PARSER_VERSION.match[win32]){cmd}{sh}]
	$.bRemoveMeta(true)
	$.bKeepRatio(true)
]]
#end @create[]



@resize[uFileSrc;sFileDest;sWidth;sHeight;hParams][locals]
^if($uFileSrc is "file"){
	$fMeasure[^image::measure[$uFileSrc]]
	$sFileSrc[$MAIN:TEMP_DIR/^math:uuid[]]]
	^uFileSrc.save[binary;$sFileSrc]
	$bDelete(true)
}{
	$sFileSrc[$uFileSrc]
	$fMeasure[^image::measure[$sFileSrc]]
}
^if(!def $sFileDest){
	$sFileDest[$sFileSrc]
}
$hDestSize[
	$.iWidth(^sWidth.int(0))
	$.iHeight(^sHeight.int(0))
]

$hParams[^hash::create[$hParams]]
^switch[$hParams.sResizeType]{
	^case[stretch]{
		$bKeepRatio(false)
		$w[$hDestSize.iWidth]
		$h[$hDestSize.iHeight]
	}
	^case[fit-smallest-side]{
		$bKeepRatio(false)
		^if($fMeasure.width>$fMeasure.height){
			$iSourceBig($fMeasure.width)
			$iSourceSmall($fMeasure.height)
			$hTargetSize[
				$.iWidth($hDestSize.iWidth)
				$.iHeight($hDestSize.iHeight)
			]
		}{
			$iSourceBig($fMeasure.height)
			$iSourceSmall($fMeasure.width)
			$hTargetSize[
				$.iWidth($hDestSize.iHeight)
				$.iHeight($hDestSize.iWidth)
			]
		}
		^if($hDestSize.iWidth>$hDestSize.iHeight){
			$iTargetBig($hDestSize.iWidth)
			$iTargetSmall($hDestSize.iHeight)
		}{
			$iTargetBig($hDestSize.iHeight)
			$iTargetSmall($hDestSize.iWidth)
		}

		$hRatio[
			$.dBig($iSourceBig/$iTargetBig)
			$.dSmall($iSourceSmall/$iTargetSmall)
		]
		^if($hRatio.dBig > $hRatio.dSmall){
			$w[^math:floor($fMeasure.width/$hRatio.dSmall+0.5)]
			$h[^math:floor($fMeasure.height/$hRatio.dSmall+0.5)]
		}{
			$w[^math:floor($fMeasure.width/$hRatio.dBig+0.5)]
			$h[^math:floor($fMeasure.height/$hRatio.dBig+0.5)]
		}
		$iX(0)
		$iY(0)
		^if($w > $hTargetSize.iWidth){
			$iX(($w-$hTargetSize.iWidth)/2)
		}
		^if($h > $hTargetSize.iHeight){
			$iY(($h-$hTargetSize.iHeight)/2)
		}
	}
	^case[DEFAULT;fit-biggest-side]{
		$bKeepRatio(true)
		$w[$hDestSize.iWidth]
		$h[$hDestSize.iHeight]
	}
}

#^throw[;Ratios (big:small): $hRatio.dBig : $hRatio.dSmall, Original size: ${fMeasure.width}x$fMeasure.height, Final target size: ${hTargetSize.iWidth}x$hTargetSize.iHeight, Resize target size: ${w}x$h, Crop offsets (x:y): $iX : $iY | $sWidth : $sHeight]
^try{
	^if(^oImage.resize[$sFileSrc;$sFileDest;$w;$h;^hash::create[$hParams] $.sResizeType[decr] $.bKeepRatio($bKeepRatio)]){
		^throw[$sClassName;resize;Resizing the image is failed.]
	}
	^if(($iX || $iY) && ^oImage.crop[$sFileDest;;$iX;$iY;$hTargetSize.iWidth;$hTargetSize.iHeight;$hParams]){
		^throw[$sClassName;resize;Cropping the image is failed.]
	}
	^if($bDelete){
		^file:delete[$sFileSrc]
	}
}{
	^if($bDelete){
		^file:delete[$sFileSrc]
	}
}
