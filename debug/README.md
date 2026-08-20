# Class for Outputting Debug Information

**Author**: vlalek, September 30, 2016
**Tags**: Debugging

The class presented here adds the `dshow` and `dstop` methods to `$MAIN`, letting you pass them several parameters to output in a form that's convenient to view and copy.

The `dshow` method doesn't stop script execution — it only adds debug information as a layer (`div`) hidden in the browser. To reveal this layer in the browser, you can use the following key combinations:

- [Ctrl] + [`]
- [Ctrl] + [/]
- [Ctrl] + [0 (numpad)]
- [⌘] + [/]
- [⌘] + [0 (numpad)]

By default, values longer than 1500 characters are hidden.

You can control which values are shown via the browser's address bar, by passing commands through `#`. For example: `#hide=. show=^(object|class)[0-9]`

If a method or variable named `isDeveloper` is defined in `$MAIN`, the methods will only trigger when it returns `true`.

See [the method in action](https://www.parser.ru/_/Debug/dstop.html) and [with commands in the hash](https://www.parser.ru/_/Debug/dstop.html#hide=.%20show=^(object|class)[0-9]).

Other versions: [Mikhail Petrushin's version](https://www.parser.ru/lib/debug-fork/), [Grigory Zhizhilkin's version](http://code.google.com/p/dstop/source/browse/trunk/Debug.p).

[Original documentation on parser.ru](https://www.parser.ru/lib/debug/)
