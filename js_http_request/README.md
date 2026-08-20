# Class for Working with JsHttpRequest

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), March 23, 2006
**Version**: 1.12
**Tags**: JS

I decided to play around with Ajax...

I had absolutely no desire to reinvent the wheel, and remembering that `JsHttpRequest.js` from [dklab.ru](http://dklab.ru/) had been chewed over on the forum more than once, I naively figured that finding, hooking up, and using an existing solution would be the fastest option.

Yeah... right. Siao liao. For some reason, everyone who'd tried to cross it with Parser seemed to have done it half-heartedly and never got as far as "downloaded it, hooked it up, it works," and never submitted code for the "Examples" section (well... or maybe they did get there but never showed it to anyone, or maybe I just didn't search well enough). Anyway, I had to fill that gap myself — hopefully I managed to do it at least a little better.

To actually try the class out, download it, unpack the archive wherever's convenient, and open the `_test_all.html` file over http from a browser. When testing, don't forget to check Cyrillic letters and symbols. You won't find anything new on the frontend (it's all exactly as the doctor — meaning Dmitry Koterov — prescribed), but the class can substantially simplify writing the backend (see the `_js_http_request_load.html` file).

A simple chat using this class was also written, which can also be considered a small test of it.

## Related links

* [http://dklab.ru/lib/JsHttpRequest/](http://dklab.ru/lib/JsHttpRequest/) — an article about this technology on dklab.ru (version 5 of the `JsHttpRequest.js` file is included in the archive);
* [http://www.ipo-design.ru/developments/lab/httprequest/](http://www.ipo-design.ru/developments/lab/httprequest/) — a set of methods intended for use with the old `JSHttpRequest.js` class; it doesn't work with Cyrillic letters, and the archive's code has some outright logical errors (sorry, author, but it's true);
* [https://www.parser.ru/forum/?id=41408](https://www.parser.ru/forum/?id=41408) — a set of methods by Sergey M., which only needed the smallest amount of filing down (the archive includes a test file, `_js_http_request_test.html`, showing the differences between the original methods and the updated ones moved into the class);
* [https://www.parser.ru/forum/?id=60053](https://www.parser.ru/forum/?id=60053) — changes by Sergey M. for working with version 5 of `JsHttpRequest.js`, which he implemented in the class on top of MadCow's changes;
* [http://www.spearance.ru/](http://www.spearance.ru/) — Eugene let me swipe from him (well, more precisely, he gave it to me himself) the table for decoding `%u0380` & Co, which also fit in almost without any filing down (I, and Sergey M. — already mentioned here more than once — only had to add a few characters).

One final note: if you don't understand anything about javascript — forget about Ajax, since the proposed class only helps simplify writing the backend (the server-side part that receives Ajax requests, decodes them, performs some actions, and sends the results back); you'll still have to write the frontend yourself (the javascript code that dynamically modifies the page based on data received from the backend).

The `JSHttpRequest.zip` archive contains the class along with the developers' js and an example; `JSHttpRequest.3.x.zip` contains the old (3.x) version of the class, likewise with the developers' js and an example.

[Original documentation on parser.ru](https://www.parser.ru/lib/js_http_request/)
