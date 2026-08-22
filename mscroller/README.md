# Text Scroller

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), August 16, 2008
**Version**: 1.14
**Tags**: SQL

The scroller presented here for your consideration is, in fact, what you can see in the forum on this very site.

This scroller doesn't have settings as flexible and varied as [the previous one](http://www.spearance.ru/parser3/scroller/text/), but it does have some specific settings of its own, and it immediately calculates the offset needed to fetch, from the SQL server, the records that belong on the current page.

Before using the scroller, you first need to find out how many records we'll be displaying page by page, which, applied to a site's news section, might look something like this:

```parser3
$iNewsCount(^pSQL.int{
	SELECT
		COUNT(*)
	FROM
		news
	WHERE
		is_published = 1
})
```

Now we can create the scroller object and output the page navigation (don't forget to hook up `scroller.p` with `@USE`):

```parser3
$iItemsPerPage(20)
$oPage[^scroller::init[$iNewsCount;$iItemsPerPage;page]]
^oPage.print[
	$.target_url[/news/]
	$.nav_count(9)
	$.mode[html]
]
```

And finally, we can fetch the list of news items on the current page and output them:

```parser3
$tNews[^pSQL.table{
	SELECT
		news_id AS id,
		title,
		^pSQL.date_format[dt;%d.%m.%Y] AS dt
	FROM
		news
	ORDER BY
		news.dt DESC
}[
	$.offset($oPage.offset)
	$.limit($oPage.limit)
]]
<ul>
^tNews.menu{
	<li><b>$tNews.dt</b>
	<br /><a href="/news/?id=$tNews.id">$tNews.title</a></li>
}
</ul>
```

Voilà.

Oh, right, almost forgot… A couple of words about its "specific" settings… In fact there's really just one such setting (`direction`). You can tell the constructor that we want the very last page (not the first one) to be numbered 1. Why would you need that? Well, imagine we have a forum (a news page, a guestbook, etc.) where data keeps getting added constantly. It would be really nice if the page at `?page=1` always contained the same data, regardless of how many records have since been added… That's exactly the problem the `direction` parameter solves (you need to pass the constructor the value -1).

When paginating with `direction=-1`, keep in mind that on pages 1 and 2 (though not at `page=1` and `page=2`) the information partially overlaps. This isn't a bug, it's a feature. It happens because pages are filled starting from the end — i.e. the last page (the one with `page=1`) is filled completely, the second-to-last one too, and so on up to the first page. But the first page needs to display the remainder of the messages. Sometimes it can turn out that this remainder is just a single message, and to avoid showing just one lone message on the first page, it instead displays the most recently added root-level messages. That's a trade-off you have to accept so that the page at a specific url (e.g. `./?page=1`) always contains the same messages (for example, so search engines index it correctly).

P.S. To understand what `$pSQL` means in the example, read the [article about SQL query portability](https://www.parser.ru/en/examples/sql/), download one of the SQL classes mentioned in it, and hook it up in `auto.p`. The scroller class doesn't make any queries itself and doesn't use `$pSQL`.

[Original documentation on parser.ru](https://www.parser.ru/en/lib/mscroller/)
