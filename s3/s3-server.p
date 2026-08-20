###########################################################################
# $Id: s3-server.p,v 2026/08/19 moko $
#
# .htaccess rules:
# RewriteEngine On
# RewriteCond %{REQUEST_FILENAME} -f
# RewriteRule .* - [L]
# RewriteRule .* /s3-server.p [L,QSA]

@auto[]
$MAX_KEYS(1000)
# root buckets storage directory
$PREFIX[/storage]
# temporal parts directory
$MULTIPART[/multipart]
# buckets hash; cgi-bin/.htaccess should have CGIPassAuth On to access header with access_key_id
$ALLOW[
	$.default[
		$.ip[^^127\.0\.0\.1]
		$.accessKeyId[]
	]
]

##################################### Support #####################################

@log[operation][now;line]
#$now[^date::now[]]
#$line[$env:REMOTE_ADDR [^now.sql-string[]] "$request:method $request:uri" $operation $response:status^#0A]
#^line.save[append;/../temp/s3.log]

##############################
@xmlResponse[nodename;content]
$response:content-type.value[application/xml]
<?xml version="1.0" encoding="UTF-8"?>
<$nodename xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
$content
</$nodename>

##############################
@validate[result]
# uploadId is our own md5 hex, partNumber is decimal — both fit [0-9a-fA-F]+;
# reject anything else before it ever touches a filesystem path
^if(!^result.match[^^[0-9a-fA-F]+^$]){
	^throw[$.type[validation] $.comment[invalid characters in "$result"]]
}

##############################
@validatePath[result]
# a normal request should never contain ".."
^if(^result.pos[..]>=0){
	^throw[$.type[validation] $.comment[path traversal in "$result"]]
}

##############################
@auth[][locals][allow;credKeyId]
# IP mask + access_key_id from the Authorization header — not a real SigV4 check
$allow[$ALLOW.$bucket]
$credKeyId[^env:HTTP_AUTHORIZATION.match[Credential=([^^/]+)]]
$result(def $allow && (!def $allow.ip || ^env:REMOTE_ADDR.match[$allow.ip]) && (!def $allow.accessKeyId || $credKeyId.1 eq $allow.accessKeyId))

############################## HTTP method handlers ###############################

@notFound[]
$response:status[404]
$result[The requested URL was not found on this server.]
^log[not-found]

##############################
@bucketCreate[]
# bucket-level PUT (e.g. rclone's CreateBucket) — no object key, nothing to store
^log[bucket-noop]

##############################
@bucketList[][locals]
# ListObjectsV2-style single-level bucket listing: honors prefix/delimiter (so clients
# walking the tree directory-by-directory get correct results) and max-keys/continuation-token
# (real pagination — CommonPrefixes are cheap and returned in full, only Contents is paginated)
$prefix[$form:prefix]
$dir[$path/^validatePath[$prefix]]
$contents[^table::create{key^#09size^#09mtime}[]]
$prefixes[^table::create{prefix}[]]
^if(-d $dir){
	$entries[^file:list[$dir][$.stat(true)]]
	^entries.menu{
		^if($entries.dir){
			^prefixes.append[$.prefix[${prefix}${entries.name}/]]
		}{
			$stat[^file::stat[$dir/$entries.name]]
			^contents.append[$.key[${prefix}${entries.name}] $.size[$entries.size] $.mtime[^stat.mdate.iso-string[]]]
		}
	}
}
^contents.sort{$contents.key}

$maxKeys[^form:max-keys.int($MAX_KEYS)]
^if($maxKeys < 1 || $maxKeys > $MAX_KEYS){ $maxKeys($MAX_KEYS) }
$token[$form:continuation-token]
^if(!def $token){ $token[$form:marker] }

$page[^table::create{key^#09size^#09mtime}[]]
$truncated[]
$lastKey[]
$skipping(def $token)
^contents.menu{
	^if($skipping){
		^if($contents.key eq $token){ $skipping[] }
	}(^page.count[] >= $maxKeys){
		$truncated(1)
		^break[]
	}{
		^page.append[$.key[$contents.key] $.size[$contents.size] $.mtime[$contents.mtime]]
		$lastKey[$contents.key]
	}
}

$keyCount($page+$prefixes)

$result[^xmlResponse[ListBucketResult]{
	<Name>$bucket</Name>
	<Prefix>$prefix</Prefix>
	<Delimiter>/</Delimiter>
	<MaxKeys>$maxKeys</MaxKeys>
	<KeyCount>$keyCount</KeyCount>
	<IsTruncated>^if($truncated){true}{false}</IsTruncated>
	^if($truncated){
		<NextContinuationToken>$lastKey</NextContinuationToken>
		<NextMarker>$lastKey</NextMarker>
	}
	^page.menu{
		<Contents>
			<Key>$page.key</Key>
			<LastModified>$page.mtime</LastModified>
			<Size>$page.size</Size>
			<StorageClass>STANDARD</StorageClass>
		</Contents>
	}
	^prefixes.menu{
		<CommonPrefixes>
			<Prefix>$prefixes.prefix</Prefix>
		</CommonPrefixes>
	}
}]
^log[listed]

##############################
@putObject[]
^request:body-file.save[binary;$path]
$response:etag["^request:body-file.md5[]"]
^log[saved]

##############################
@deleteObject[]
^if(-f $path){
	^file:delete[$path]
	$response:status[204]
	^log[deleted]
	$result[]
}{
	$result[^notFound[]]
}

##############################
@redirectToObject[]
^if(-f $path){
	$response:location[$path]
	^log[redirected]
}{
	$result[^notFound[]]
}

################################ Multipart upload #################################

@initiateMultipart[][locals]
# parts are staged separately and assembled on complete — never touches the final key
$uploadId[^math:md5[$path $status:pid ^math:random(1000000)]]
$result[^xmlResponse[InitiateMultipartUploadResult]{
	<Bucket>$bucket</Bucket>
	<Key>$key</Key>
	<UploadId>$uploadId</UploadId>
}]
^log[multipart-initiated]

##############################
@uploadPart[][locals]
$partPath[$MULTIPART/$path/^validate[$form:uploadId]/^validate[$form:partNumber]]
^request:body-file.save[binary;$partPath]
$response:etag["^request:body-file.md5[]"]
^log[multipart-part]

##############################
@completeMultipart[][locals]
# ignores the client's part list/etags — just assembles whatever we actually received,
# in ascending part-number order, which is all that matters for a single trusted client
$partsDir[$MULTIPART/$path/^validate[$form:uploadId]]
^if(-d $partsDir){
	$partFiles[^file:list[$partsDir]]
	^partFiles.sort(^partFiles.name.int(0))
	^partFiles.menu{
		^file:copy[$partsDir/$partFiles.name;$path;$.append(^partFiles.line[] > 1)]
		^file:delete[$partsDir/$partFiles.name]
	}
	$result[^xmlResponse[CompleteMultipartUploadResult]{
		<Bucket>$bucket</Bucket>
		<Key>$key</Key>
		<ETag>"^file:md5[$path]"</ETag>
	}]
	^log[multipart-completed]
}{
	$result[^notFound[]]
}

##############################
@abortMultipart[][locals]
$partsDir[$MULTIPART/$path/^validate[$form:uploadId]]
^if(-d $partsDir){
	$partFiles[^file:list[$partsDir]]
	^partFiles.menu{
		^file:delete[$partsDir/$partFiles.name]
	}
}
$response:status[204]
^log[multipart-aborted]

##################################### Entry point #####################################

@route[]
^switch[$request:method]{
	^case[PUT]{
		^if(def $form:partNumber){
			^uploadPart[]
		}(!def $key){
			^bucketCreate[]
		}{
			^putObject[]
		}
	}
	^case[POST]{
		^if(def $form:uploadId){
			^completeMultipart[]
		}{
			^initiateMultipart[]
		}
	}
	^case[DELETE]{
		^if(def $form:uploadId){
			^abortMultipart[]
		}{
			^deleteObject[]
		}
	}
	^case[GET]{
		^if(!def $key){
			^bucketList[]
		}{
			^redirectToObject[]
		}
	}
	^case[HEAD]{
		^redirectToObject[]
	}
	^case[DEFAULT]{
		^notFound[]
	}
}

@main[][parts]
$path[^validatePath[$request:path]]

$parts[^path.split[/][a]]
$bucket[$parts.1]
$key[^path.mid(^bucket.length[]+2)]

$path[$PREFIX/$path]

^if(!def $bucket){
	$result[Bucket should be specified]
}(^auth[]){
	$result[^route[]]
}{
	$response:status[403]
	$result[Permission denied]
	^log[forbidden]
}
