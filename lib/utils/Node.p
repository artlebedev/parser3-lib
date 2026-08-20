############################################################
# $Id: Node.p,v 1.18 2011-10-05 00:51:18 misha Exp $

@CLASS
Node


@USE
Doc.p
Attrs.p


############################################################
@auto[]
$sDummyRoot[dummy-root-tag]
###


############################################################
# print $xNode as string
@toString[xNode;sRootTag][result;xDoc;_tmp]
^if($xNode){
	$xDoc[^xdoc::create[$sDummyRoot]]
	$_tmp[^xDoc.documentElement.appendChild[^xDoc.importNode[$xNode](1)]]

	$result[^Doc:toString[$xDoc]]
	$result[^result.match[</?^taint[regex][$sDummyRoot]>][g]{}]
}{
	$result[]
}
^if(def $sRootTag){
	$result[^self.tag[$sRootTag;;$result]]
}
###


############################################################
# print $xNode VALUE as string: <aaa><bbb>ccc</bbb></aaa> => "<bbb>ccc</bbb>"
@valueToString[xNode;sRootTag][result]
$result[^self.toString[$xNode]]
^if(def $result){
	$result[^result.match[^^<(^taint[regex][$xNode.nodeName])[^^>]*>(.*)</\1>^$][]{$match.2}]
}
^if(def $sRootTag){
	$result[^self.tag[$sRootTag;;$result]]
}
###


############################################################
@tag[sTagName;oAttrs;sBody]
^if(def $sTagName){
	$result[<$sTagName^if(def $oAttrs){^oAttrs.string[]}^if(def $sBody){>$sBody</$sTagName>}{/>}]
}{
	$result[$sBody]
}
###


############################################################
# go through all nodes in $hNodeList and execute $jCode
@foreach[hNodeList;hNodeName;sNode;sAttr;jCode;sSeparator][result;i;xNode]
$result[^for[i](0;$hNodeList-1){$xNode[$hNodeList.$i]^if(^self._isRequestedNode[$xNode;$hNodeName]){$caller.$sNode[$xNode]^if(def $sAttr){$caller.$sAttr[^Attrs:hash[$xNode]]}$jCode}}[$sSeparator]]
###


############################################################
# go through all children for $xParent and execute $jCode
@foreachChild[xParent;hNodeName;sNode;sAttr;jCode;sSeparator][result;xNode]
$xNode[$xParent.firstChild]
$result[^while($xNode){^if(^self._isRequestedNode[$xNode;$hNodeName]){$caller.$sNode[$xNode]^if(def $sAttr){$caller.$sAttr[^Attrs:hash[$xNode]]}$jCode}$xNode[$xNode.nextSibling]}[$sSeparator]]
###


############################################################
# get children of $xParent as hash
@getChildren[xParent;hNodeName][result;xNode]
$result[^hash::create[]]
$xNode[$xParent.firstChild]
^while($xNode){^if(^self._isRequestedNode[$xNode;$hNodeName]){$result.[$xNode.nodeName][^self.toString[$xNode]]}$xNode[$xNode.nextSibling]}
###


############################################################
@getAttributes[uData][result]
$result[^Attrs:hash[$uData]]
###


############################################################
@printAttributes[uData;uExclude;uAddon][result]
$result[^Attrs:string[$uData;;$uExclude;$uAddon]]
###


############################################################
@_isRequestedNode[xNode;hNodeName][result]
$result($xNode.nodeType == $xdoc:ELEMENT_NODE && (!def $hNodeName || def $hNodeName.[$xNode.nodeName]))
###
