############################################################
# $Id: MySqlComp.p,v 2.2 2012-07-30 11:53:53 misha Exp $

@CLASS
MySqlComp


@USE
MySql.p


@BASE
MySql



@create[sConnectString;hParams]
^BASE:create[$sConnectString;$hParams]
$self.date_diff[$self.dateDiff]
$self.date_sub[$self.dateSub]
$self.date_add[$self.dateAdd]
$self.date_format[$self.dateFormat]
$self.last_insert_id[$self.lastInsertID]
$self.set_last_insert_id[$self.setLastInsertID]
$self.left_join[$self.leftJoin]
