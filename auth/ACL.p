###########################################################################
# $Id:	ACL.p,v 1.0 2006/02/15 17:46:45 misha Exp $


@CLASS
ACL


@USE
AUserType.p



###########################################################################
@auto[]
$sClassName[ACL]

# for caching ACLs and calculated rights
$hACL[^hash::create[]]
$hRights[^hash::create[]]
#end @auto[]



###########################################################################
@create[hParam]
$hParam[^hash::create[$hParam]]

^if(def $hParam.oSql){
	$self.oSql[$hParam.oSql]
}{
	^throw[$sClassName;^$.oSql must be specified.]
}

# select from DB only specified $sType
^if(def $hParam.sType){
	$self.sType[$hParam.sType]
}
#end @create[]



###########################################################################
@loadRights[]
^if(!($tRights is "table")){
	$tRights[^oSql.table{
		SELECT
			rights_id AS id,
			rights_type_id,
			name,
			name_short AS abbr,
			description
		FROM
			rights
		ORDER BY
			rights_id
	}[;
		$.sFile[rights.table]
	]]
	$hRights[^tRights.hash[abbr]]
}
#end @loadRights[]



###########################################################################
@loadACL[oUser][tACL;hRefererType;sRefererType;tRefererTypeACL]
^if(!($hACL.[$oUser.id] is "hash")){
	$tACL[^oSql.table{
		SELECT
			acl.referer_type,
			acl.referer_id,
			acl.auser_id,
			acl.rights,
			auser.auser_type_id
		FROM
			acl,
			auser
		WHERE
			acl.auser_id = auser.auser_id
			AND acl.auser_id IN (
				$AUserType:OWNER_ID
				, $oUser.id
				^if($oUser.groups){
					$tUserGroup[^oUser.groups.select($oUser.groups.is_published == 1)]
					^if($tUserGroup){
						^use[Lib.p]
						, ^Lib:makeList[$tUserGroup;group_id]
					}
				}
			)
			^if(def $self.sType){
				AND acl.referer_type = '$self.sType'
			}
	}]
	$hACL.[$oUser.id][^hash::create[]]
	$hRefererType[^tACL.hash[referer_type][$.distinct[tables]]]
	^hRefererType.foreach[sRefererType;tRefererTypeACL]{
		$hACL.[$oUser.id].[$sRefererType][^tRefererTypeACL.hash[auser_type_id][$.distinct[tables]]]
	}
}
$result[]
#end @loadACL[]



###########################################################################
# for specified sType return user ACL [todo: for specified items list ]
@getACL[oUser;sType]
^self.loadACL[$oUser]
$result[$hACL.[$oUser.id].$sType]
#end @getACL[]



###########################################################################
@isHaveRight[sRightAbbr;iRights]
^self.loadRights[]
$result(
	$iRights
	&& $hRights.$sRightAbbr
	&& $hRights.$sRightAbbr.id & $iRights
)
#end @isHaveRight[]



###########################################################################
# calculate and return effective $oUser rights to $hItem
# $hItem, $hTree must have fields: id, parent_id, irf, user_id
@getRightsToItem[oUser;sType;hItem;hTree][hACL;iRightType]
^if(def $oUser){
	^if($hItem){
		^if(def ^self.getRights[$oUser.id;$sType;$hItem.id]){
			^rem{ *** take rights to this item from cache if it already was calculated *** }
			$result(^self.getRights[$oUser.id;$sType;$hItem.id])
		}{
			^if($hTree && ^hItem.irf.int(0)){
				^rem{ *** hTree specified and irf != 0 - calculate user rights to parent first *** }
				$result(^hItem.irf.int(0) & ^self.getRightsToObject[$oUser;$sType;^if($hTree.[$hItem.parent_id]){$hTree.[$hItem.parent_id]};$hTree])
			}{
				^rem{ *** working without hierarchy or irf == 0 (all parent's rights will be masked anyway) *** }
				$result(0)
			}
			
			$hACL[^self.getACL[$oUser;$sType]]
			^if($hACL){
				^rem{ *** if rights to item given to user then rights given to him through groups will be ignored *** }
				$iRightType[^if($hACL.[$AUserType:USER] && ^hACL.[$AUserType:USER].locate[referer_id;$hItem.id]){$AUserType:USER}{$AUserType:GROUP}]
				$result(^self.sumRights($result)[$hACL.$iRightType;$hItem.id])
	        	
				^if($hItem.user_id == $oUser.id){
					^rem{ *** if user is the item's owner - add owner's rights *** }
					$result(^self.sumRights($result)[$hACL.[$AUserType:OWNER];$hItem.id])
				}
			}
			
			^self.putRights[$oUser.id;$sType;$hItem.id;$result]
		}
	}{
		^rem{ *** item wasn't specified - get rights to root *** }
		$result[^self.getRights[$oUser.id;$sType;0]]
		^if(def $result){
			^rem{ *** I hate if one variable can contain value in different types so convert string to int *** }
			$result(^result.int[])
		}{
			^if($oUser.rights){
				$result($oUser.rights)
			}{
				$result(^self.sumRights(0)[$oUser.groups])
			}
			
			^self.putRights[$oUser.id;$sType;0;$result]
		}
	}
}{
	$result(0)
}
#end @getRightsToItem[]



###########################################################################
@sumRights[iRights;tACL;sRefererID]
$result($iRights)
^if($tACL){
	$tACL[^tACL.select($tACL.referer_id eq $sRefererID)]
	^tACL.menu{$result($result | $tACL.rights)}
}
#end @sumRights[]



###########################################################################
@getRights[sUserID;sType;sRefererID]
$result[$hRights.[$sUserID].[$sType].$sRefererID]
#end @getRights[]



###########################################################################
@putRights[sUserID;sType;sRefererID;uValue]
^if(def $sRefererID){
	^if(!($hRights.[$sUserID] is "hash")){
		$hRights.[$sUserID][^hash::create[]]
	}
	^if(!($hRights.[$sUserID].[$sType] is "hash")){
		$hRights.[$sUserID].[$sType][^hash::create[]]
	}
	$hRights.[$sUserID].[$sType].[$sRefererID][$uValue]
}
$result[]
#end @putRights[]
