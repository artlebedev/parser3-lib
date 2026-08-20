###########################################################################
# $Id: FileSystem.p,v 1.11 2010-11-18 23:07:54 misha Exp $
###########################################################################


@CLASS
FileSystem



###########################################################################
@auto[]
$hDefault[
	$.hName[
		$.b[bytes]
		$.kb[KB]
		$.mb[MB]
	]
	$.sSpace[&nbsp^;]
	$.sFormat[%.1f]
]
#end @auto[]



###########################################################################
# return size for specified file or file with specified filename
@getFileSize[uFile][result;f]
$result[]
^if($uFile is "string" && def $uFile && -f $uFile){
	$f[^file::stat[$uFile]]
	$result($f.size)
}{
	^if($uFile is "file"){
		$result($uFile.size)
	}
}
#end @getFileSize[]



###########################################################################
# print string with file size. $.hName with bytes/KB/MB texts, $.sDecimalDivider and $.sFormat can be specified
@printFileSize[iSize;hParam][result;hOption]
^if(def $iSize){
	^if($hParam is "hash"){
		$hOption[^hParam.union[$hDefault]]
	}{
		$hOption[$hDefault]
	}
	^if($iSize < 1024){
		$result[${iSize}${hOption.sSpace}$hOption.hName.b]
	}{
		^if($iSize < 1048576){
			$result[^eval($iSize/1024)[$hOption.sFormat]${hOption.sSpace}$hOption.hName.kb]
		}{
			$result[^eval($iSize/1048576)[$hOption.sFormat]${hOption.sSpace}$hOption.hName.mb]
		}
	}
	$result[^result.match[\.0+(?=\D)][]{}]
	^if(def $hOption.sDecimalDivider){
		$result[^result.match[\.][]{$hOption.sDecimalDivider}]
	}
}{
	$result[]
}
#end @printFileSize[]



###########################################################################
@getRelativePath[sFileSpec]
^if(def ${request:document-root} && def $sFileSpec && ^sFileSpec.pos[$request:document-root]==0){
	$result[^sFileSpec.mid(^request:document-root.length[])]
	$result[/^result.trim[both;/]]
}{
	$result[]
}
#end @getRelativePath[]



###########################################################################
# $.bRecursive(true) - copy all subdirs
@copy[sFrom;tTo;hParam]
^if(def $sFrom && def $tTo){
	^if(-f $sFrom){
		^self.fileCopy[$sFrom;$tTo]
	}
	^if(-d $sFrom){
		^self.dirCopy[$sFrom;$tTo;$hParam]
	}
}
$result[]
#end @copy[]



###########################################################################
@fileCopy[sFileFrom;sFileTo][f]
^if(def $sFileFrom && def $sFileTo && $sFileFrom ne $sFileTo && -f $sFileFrom){
	^try{
		^file:copy[$sFileFrom;$sFileTo]
	}{
		^if($exception.comment eq "undefined method"){
			^rem{ *** parser prior 3.2.2 *** }
			$exception.handled(1)
			$f[^file::load[binary;$sFileFrom]]
			^f.save[binary;$sFileTo]
		}
	}
}
$result[]
#end @fileCopy[]



###########################################################################
# $.bRecursive(true) - copy all subdirs
@dirCopy[sDirFrom;sDirTo;hParam][tFile;sFromName;bRecursive]
^if(def $sDirFrom && def $sDirTo && $sDirFrom ne $sDirTo && -d $sDirFrom){
	$bRecursive(def $hParam && ($hParam.bRecursive || $hParam.is_recursive))
	$tFile[^file:list[$sDirFrom]]
	^tFile.menu{
		$sFromName[$sDirFrom/$tFile.name]
		^if($bRecursive && -d $sFromName){
			^self.dirCopy[$sFromName;$sDirTo/$tFile.name;$hParam]
		}{
			^if(-f $sFromName){
				^self.fileCopy[$sFromName;$sDirTo/$tFile.name]
			}
		}
	}
}
$result[]
#end @dirCopy[]



###########################################################################
@dirMove[sDirFrom;sDirTo][tFile;sFromName;sToName]
^if(def $sDirFrom && -d $sDirFrom){
	^if(!-d $sDirTo){
		^file:move[$sDirFrom;$sDirTo]
	}{
		$tFile[^file:list[$sDirFrom]]
		^tFile.menu{
			$sFromName[$sDirFrom/$tFile.name]
			$sToName[$sDirTo/$tFile.name]
			^if(-d $sFromName){
				^self.dirMove[$sFromName;$sToName]
			}{
				^file:move[$sFromName;$sToName]
			}
		}
	}
}
$result[]
#end @dirMove[]



###########################################################################
# $.bRecursive(true) - all subdirs will be deleted
@dirDelete[sDir;hParam][tFile;sFromName;bRecursive]
^if(def $sDir && -d $sDir){
	$bRecursive(def $hParam && ($hParam.bRecursive || $hParam.is_recursive))
	$tFile[^file:list[$sDir]]
	^tFile.menu{
		$sFromName[$sDir/$tFile.name]
		^if($bRecursive && -d $sFromName){
			^self.dirDelete[$sFromName;$hParam]
		}{
			^if(-f $sFromName){
				^try{
					^file:delete[$sFromName]
				}{
					$exception.handled(1)
				}
			}
		}
	}
}
$result[]
#end @dirDelete[]
