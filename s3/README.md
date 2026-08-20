# Simple Amazon S3 Server

**Author**: [moko](https://www.parser.ru/forum/members/?id=6), August 19, 2026
**Tags**: S3

A simple Amazon S3-compatible server implements just enough of the S3 API — single-part and multipart object uploads, GET/HEAD/DELETE on objects, and a `ListObjectsV2`-style bucket listing — to work as the backend for a real S3 client such as `rclone`.

## Hooking it up

Point Apache's CGI/mod_parser handler at `s3-server.p` and rewrite everything that isn't already an existing static file to it:

```
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} -f
RewriteRule .* - [L]
RewriteRule .* /s3-server.p [L,QSA]
```

The first rule lets Apache serve any file that already exists on disk directly. Everything else — writes, multipart operations, bucket listing, and the redirect trick used for GET/HEAD on individual keys — falls through to the script.

S3 clients authenticate by sending an access key id in the `Authorization` header, but Apache strips that header from CGI requests by default. The script needs it passed through as `$env:HTTP_AUTHORIZATION`:

```
CGIPassAuth On
```

This directive must apply to the `cgi-bin` directory itself, not the directory holding the `RewriteRule`s above — set it there directly in Apache's config, or in `cgi-bin/.htaccess` if `AllowOverride` allows it.

Without it, `^auth[]` never sees a `Credential=...` value — any bucket whose `$ALLOW` entry requires a matching `$.accessKeyId` will reject every request with 403. Buckets that rely on the IP check alone aren't affected.

## Access control and adding buckets

There's no bucket-creation API — the `PUT` clients normally use to create a bucket is a no-op here. Which bucket names a client is actually *allowed* to write to is a separate matter, controlled by the `$ALLOW` hash in `@auto[]`, keyed by bucket name:

```parser3
$ALLOW[
	$.default[
		$.ip[^^127\.0\.0\.1]
		$.accessKeyId[]
	]
]
```

To add a new bucket, add another entry under `$ALLOW` with the bucket name as the key:

```parser3
$ALLOW[
	$.default[
		$.ip[^^127\.0\.0\.1]
		$.accessKeyId[]
	]
	$.my-bucket[
		$.ip[^^10\.0\.0\.^#0-9^#0-9?^$]
		$.accessKeyId[some-secret-id]
	]
]
```

Each entry supports two independent checks, both optional:

* `$.ip` — a regex matched against `$env:REMOTE_ADDR`. Omit it to allow any address.
* `$.accessKeyId` — compared against the access key id parsed out of the request's `Authorization` header (the `Credential=...` part). Omit it to allow any key.

Requests for a bucket that isn't listed in `$ALLOW` are rejected outright. Note that this is deliberately *not* a real AWS SigV4 signature check — there's no verification that the request was actually signed with a matching secret key. It's just enough to keep a bucket restricted to a known IP and/or a shared access key id acting as a bearer token; treat `$.accessKeyId` as a shared secret, not as real request authentication.

## Storage layout

* `$PREFIX` (`/storage`) — where finished objects live, one subdirectory per bucket, mirroring each object's key directly as a filesystem path.
* `$MULTIPART` (`/multipart`) — a staging area for in-progress multipart uploads. Parts are written under `bucket/key/uploadId/partNumber` and only get assembled into the final object once the client sends `CompleteMultipartUpload`; an aborted or abandoned upload just leaves orphaned part files there.
* The request log is optionally written to a file.

## Supported operations

| Operation | Request | Notes |
| --- | --- | --- |
| Create bucket | `PUT` with no key | a bucket's directory appears on disk the first time an object is written to it |
| List objects | `GET` with no key | `ListObjectsV2`-style; supports `prefix`, `delimiter`, `max-keys`, and `continuation-token`/`marker` pagination |
| Put object | `PUT` | single-part upload; sets the response `ETag` from the uploaded body's md5 |
| Get / Head object | `GET` / `HEAD` | served via a CGI Local Redirect, so Apache streams the file directly instead of Parser |
| Delete object | `DELETE` | |
| Initiate multipart upload | `POST` (no `uploadId`) | |
| Upload part | `PUT` with `partNumber` and `uploadId` | |
| Complete multipart upload | `POST` with `uploadId` | assembles parts in ascending part-number order |
| Abort multipart upload | `DELETE` with `uploadId` | deletes any staged parts |

[Original documentation on parser.ru](https://www.parser.ru/lib/s3/)
