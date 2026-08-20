# Class for Encoding Email Addresses When Outputting Them in mailto: Links

**Author**: Wonder, January 17, 2006
**Version**: 1.05
**Tags**: E-mail

```parser3
^mailto:print[email][type]
^mailto:print[email][title][type]
^mailto:print[email][params][type]
```

The method encrypts the given e-mail depending on the type.

* `email` — the e-mail address to encrypt
* `type` — the type of the returned result: `html` (default) or `xml`
* `title`, or `$params.title` — the link's title
* `$params.subject` — the message subject (`?subject=...`)
* `$params.attributes` — additional attributes for the `<a />` tag

If the `xml` type was specified, the method returns the string:

```
<email-crypted>em'+'ail</email-crypted>
```

For the `html` type, the returned string looks like this:

```
<script type="text/javascript">document.write('em'+'ail')</script>
```

```parser3
^mailto:crypt[text][type]
```

The method encrypts every e-mail address found in the given text.

Usage example in `@postprocess[]`:

```parser3
@postprocess[body]
^mailto:crypt[$body][html]
```

Note: only links of the form `<a href="...">...</a>` will be processed.

[Original documentation on parser.ru](https://www.parser.ru/lib/mailto/)
