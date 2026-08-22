# Class for Formatted Output of Two Dates

**Author**: Wonder, November 7, 2005
**Version**: 1.1
**Tags**: Dates

The class outputs two given dates (or just one, if they're equal or a second date isn't specified) according to format strings for outputting each date individually (using the date-handling class) and an overall format string. It also highlights the date considered "new" (by default, a date within the last 24 hours).

Everything that can be configured is configured at initialization.

Initialization example:

```parser3
^mDate:init[
    $.dt_limit[1986-06-11]
    $.format_string[%o / %n]
    $.dtf_format_string[%d %h %Y %H:%M]
    $.dtf_locale[rr-locale]
    $.canvas_tag[div]
    $.canvas_addtags[style="background-color: #efefef^; padding: 1em"]
    $.new_tag[font]
    $.new_addtags[color="#cc0000"]
    $.old_tag[font]
    $.old_addtags[style="color: #666666"]
]
```

* `$.dt_limit[date]` — the date starting from which the given dates are considered new. Can be a string in sql format or a `date` object. If not specified, a date is considered stale once 24 hours have passed.
* `$.format_string[%o / %n]` — the format string for outputting the two dates (`o` — old date, `n` — new date, e.g. the creation date and the update date, respectively).

Usage example:

```parser3
^mDate:init[]

$dt_1[^date::create(1986;6;10;15;10)]
$dt_2[^date::create(2005;11;4;16;35)]

^mDate:print[$dt_1;$dt_2]
```

Returns the string:

```
10.06.1986 15:10 / <font color="#cc0000">04.11.2005 16:35</font>
```

[Original documentation on parser.ru](https://www.parser.ru/en/lib/mdate/)
