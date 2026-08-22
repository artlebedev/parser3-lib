# Outputting RSS

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), August 3, 2007
**Version**: 1.4
**Tags**: RSS, XML

More than once or twice I've had to output something as an RSS feed, and at some point I got tired of writing the same, albeit simple, boilerplate xml every time. So I wrote a few classes that hide the intimate details of the RSS format and let you output data into an RSS stream using a handful of simple methods.

```parser3
# create a Feed object and, if needed, set the <channel/> fields right away.
# you can set any field mentioned in the RSS 2.0 specification.
# for date-type fields you can pass either a date object or a string with a date in sql format.
$oFeed[^FeedRss::create[
	$.title[RSS title]
	$.link[http://$env:SERVER_NAME/]
	$.description[RSS description]

#	by default, docs will output
#	$.docs[http://blogs.law.harvard.edu/tech/rss]

#	by default, generator will output
#	$.generator[^if(def $env:PARSER_VERSION){$env:PARSER_VERSION}{Parser 3}]

#	$.copyright[Copyright (c) Vasya Poupkin]
#	$.webMaster[vasya@poupkin.ru]
#	$.ttl(10)
#	$.image[
#		<title>A pretty short title</title>
#		<url>http://$env:SERVER_NAME/link/to/image.jpg</url>
#		<link>http://$env:SERVER_NAME/</link>
#		<width>100</width>
#		<height>100</height>
#	]
#	and so on
]]

# if you didn't set the <channel/> fields when creating the object, or you want to
# override them, do so here
^oFeed.set[
	$.title[RSS title ^[updated^]]
]

# add items
# you can set any field mentioned in the RSS 2.0 specification.
# for date-type fields you can pass either a date object or a string with a date in sql format.
# in practice you'll fetch the data from a database/file somehow, and call the addItem
# method multiple times (e.g. inside a menu).
^oFeed.addItem[
	$.title[Item 1 title]
	$.guid[http://item1-link]
	$.pubDate[^date::create[2007-08-02 22:33:44]]
	$.author[^taint[Name <email@domain.ru>]]
]
^oFeed.addItem[
	$.title[Item 2 title]
	$.guid[http://item2-link]
	$.pubDate[2007-08-01 12:23:34]
	$.description[Item 2 description]
	$.comments[Item 2 comments]
]

# output the RSS stream
# before outputting, the required fields will be checked for being filled in.
# by default, the necessary HTTP headers (last-modified, content-type) will be sent.
^oFeed.print[
	$.sVersion[2.0]

#	you need to specify which Time Zone will be used when outputting date-type fields.
#	per RFC822 it's safe to use the GMT, UTC zones, some USA zones, or a time offset.
#	if the specified zone doesn't match the zone your server runs in,
#	don't forget to manually shift the dates to the right zone when setting the date-type
#	fields on the channel and items.
	$.sTZ[+0300]
#	$.sTZ[GMT]

#	the number of items that will be output. by default, all added items are output.
	$.iItemLimit(10)

#	if specified, items will be sorted by pubDate. by default, they're output in the
#	order they were added.
	$.bOrderItems(true)

#	suppress outputting the XML declaration.
#	$.bOmitXMLDeclaration(true)

#	suppress outputting HTTP headers.
#	$.bOmitHTTPHeaders(true)
]
```

That's basically it :)

Oh, I forgot to mention that these classes require the `dtf.p` class to be available, as well as the `ArrayList` and `ArrayListEnumerator` classes shamelessly "stolen" from smalex, which have since taken up residence among the [useful user-defined operators](https://www.parser.ru/en/lib/lib/).

[Original documentation on parser.ru](https://www.parser.ru/en/lib/rss/)
