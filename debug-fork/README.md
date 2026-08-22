# Outputting Debug Information

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), February 9, 2013
**Tags**: Debugging

I've long been using the convenient `^dstop[...]` method from the [Debug.p](http://code.google.com/p/dstop/source/browse/trunk/Debug.p) class, written by [Grigory Zhizhilkin](http://code.google.com/u/115099674466518970598/). I just felt like some functionality was missing — for instance, displaying user-defined objects and classes.

I added the functionality I needed, wrote a letter to the author, and got... silence in response. Oh well, I'm publishing the fork here — maybe it'll be useful to someone else too?

Changes relative to the original class:

* User-defined objects'/classes' contents are now displayed (fields, methods, hierarchy).
* Empty hashes, tables, and junctions are no longer displayed as void.
* Redid the display of the `file` and `image` classes.
* Large objects can now be collapsed/expanded.
* Added protection against recursion for hashes/objects.
* Objects of the `xnode` class are now displayed correctly (previously attributes weren't shown and the `&` character wasn't escaped).
* Hashes/objects containing a `foreach` field/method are now displayed properly.
* Minor optimizations.

[See the method in action](https://www.parser.ru/_/Debug/dstop-fork.html)

[Original documentation on parser.ru](https://www.parser.ru/en/lib/debug-fork/)
