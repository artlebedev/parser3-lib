# Parser 3 Class Library

A collection of reusable classes and utilities for the [Parser 3](https://www.parser.ru/en/) scripting language.

This repository is the official mirror of [the Parser 3 class library](https://www.parser.ru/en/lib/).

| Library | Description |
| ------- | ----------- |
| [antiflood](antiflood/) | Protection against duplicate messages using a hashfile, intended for guestbooks and forums. |
| [antispam](antispam/) | Protection against spam in guestbooks, forums, and similar web forms. |
| [auth](auth/) | User authentication class. It may also serve as an example of implementing authentication in Parser 3. |
| [autoindex](autoindex/) | Displays a directory listing similar to Apache `mod_autoindex` and can automatically generate previews for images. |
| [chat](chat/) | Source code for a simple chat application using JsHttpRequest. |
| [date](date/) | Class containing several methods for working with date objects. |
| [debug](debug/) | Another version of the `Debug.p` class for displaying debugging information. |
| [debug-fork](debug-fork/) | Small modification of the `Debug.p` class. |
| [erusage](erusage/) | Simplifies memory usage tracking and garbage collection. |
| [FioMorph ↗](https://github.com/Spearance/fio-morph-p3) | Declines Russian surnames, first names, and patronymics from the nominative case into other grammatical cases. |
| [img](img/) | Classes with a common interface for image processing using NConvert and ImageMagick. They support convert, crop, info, resize, rotate, watermark, and rotateJPG operations. |
| [img2](img2/) | Class for creating image previews using Perl scripts with the Image::Magick module. |
| [int2str](int2str/) | Class for writing numbers in words. |
| [js_http_request](js_http_request/) | Class that simplifies backend development when working with JsHttpRequest from dklab.ru. |
| [lib](lib/) | Useful user-defined operators that may make programming with Parser 3 easier. |
| [mailto](mailto/) | Class for encoding e-mail addresses in `mailto:` links and outputting them through JavaScript using `document.write`. |
| [Markdown ↗](https://github.com/Spearance/markdown-p3) | Converts Markdown markup to HTML. |
| [mdate](mdate/) | Class for formatted output of two dates. |
| [mscroller](mscroller/) | Pagination class that also calculates the `offset` and `limit` values required for an SQL query selecting records for the current page. |
| [PF 2 ↗](https://github.com/unhandled-exception/pf2) | Library containing base classes, ORM, controllers with flexible routing, a template engine, and other classes useful for web application development. |
| [rss](rss/) | Classes that simplify generation of RSS feeds. |
| [s3](s3/) | Simple Amazon S3 server. |
| [sql](sql/) | Classes for working with MySQL, Oracle, MSSQL, and PostgreSQL. They make Parser 3 code more portable across different SQL servers and simplify SQL performance profiling. |
