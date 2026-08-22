# Tracking Memory Usage and Garbage Collection

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), October 28, 2010
**Version**: 1.5
**Tags**: Memory

Well, here we go... now we've even gotten to garbage collection... But then, who promised this would be completely easy? Anyway, using it isn't mandatory at all, but sometimes a moment arrives where it can come in handy. The built-in `^memory:compact[]` hasn't gone anywhere, but calling it on every little thing isn't a great idea, since that operation isn't exactly fast.

And that's where the proposed `Erusage.p` class can help — its job is, in principle, exactly the same thing: periodic calls to `^memory:compact[]`, except it won't do this constantly. On top of that, it will also accumulate some simple statistics that might come in handy.

As usual, everything is simple: download the archive, unpack it, hook up `Erusage.p` in the root `auto.p`, and in the places where you feel garbage collection ought to happen, call `^Erusage:compact[]` instead of the regular `^memory:compact[]`. That's it. :)

And what does that give you? The thing is, the class will only call the parser's `^memory:compact[]` when more memory than the value of `$iLimit` (2048 KB by default) has been used since the last garbage collection; otherwise nothing happens (other than counting the number of calls). You can change the value of `$iLimit` by calling the static method `^Erusage:init[$.iLimit(4096)]`.

If, at some point in your code's space-time continuum, you decide that a genuine, real `^memory:compact[]` absolutely must run right there, go ahead and call `^Erusage:compact[$.bForce(1)]` and it will be executed, no questions asked :)

And finally, in `@postprocess[]` you can call `^Erusage:print[]` and print the accumulated results to the screen (or to a file, if you call `^Erusage:print[$.sFile[path/to/file.log]]`).

You can also call `^Erusage:log[$.sFile[/path/to/erusage.log]]` from `@postprocess[]`, and the class will log the page-generation time and the memory used (plus a few other useful little details).

And now that's really everything :)

[Original documentation on parser.ru](https://www.parser.ru/en/lib/erusage/)
