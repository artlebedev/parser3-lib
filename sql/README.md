# Classes for Working with MySQL, Oracle, MSSQL, and PgSQL

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), January 28, 2013
**Version**: 2.8
**Tags**: SQL

It's recommended to first read the article on [SQL query portability](https://www.parser.ru/examples/sql/).

It so happened that I wasn't entirely satisfied with the standard functionality of `^table::sql{}`, `^hash::sql{}` & Co. For example, I wanted to periodically get information about query execution time, the number of queries executed while building a document, log information about "slow" queries, cache the results of complex queries, connect automatically, and so on.

Since it seemed wrong to me to modify the parser's own code to solve tasks like these, I wrote SQL classes that provide the functionality I needed.

To connect the appropriate class, I add a line like this to the `@auto[]` method of the root auto.p (after linking the corresponding class with `@USE`):

```parser3
$oSql[^MySql::create[$SQL.connect-string;
	$.sCacheDir[/../data/sql_cache]
]]
```

This creates an instance of the MySql class in `$oSql`, whose methods I can call from anywhere in the code:

```parser3
@main[]
<html>
^oSql.server{
^rem{ *** fetched part of the data into the parser table $page *** }
<head>
	<title>$hPage.title</title>
</head>
	...
	^rem{ *** call methods that may run queries against the database,
since the connection is already established. *** }
	^printPageMenu[]

	^rem{ *** add a record to the info table *** }
	^oSql.void{INSERT INTO info (name) VALUES ('$form:name')}

	^rem{ *** fetch last_insert_id() and store it in the sort_order field
of the just-added record *** }
	$iLastInsertedId(^oSql.setLastInsertId[info;sort_order])
	...
}
</html>
```

When using the SQL classes, it's no longer necessary to place queries inside `connect` (which lives inside the `server` method). When you create an SQL object, you specify the connection string to the SQL server, so the class can establish the connection itself if you write a query outside the `server` method. Keep in mind that in this case each query is executed as a separate transaction — if that's not what you want, you'll still need to wrap the group of queries that should run as a single transaction yourself.

For most servers, the connect procedure to an SQL server is a fairly slow operation, so it's natural to worry whether multiple connects noticeably slow down code execution. They don't — Parser caches a connection once it's opened and doesn't reopen it, so feel free to use them (that said, out of habit I still use a single connect per page unless I need transactions).

To get debug information, you need to initialize the object slightly differently:

```parser3
$oSql[^MySql::create[$SQL.connect-string;
	$.bDebug(1)
	$.sCacheDir[/../data/sql_cache]
	^rem{ *** you can see the description of all options in Sql.p, right before the create constructor *** }
]]
```

and in the `@postprocess[]` method you can call the method that retrieves the statistics:

```parser3
@postprocess[sBody][oSqlLog]
$result[$sBody]
^if($oSql is "Sql"){
	^use[SqlLog.p]
	$oSqlLog[^SqlLog::create[$oSql]]
	^oSqlLog.log[
		$.iQueryTimeLimit(500)
		$.iQueriesLimit(25)
		$.iQueryRowsLimit(3000)
#		$.bExpandExceededQueriesToLog(1)
		^if(def $form:mode && ^form:tables.mode.locate[field;debug]){
			^rem{ *** if the page was requested with ?mode=debug, get and
save information about all sql queries *** }
			$.sFile[/../data/sql.txt]
			$.bAll(1)
		}{
			^rem{ *** otherwise, by default, write to a different log file
only information about problematic pages *** }
			$.sFile[/../data/sql.log]
		}
	]
}
```

With this in place, if the document is requested with the `?mode=debug` parameter, information about every query made through the `$oSql` object while building that document will be saved to `sql.txt`. During normal site operation, `sql.log` will instead record information about queries whose execution time exceeds 500 ms, or about pages where more queries were made than `iQueriesLimit` allows.

So I always initialize with `$.bDebug(1)` and make all SQL queries through the `$oSql` object, and I periodically check `sql.log` to see which queries were written poorly and need fixing.

It's worth adding that when working with MySQL, if debug output is enabled, an `EXPLAIN` is run for each query and its results are also written to the log — so when analyzing the logs it's immediately clear what needs attention. Note that `EXPLAIN` is only run for problematic queries, and only when the statistics are actually output, not for every single query; `$.bDebug(1)` by itself only measures the time/memory spent on each query (i.e. it's fast and not resource-intensive).

As you can see from the code, outputting the accumulated results is handled by a separate `SqlLog` class — so if you don't output this kind of statistics, that class's code isn't even loaded.

A couple of words about caching query results (if you don't want to use it, simply don't specify the `sCacheDir` parameter when creating the object).

Working with an SQL server is very convenient: information is stored in a structured form and can be retrieved in arbitrary chunks, but sometimes it turns out that optimizing a complex query without introducing redundancy is difficult or impossible. And if such a query operates on rarely-changing data, the simplest way out is to cache its results.

In principle, SQL servers do have their own query caching mechanisms, but us `^`-wranglers (Parser developers) don't always have access to those settings — so once again, these SQL classes can come to the rescue here, and they're quite simple to use:

```parser3
$tResult[^oSql.table{
	SELECT
		...
	FROM
		table_1,
		table_2,
		table_3
	WHERE
		...
	GROUP BY
		...
	HAVING
		...
	ORDER BY
		...
}[
	$.limit(10)
][
	$.sFile[hardcore_query.txt]
	$.dInterval(1/24)
]]
```

In this case, the complex SQL query will be executed once, and its results will be saved to the file `hardcore_query.txt`. On a repeat request (another visitor comes to view the page), the SQL query won't be executed again — the results will instead be taken directly from the saved file.

The caching parameter here says that the cache file will expire once an hour: once it expires, it will be deleted, and the very first request after expiration will run the SQL query — after which the file cache will kick in again.

A few more parameters are available: `$.dtExpirationTime[time]` clears the cache file on the first request after the specified time. This parameter can be combined with `dInterval` — in that case the cache file will be cleared both once per the given interval and when the specified time arrives.

Newer versions of the SQL classes have an auto-caching feature: instead of specifying a file name, you can simply set the `$.bAuto(1)` parameter, and the file name will be generated automatically from the query body and the limit/offset parameters (void queries are not cached). Keep in mind, though, that caching queries with user-supplied parameters (like search) doesn't make much sense: you'll end up with a huge pile of cache files, while repeat queries with the exact same conditions are unlikely.

If you'd like to enable auto-caching for all queries and don't want to write `$.bAuto(1)` over and over, you can specify the `$.bCacheAuto(1)` option when creating the object — auto-caching will then be enabled for all queries, and you can disable it for a specific query with `$.bAuto(0)`.

To force-delete a cache file, you can use the `clear` method:

```parser3
^oSql.clear[hardcore_query.txt]
```

This can be useful to call from an admin interface to force-delete a cache file when data changes in the tables involved in the query.

If you need to clear all cache files, you can do so by calling `clear` with no parameters.

Now it's time for the fly in the ointment: the new classes are not compatible with the old ones. If you want to switch to them, you'll need to rewrite the code that creates the SQL class objects and the code that logs information to files. The parameters of SQL queries themselves are backward-compatible with the old code, though to keep the old method names working you need to use the `MySqlComp` & Co classes instead of `MySql` & Co (see `upgrade.txt` in this directory for detailed upgrade instructions).

[Original documentation on parser.ru](https://www.parser.ru/en/lib/sql/)
